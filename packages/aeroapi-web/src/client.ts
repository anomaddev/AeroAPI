import { loadReferenceCache, mergeAircraft, mergeAirline, mergeAirport, type CacheInput } from "./cache.js";
import { AeroErrors } from "./errors.js";
import { decodeBase64, DEFAULT_BASE_URL, encodeQuery, send, type Query, type Transport } from "./http.js";
import {
  asAircraft,
  asAirline,
  asAirport,
  asFlight,
  asFlights,
  mergeCodeshares,
  referenceCache,
  type AdvancedSearchParameter,
  type Airline,
  type AirlineFlightCountResponse,
  type AirlineFlightsRequestType,
  type AirlineFlightsResponse,
  type AirlinesResponse,
  type Airport,
  type AirportFlightCounts,
  type AirportFlightsRequestType,
  type AirportFlightsResponse,
  type AirportIdType,
  type AirportRouteResponse,
  type AirportsDelayedResponse,
  type AirportsNearbyResponse,
  type AirportsResponse,
  type AirportStatus,
  type AirportWeatherForecastResponse,
  type AirportWeatherObservationsResponse,
  type Aircraft,
  type AircraftOwnerResponse,
  type BlockedResponse,
  type CanonicalAirlineResponse,
  type CanonicalAirportResponse,
  type CanonicalFlightIdResponse,
  type DateRange,
  type DisruptionCountResponse,
  type DisruptionCountTimePeriod,
  type DisruptionCountType,
  type DisruptionEntity,
  type Flight,
  type FlightDataResponse,
  type FlightRoute,
  type FlightSearchResponse,
  type FlightTrackPoint,
  type FlightType,
  type FlightsBetweenAirportsResponse,
  type IdentType,
  type LastFlightResponse,
  type MapImage,
  type RouteRequestSort,
  type ScheduledFlight,
  type ScheduledFlightResponse,
  type TemperatureUnits,
} from "./models.js";
import {
  advancedSearchQuery,
  AircraftOwnerRequest,
  AircraftTypeInfoRequest,
  AirlineFlightCountRequest,
  AirlineFlightsRequest,
  AirlineInfoRequest,
  AirlinesRequest,
  AirportFlightsRequest,
  AirportInfoRequest,
  AirportRouteRequest,
  AirportsNearbyRequest,
  AirportsRequest,
  AirportStatusRequest,
  AirportWeatherForecastRequest,
  AirportWeatherObservationRequest,
  BlockedCheck,
  CanonicalAirlineRequest,
  CanonicalAirportRequest,
  CanonicalFlightIdRequest,
  DisruptionCountsRequest,
  FlightDataRequest,
  FlightPositionRequest,
  FlightRouteRequest,
  FlightTrackRequest,
  FlightsBetweenAirportsRequest,
  LastFlightRequest,
  MapDataRequest,
  ScheduledFlightRequest,
  type AeroAPIRequest,
} from "./requests.js";

export interface AeroAPIOptions {
  apiKey?: string;
  baseUrl?: string;
  fetch?: typeof fetch;
}

export class AeroAPI {
  static debug = false;
  static showHTTPRequestURLs = false;
  static readonly allAirports = referenceCache.airports;
  static readonly allAirlines = referenceCache.airlines;
  static readonly allAircraft = referenceCache.aircraft;

  private static shared = new AeroAPI({ apiKey: "" });

  /** Shared client, matching `AeroAPI.manager` in Swift. */
  static get manager(): AeroAPI {
    return AeroAPI.shared;
  }

  apiKey: string;
  readonly baseUrl: string;
  private readonly transport: Transport;

  constructor(options: AeroAPIOptions = {}) {
    this.apiKey = options.apiKey ?? "";
    this.baseUrl = (options.baseUrl ?? DEFAULT_BASE_URL).replace(/\/$/, "");
    const fetchImpl = options.fetch ?? globalThis.fetch.bind(globalThis);
    this.transport = (url, init) => fetchImpl(url, init);
  }

  setApiKey(key: string): void {
    this.apiKey = key;
  }

  async loadCache(input?: CacheInput): Promise<void> {
    await loadReferenceCache(input);
  }

  private log(path: string, query: Query): void {
    if (!(AeroAPI.debug || AeroAPI.showHTTPRequestURLs)) return;
    console.log("REQUESTING:");
    console.log(`${this.baseUrl}${path}${encodeQuery(query)}`);
    console.log();
  }

  private async call<T>(request: AeroAPIRequest): Promise<T> {
    this.log(request.path(), request.query());
    return send<T>(this.transport, this.baseUrl, this.apiKey, request.path(), request.query());
  }

  private async searchFlights(path: string, query: Query): Promise<FlightDataResponse> {
    this.log(path, query);
    const page = await send<FlightDataResponse>(this.transport, this.baseUrl, this.apiKey, path, query);
    page.flights = asFlights(page.flights as unknown as object[]);
    return page;
  }

