import { AeroErrors } from "./errors.js";
import type { Query } from "./http.js";
import type {
  AirlineFlightsRequestType,
  Airport,
  AirportFlightsRequestType,
  DateRange,
  DisruptionCountTimePeriod,
  DisruptionCountType,
  FlightAwareMapLayer,
  FlightConnectionType,
  FlightType,
  IdentType,
  TemperatureUnits,
} from "./models.js";

/** Swift compares dates with `84600` seconds per day. */
const SWIFT_DAY_MS = 84_600 * 1000;

export interface AeroAPIRequest {
  path(): string;
  query(): Query;
}

export function faFlightTimestamp(faFlightId: string): number {
  const stamp = Number(faFlightId.split("-")[1]);
  if (!Number.isFinite(stamp)) throw AeroErrors.faIdDateInvalid(faFlightId);
  return stamp;
}

export function isHistoricalFlight(faFlightId: string, nowSeconds = Date.now() / 1000): boolean {
  return nowSeconds > faFlightTimestamp(faFlightId);
}

export function assertDateWindow(start: Date, end: Date, now = Date.now()): void {
  if (start.getTime() >= end.getTime()) throw AeroErrors.startDateBeforeEndDate();
  if (start.getTime() <= now - 7 * SWIFT_DAY_MS || end.getTime() >= now + 2 * SWIFT_DAY_MS) {
    throw AeroErrors.invalidDateAirportFlightsRequest();
  }
}

export function assertMapDimension(name: "height" | "width", value: number): void {
  if (!Number.isInteger(value) || value < 1 || value > 1500) {
    throw name === "height" ? AeroErrors.invalidMapHeight(value) : AeroErrors.invalidMapWidth(value);
  }
}

function dateQuery(range: DateRange | undefined, validate: boolean): Query {
  if (!range) return {};
  if (validate) assertDateWindow(range.start, range.end);
  return { start: range.start, end: range.end };
}

export class FlightDataRequest implements AeroAPIRequest {
  readonly ident: string;
  readonly historical: boolean;
  private readonly items: Query;

  private constructor(ident: string, historical: boolean, items: Query) {
    this.ident = ident;
    this.historical = historical;
    this.items = items;
  }

  static faId(faId: string, historical = false): FlightDataRequest {
    faFlightTimestamp(faId);
    return new FlightDataRequest(faId, historical, { ident_type: "fa_flight_id" });
  }

  static ident(options: {
    ident: string;
    type?: IdentType;
    dateRange?: DateRange;
    maxPages?: number;
    cursor?: string;
    historical?: boolean;
  }): FlightDataRequest {
    const historical = options.dateRange ? options.dateRange.start.getTime() < Date.now() : (options.historical ?? false);
    return new FlightDataRequest(options.ident, historical, {
      ident_type: options.type ?? "designator",
      max_pages: options.maxPages ?? 1,
      ...dateQuery(options.dateRange, false),
      cursor: options.cursor,
    });
  }

  path(): string {
    return `${this.historical ? "/history" : ""}/flights/${encodeURIComponent(this.ident)}`;
  }

  query(): Query {
    return this.items;
  }
}

export class CanonicalFlightIdRequest implements AeroAPIRequest {
  constructor(
    private readonly code: string,
    private readonly identType?: IdentType,
    private readonly countryCode?: string,
  ) {}

  path(): string {
    return `/flights/${encodeURIComponent(this.code)}/canonical`;
  }

  query(): Query {
    return {
      ident_type: this.identType && this.identType !== "fa_flight_id" ? this.identType : undefined,
      country_code: this.countryCode,
    };
  }
}

export class FlightPositionRequest implements AeroAPIRequest {
  constructor(private readonly faId: string) {}
  path(): string {
    return `/flights/${encodeURIComponent(this.faId)}/position`;
  }
  query(): Query {
    return {};
  }
}