  async getFlightData(faId: string): Promise<Flight | null>;
  async getFlightData(request: FlightDataRequest): Promise<FlightDataResponse>;
  async getFlightData(faIdOrRequest: string | FlightDataRequest): Promise<Flight | null | FlightDataResponse> {
    if (typeof faIdOrRequest === "string") {
      const page = await this.getFlightData(FlightDataRequest.faId(faIdOrRequest));
      return page.flights?.[0] ?? null;
    }
    return this.searchFlights(faIdOrRequest.path(), faIdOrRequest.query());
  }

  flightIDCanonical(code: string, type?: IdentType, countryCode?: string): Promise<CanonicalFlightIdResponse> {
    return this.call(new CanonicalFlightIdRequest(code, type, countryCode));
  }

  getPosition(faId: string): Promise<FlightSearchResponse> {
    return this.call(new FlightPositionRequest(faId));
  }

  async getRoute(faId: string): Promise<FlightRoute> {
    return this.call(new FlightRouteRequest(faId));
  }

  async getTrack(faId: string, includeEstimatedPositions = false): Promise<FlightTrackPoint[]> {
    const data = await this.call<{ positions?: FlightTrackPoint[] }>(new FlightTrackRequest(faId, includeEstimatedPositions));
    if (!data.positions) throw AeroErrors.failedDecodingFlightTrackResponse();
    if (data.positions.length === 0) throw AeroErrors.flightTrackEmpty();
    return data.positions;
  }

  async getMap(request: MapDataRequest): Promise<MapImage> {
    const payload = await this.call<{ map?: string }>(request);
    if (!payload.map) throw AeroErrors.failedDecodingMapData();
    const bytes = decodeBase64(payload.map);
    let binary = "";
    for (const byte of bytes) binary += String.fromCharCode(byte);
    return { bytes, dataUrl: `data:image/png;base64,${btoa(binary)}` };
  }

  advancedSearch(parameter: AdvancedSearchParameter): Promise<FlightDataResponse> {
    return this.searchFlights("/flights/search/advanced", advancedSearchQuery(parameter));
  }

  getAirports(maxPages = 1): Promise<AirportsResponse> {
    return this.call(new AirportsRequest(maxPages));
  }

  airportCanonical(code: string, type: AirportIdType = "icao"): Promise<CanonicalAirportResponse> {
    return this.call(new CanonicalAirportRequest(code, type));
  }

  async getAirportInfo(id: { code: string } | { icao: string } | { iata: string }): Promise<Airport> {
    const code = "code" in id ? id.code : "icao" in id ? id.icao : id.iata;
    const airport = asAirport(await this.call<object>(new AirportInfoRequest(code)));
    if ("icao" in id) return mergeAirport(airport, { icao: id.icao });
    if ("iata" in id) return mergeAirport(airport, { iata: id.iata });
    return mergeAirport(airport, { code: id.code });
  }

  async getAirportFlights(request: AirportFlightsRequest): Promise<AirportFlightsResponse> {
    const response = await this.call<AirportFlightsResponse>(request);
    response.arrivals = asFlights(response.arrivals as unknown as object[]);
    response.departures = asFlights(response.departures as unknown as object[]);
    response.scheduledArrivals = asFlights(response.scheduledArrivals as unknown as object[]);
    response.scheduledDepartures = asFlights(response.scheduledDepartures as unknown as object[]);
    return response;
  }

  /** Swift's async name is `getAirportsFlights`. */
  getAirportsFlights(request: AirportFlightsRequest): Promise<AirportFlightsResponse> {
    return this.getAirportFlights(request);
  }

  getAirportFlightCounts(code: string): Promise<AirportFlightCounts> {
    return this.call({ path: () => `/airports/${encodeURIComponent(code)}/flights/counts`, query: () => ({}) });
  }

  async getFlightsBetweenAirports(request: FlightsBetweenAirportsRequest): Promise<FlightsBetweenAirportsResponse> {
    const response = await this.call<FlightsBetweenAirportsResponse>(request);
    response.flights = response.flights?.map((segment) => ({
      segments: asFlights(segment.segments as unknown as object[]) ?? [],
    }));
    return response;
  }

  getAirportsNear(request: AirportsNearbyRequest): Promise<AirportsNearbyResponse> {
    return this.call(request);
  }

  getAirportStatus(code: string): Promise<AirportStatus> {
    return this.call(new AirportStatusRequest(code));
  }

  getAirportsDelayed(): Promise<AirportsDelayedResponse> {
    return this.call(new AirportStatusRequest());
  }

  getAirportForecast(code: string, timestamp = new Date(), returnNearby = true): Promise<AirportWeatherForecastResponse> {
    return this.call(new AirportWeatherForecastRequest(code, timestamp, returnNearby));
  }

  getAirportObservations(
    code: string,
    options: { temperatureUnits?: TemperatureUnits; timestamp?: Date; returnNearby?: boolean; maxPages?: number } = {},
  ): Promise<AirportWeatherObservationsResponse> {
    return this.call(new AirportWeatherObservationRequest(code, options));
  }