export class FlightRouteRequest implements AeroAPIRequest {
  readonly historical: boolean;
  constructor(private readonly faId: string) {
    this.historical = isHistoricalFlight(faId);
  }
  path(): string {
    return `${this.historical ? "/history" : ""}/flights/${encodeURIComponent(this.faId)}/route`;
  }
  query(): Query {
    return {};
  }
}

export class FlightTrackRequest implements AeroAPIRequest {
  readonly historical: boolean;
  constructor(
    private readonly faId: string,
    private readonly includeEstimated = false,
  ) {
    this.historical = isHistoricalFlight(faId);
  }
  path(): string {
    return `${this.historical ? "/history" : ""}/flights/${encodeURIComponent(this.faId)}/track`;
  }
  query(): Query {
    return { include_estimated_positions: this.includeEstimated };
  }
}

export class MapDataRequest implements AeroAPIRequest {
  readonly historical: boolean;
  constructor(
    private readonly faId: string,
    private readonly options: {
      height?: number;
      width?: number;
      layersOn?: FlightAwareMapLayer[];
      layersOff?: FlightAwareMapLayer[];
      showDataBlock?: boolean;
      airportsExpandView?: boolean;
      showAirports?: boolean;
      historical?: boolean;
    } = {},
  ) {
    const height = options.height ?? 480;
    const width = options.width ?? 640;
    assertMapDimension("height", height);
    assertMapDimension("width", width);
    this.options = { ...options, height, width };
    this.historical = options.historical ?? isHistoricalFlight(faId);
  }
  path(): string {
    return `${this.historical ? "/history" : ""}/flights/${encodeURIComponent(this.faId)}/map`;
  }
  query(): Query {
    return {
      height: this.options.height,
      width: this.options.width,
      layer_on: this.options.layersOn,
      layer_off: this.options.layersOff,
      show_data_block: this.options.showDataBlock,
      airports_expand_view: this.options.airportsExpandView,
      show_airports: this.options.showAirports,
    };
  }
}

export class AirportsRequest implements AeroAPIRequest {
  constructor(private readonly maxPages = 1) {}
  path(): string {
    return "/airports";
  }
  query(): Query {
    return { max_pages: this.maxPages };
  }
}

export class CanonicalAirportRequest implements AeroAPIRequest {
  constructor(
    private readonly code: string,
    private readonly idType = "icao",
  ) {}
  path(): string {
    return `/airports/${encodeURIComponent(this.code)}/canonical`;
  }
  query(): Query {
    return { id_type: this.idType };
  }
}

export class AirportInfoRequest implements AeroAPIRequest {
  constructor(private readonly code: string) {}
  path(): string {
    return `/airports/${encodeURIComponent(this.code)}`;
  }
  query(): Query {
    return {};
  }
}

export class AirportFlightsRequest implements AeroAPIRequest {
  constructor(
    private readonly code: string,
    private readonly options: {
      airline?: string;
      type?: FlightType;
      dateRange?: DateRange;
      cursor?: string;
      requestType?: AirportFlightsRequestType;
    } = {},
  ) {}
  path(): string {
    const suffix: Record<AirportFlightsRequestType, string> = {
      all: "",
      scheduledArrivals: "/scheduled_arrivals",
      scheduledDepartures: "/scheduled_departures",
      arrivals: "/arrivals",
      departures: "/departures",
    };
    return `/airports/${encodeURIComponent(this.code)}/flights${suffix[this.options.requestType ?? "all"]}`;
  }
  query(): Query {
    return {
      type: this.options.type ?? "Airline",
      max_pages: 1,
      airline: this.options.airline,
      ...dateQuery(this.options.dateRange, true),
      cursor: this.options.cursor,
    };
  }
}