  getRoutesBetween(
    origin: string,
    destination: string,
    _sortBy: RouteRequestSort = "count",
    _maxFileAge = "2 weeks",
    maxPages = 3,
  ): Promise<AirportRouteResponse> {
    return this.call(new AirportRouteRequest(origin, destination, maxPages));
  }

  getAirlines(maxPages = 1): Promise<AirlinesResponse> {
    return this.call(new AirlinesRequest(maxPages));
  }

  airlineCanonical(code: string, countryCode?: string): Promise<CanonicalAirlineResponse> {
    return this.call(new CanonicalAirlineRequest(code, countryCode));
  }

  async getAirlineInfo(id: { icao: string } | { iata: string }): Promise<Airline> {
    const code = "icao" in id ? id.icao : id.iata;
    const airline = asAirline(await this.call<object>(new AirlineInfoRequest(code)));
    return "icao" in id ? mergeAirline(airline, { icao: id.icao }) : mergeAirline(airline, { iata: id.iata });
  }

  getAirlineCountsOnRecord(icao: string): Promise<AirlineFlightCountResponse> {
    return this.call(new AirlineFlightCountRequest(icao));
  }

  async getAirlineFlights(request: AirlineFlightsRequest): Promise<AirlineFlightsResponse> {
    const response = await this.call<AirlineFlightsResponse>(request);
    response.arrivals = asFlights(response.arrivals as unknown as object[]);
    response.scheduled = asFlights(response.scheduled as unknown as object[]);
    response.enroute = asFlights(response.enroute as unknown as object[]);
    return response;
  }

  getAirlineFlightCounts(icao: string): Promise<AirlineFlightsResponse> {
    return this.call(new AirlineFlightCountRequest(icao));
  }

  async lastFlightFor(tailno: string): Promise<Flight | null> {
    const response = await this.call<LastFlightResponse>(new LastFlightRequest(tailno));
    const flights = asFlights(response.flights as unknown as object[]);
    return flights?.[0] ?? null;
  }

  async checkBlocked(registration: string): Promise<boolean> {
    const response = await this.call<BlockedResponse>(new BlockedCheck(registration));
    return response.blocked;
  }

  async getAircraftInfo(icao: string): Promise<Aircraft> {
    const aircraft = asAircraft(await this.call<object>(new AircraftTypeInfoRequest(icao)));
    return mergeAircraft(aircraft, icao);
  }

  getOwner(registration: string): Promise<AircraftOwnerResponse> {
    return this.call(new AircraftOwnerRequest(registration));
  }

  disruptionsAt(options: {
    entity: string;
    type: DisruptionCountType;
    timePeriod?: DisruptionCountTimePeriod;
  }): Promise<DisruptionEntity> {
    return this.call(
      new DisruptionCountsRequest(options.type, { code: options.entity, timePeriod: options.timePeriod }),
    );
  }

  disruptionCounts(
    options:
      | { airline: string; timePeriod?: DisruptionCountTimePeriod; maxPages?: number }
      | { type?: DisruptionCountType; timePeriod?: DisruptionCountTimePeriod; maxPages?: number },
  ): Promise<DisruptionCountResponse> {
    const type = "airline" in options ? "airline" : (options.type ?? "origin");
    return this.call(new DisruptionCountsRequest(type, { timePeriod: options.timePeriod, maxPages: options.maxPages }));
  }

  async getScheduled(request: ScheduledFlightRequest): Promise<ScheduledFlight[]> {
    const response = await this.call<ScheduledFlightResponse>(request);
    if (!response.scheduled) throw AeroErrors.failedDecodingScheduledFlightResponse();
    return mergeCodeshares(response.scheduled);
  }
}

export function airportFlights(code: string, options?: {
  airline?: string;
  type?: FlightType;
  dateRange?: DateRange;
  cursor?: string;
  requestType?: AirportFlightsRequestType;
}): AirportFlightsRequest {
  return new AirportFlightsRequest(code, options);
}

export function airlineFlights(code: string, options?: {
  dateRange?: DateRange;
  cursor?: string;
  requestType?: AirlineFlightsRequestType;
}): AirlineFlightsRequest {
  return new AirlineFlightsRequest(code, options);
}

export function flightsBetween(
  origin: string,
  destination: string,
  options?: ConstructorParameters<typeof FlightsBetweenAirportsRequest>[2],
): FlightsBetweenAirportsRequest {
  return new FlightsBetweenAirportsRequest(origin, destination, options);
}

export function airportsNear(options: ConstructorParameters<typeof AirportsNearbyRequest>[0]): AirportsNearbyRequest {
  return new AirportsNearbyRequest(options);
}

export function mapRequest(faId: string, options?: ConstructorParameters<typeof MapDataRequest>[1]): MapDataRequest {
  return new MapDataRequest(faId, options);
}

export { FlightDataRequest, MapDataRequest, ScheduledFlightRequest };