export class FlightsBetweenAirportsRequest implements AeroAPIRequest {
  constructor(
    private readonly origin: string,
    private readonly destination: string,
    private readonly options: {
      type?: FlightType;
      connection?: FlightConnectionType;
      dateRange?: DateRange;
      maxPages?: number;
      cursor?: string;
    } = {},
  ) {}
  path(): string {
    return `/airports/${encodeURIComponent(this.origin)}/flights/to/${encodeURIComponent(this.destination)}`;
  }
  query(): Query {
    return {
      max_pages: this.options.maxPages ?? 1,
      type: this.options.type ?? "Airline",
      connection: this.options.connection ?? "nonstop",
      ...dateQuery(this.options.dateRange, true),
      cursor: this.options.cursor,
    };
  }
}

export class AirportsNearbyRequest implements AeroAPIRequest {
  constructor(
    private readonly options: {
      code?: string;
      latitude?: number;
      longitude?: number;
      radius?: number;
      onlyInstrumentApproaches?: boolean;
      cursor?: string;
    },
  ) {}
  path(): string {
    return this.options.code ? `/airports/${encodeURIComponent(this.options.code)}/nearby` : "/airports/nearby";
  }
  query(): Query {
    return {
      latitude: this.options.latitude,
      longitude: this.options.longitude,
      radius: this.options.radius ?? 250,
      only_iap: this.options.onlyInstrumentApproaches ?? false,
      max_pages: 1,
      cursor: this.options.cursor,
    };
  }
}

export class AirportStatusRequest implements AeroAPIRequest {
  constructor(private readonly code?: string) {}
  path(): string {
    return this.code ? `/airports/${encodeURIComponent(this.code)}/delays` : "/airports/delays";
  }
  query(): Query {
    return this.code ? {} : { max_pages: 5 };
  }
}

export class AirportWeatherForecastRequest implements AeroAPIRequest {
  constructor(
    private readonly code: string,
    private readonly timestamp = new Date(),
    private readonly returnNearby = true,
  ) {}
  path(): string {
    return `/airports/${encodeURIComponent(this.code)}/weather/forecast`;
  }
  query(): Query {
    return { timestamp: this.timestamp, return_nearby_weather: this.returnNearby };
  }
}

export class AirportWeatherObservationRequest implements AeroAPIRequest {
  constructor(
    private readonly code: string,
    private readonly options: {
      temperatureUnits?: TemperatureUnits;
      timestamp?: Date;
      returnNearby?: boolean;
      maxPages?: number;
    } = {},
  ) {}
  path(): string {
    return `/airports/${encodeURIComponent(this.code)}/weather/observations`;
  }
  query(): Query {
    return {
      temperature_units: this.options.temperatureUnits ?? "F",
      timestamp: this.options.timestamp ?? new Date(),
      return_nearby_weather: this.options.returnNearby ?? true,
      max_pages: this.options.maxPages ?? 3,
    };
  }
}

export class AirportRouteRequest implements AeroAPIRequest {
  constructor(
    private readonly origin: string,
    private readonly destination: string,
    private readonly maxPages = 3,
    private readonly cursor?: string,
  ) {}
  path(): string {
    return `/airports/${encodeURIComponent(this.origin)}/routes/${encodeURIComponent(this.destination)}`;
  }
  query(): Query {
    return { max_pages: this.maxPages, cursor: this.cursor };
  }
}

export class AirlinesRequest implements AeroAPIRequest {
  constructor(private readonly maxPages = 1) {}
  path(): string {
    return "/operators";
  }
  query(): Query {
    return { max_pages: this.maxPages };
  }
}

export class CanonicalAirlineRequest implements AeroAPIRequest {
  constructor(
    private readonly code: string,
    private readonly countryCode?: string,
  ) {}
  path(): string {
    return `/operators/${encodeURIComponent(this.code)}/canonical`;
  }
  query(): Query {
    return { country_code: this.countryCode };
  }
}

export class AirlineInfoRequest implements AeroAPIRequest {
  constructor(private readonly code: string) {}
  path(): string {
    return `/operators/${encodeURIComponent(this.code)}`;
  }
  query(): Query {
    return {};
  }
}

export class AirlineFlightCountRequest implements AeroAPIRequest {
  constructor(private readonly code: string) {}
  path(): string {
    return `/operators/${encodeURIComponent(this.code)}/flights/counts`;
  }
  query(): Query {
    return {};
  }
}

export class AirlineFlightsRequest implements AeroAPIRequest {
  constructor(
    private readonly code: string,
    private readonly options: {
      dateRange?: DateRange;
      cursor?: string;
      requestType?: AirlineFlightsRequestType;
    } = {},
  ) {}
  path(): string {
    const kind = this.options.requestType ?? "all";
    const suffix = kind === "all" ? "" : `/${kind}`;
    return `/operators/${encodeURIComponent(this.code)}/flights${suffix}`;
  }
  query(): Query {
    return { max_pages: 1, ...dateQuery(this.options.dateRange, true), cursor: this.options.cursor };
  }
}

export class LastFlightRequest implements AeroAPIRequest {
  constructor(private readonly registration: string) {}
  path(): string {
    return `/history/aircraft/${encodeURIComponent(this.registration)}/last_flight`;
  }
  query(): Query {
    return {};
  }
}

export class BlockedCheck implements AeroAPIRequest {
  constructor(private readonly ident: string) {}
  path(): string {
    return `/aircraft/${encodeURIComponent(this.ident)}/blocked`;
  }
  query(): Query {
    return {};
  }
}

export class AircraftTypeInfoRequest implements AeroAPIRequest {
  constructor(private readonly icao: string) {}
  path(): string {
    return `/aircraft/types/${encodeURIComponent(this.icao)}`;
  }
  query(): Query {
    return {};
  }
}

export class AircraftOwnerRequest implements AeroAPIRequest {
  constructor(private readonly ident: string) {}
  path(): string {
    return `/aircraft/${encodeURIComponent(this.ident)}/owner`;
  }
  query(): Query {
    return {};
  }
}

export class DisruptionCountsRequest implements AeroAPIRequest {
  constructor(
    private readonly entityType: DisruptionCountType,
    private readonly options: { code?: string; timePeriod?: DisruptionCountTimePeriod; maxPages?: number } = {},
  ) {}
  path(): string {
    const base = `/disruption_counts/${this.entityType}/`;
    return this.options.code ? `${base}${encodeURIComponent(this.options.code)}` : base;
  }
  query(): Query {
    return {
      time_period: this.options.timePeriod ?? "today",
      max_pages: this.options.code ? undefined : (this.options.maxPages ?? 1),
    };
  }
}

export class ScheduledFlightRequest implements AeroAPIRequest {
  readonly filters: Query;
  constructor(
    readonly day: number,
    readonly year: number,
    readonly origin: Airport,
    filters: Query,
  ) {
    this.filters = filters;
  }
  static between(day: number, year: number, origin: Airport, destination?: Airport): ScheduledFlightRequest {
    return new ScheduledFlightRequest(day, year, origin, {
      origin: origin.codeIcao,
      destination: destination?.codeIcao,
    });
  }
  static ident(day: number, year: number, origin: Airport, ident: string): ScheduledFlightRequest {
    return new ScheduledFlightRequest(day, year, origin, { ident });
  }
  path(): string {
    return "";
  }
  query(): Query {
    return this.filters;
  }
}

export function advancedSearchQuery(parameter: import("./models.js").AdvancedSearchParameter): Query {
  if (parameter.kind !== "mapBounds") return { "": "" };
  const { bounds } = parameter;
  const lon = [bounds.NECoord.longitude, bounds.NWCoord.longitude].sort((left, right) => left - right);
  const lat = [bounds.NWCoord.latitude, bounds.SWCoord.latitude].sort((left, right) => left - right);
  const query = `{range lat ${lat[0]} ${lat[1]}} {range lon ${lon[0]} ${lon[1]}} {< alt 500}`;
  return { query, max_pages: "5" };
}

export function describeRequest(request: AeroAPIRequest): { path: string; query: Query } {
  return { path: request.path(), query: request.query() };
}
