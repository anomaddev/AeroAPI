import { AeroAPIError } from "./errors.js";
import {
  DEFAULT_BASE_URL,
  decodeBase64,
  encodeQuery,
  send,
  type Query,
  type Transport,
} from "./http.js";
import type {
  AircraftOwner,
  AircraftType,
  Airport,
  AirportFlightCounts,
  AirportFlightKind,
  AirportFlights,
  AirportIdType,
  AirportPage,
  BlockedAircraft,
  CanonicalAirportResponse,
  CanonicalFlightResponse,
  CanonicalOperatorResponse,
  ConnectionKind,
  DateWindow,
  DisruptionCounts,
  DisruptionEntity,
  DisruptionEntityType,
  DisruptionTimePeriod,
  FlightKind,
  FlightListQuery,
  FlightPage,
  FlightPosition,
  FlightRoute,
  FlightTrackResponse,
  FlightsBetweenAirports,
  IdentType,
  MapImage,
  MapQuery,
  NearbyAirports,
  Operator,
  OperatorFlightCounts,
  OperatorFlightKind,
  OperatorFlights,
  OperatorPage,
} from "./types.js";

export interface AeroAPIOptions {
  /** AeroAPI key from the FlightAware developer portal. */
  apiKey: string;
  /** Override the API origin. Defaults to the FlightAware AeroAPI host. */
  baseUrl?: string;
  /** Inject a fetch implementation. Defaults to the global `fetch`. */
  fetch?: typeof fetch;
}

const DAY_MS = 86_400_000;

export function assertDateWindow(start: Date, end: Date): void {
  if (start.getTime() >= end.getTime()) {
    throw new AeroAPIError("Start Date cannot be before the End Date.", {
      code: "startDateBeforeEndDate",
    });
  }
  const now = Date.now();
  if (start.getTime() <= now - 7 * DAY_MS || end.getTime() >= now + 2 * DAY_MS) {
    throw new AeroAPIError(
      "Start and End dates must be no further than a week in the past and two days in the future.",
      { code: "invalidDateRange" },
    );
  }
}

export function assertMapDimension(name: "height" | "width", value: number): void {
  if (!Number.isInteger(value) || value < 1 || value > 1500) {
    throw new AeroAPIError(
      `The ${name} (${value}) given to the request for map data is invalid. It must be between 1 and 1500!`,
      { code: name === "height" ? "invalidMapHeight" : "invalidMapWidth" },
    );
  }
}

export function faFlightTimestamp(faFlightId: string): number {
  const stamp = Number(faFlightId.split("-")[1]);
  if (!Number.isFinite(stamp)) {
    throw new AeroAPIError(`The FAID date string is invalid: ${faFlightId}`, {
      code: "faIdDateInvalid",
    });
  }
  return stamp;
}

export function isHistoricalFlight(faFlightId: string, nowSeconds = Date.now() / 1000): boolean {
  return nowSeconds > faFlightTimestamp(faFlightId);
}

function dateQuery(window: DateWindow | undefined): Query {
  if (!window) return {};
  assertDateWindow(window.start, window.end);
  return { start: window.start, end: window.end };
}

function flightQuery(query: FlightListQuery | undefined): Query {
  return {
    ident_type: query?.identType,
    start: query?.start,
    end: query?.end,
    max_pages: query?.maxPages,
    cursor: query?.cursor,
  };
}

/**
 * FlightAware AeroAPI client for browsers and Node.js.
 *
 * Covers the same flight, airport, operator, history, aircraft, and disruption
 * endpoints as the iOS Swift package.
 */
export class AeroAPI {
  readonly apiKey: string;
  readonly baseUrl: string;
  private readonly transport: Transport;

  constructor(options: AeroAPIOptions) {
    this.apiKey = options.apiKey;
    this.baseUrl = (options.baseUrl ?? DEFAULT_BASE_URL).replace(/\/$/, "");
    const fetchImpl = options.fetch ?? globalThis.fetch.bind(globalThis);
    this.transport = (url, init) => fetchImpl(url, init);
  }

  /** Absolute URL the client would request. Useful for diagnostics. */
  url(path: string, query?: Query): string {
    return `${this.baseUrl}${path}${encodeQuery(query)}`;
  }

  private get<T>(path: string, query?: Query): Promise<T> {
    return send<T>(this.transport, this.baseUrl, this.apiKey, path, query);
  }

  private async map(path: string, query: Query): Promise<MapImage> {
    const payload = await this.get<{ map?: string }>(path, query);
    if (!payload.map) {
      throw new AeroAPIError("Failed to decode 'map' from JSON data response", {
        code: "failedDecodingMapData",
      });
    }
    const bytes = decodeBase64(payload.map);
    let binary = "";
    for (const byte of bytes) binary += String.fromCharCode(byte);
    return { bytes, dataUrl: `data:image/png;base64,${btoa(binary)}` };
  }

  readonly flights = {
    list: (ident: string, query?: FlightListQuery): Promise<FlightPage> => {
      const historical = query?.historical ?? false;
      const prefix = historical ? "/history" : "";
      return this.get<FlightPage>(`${prefix}/flights/${encodeURIComponent(ident)}`, flightQuery(query));
    },

    canonical: (ident: string, identType?: IdentType, countryCode?: string): Promise<CanonicalFlightResponse> =>
      this.get(`/flights/${encodeURIComponent(ident)}/canonical`, {
        ident_type: identType,
        country_code: countryCode,
      }),

    position: (faFlightId: string): Promise<FlightPosition> =>
      this.get(`/flights/${encodeURIComponent(faFlightId)}/position`),

    route: async (faFlightId: string, historical = isHistoricalFlight(faFlightId)): Promise<FlightRoute> => {
      const prefix = historical ? "/history" : "";
      return this.get(`${prefix}/flights/${encodeURIComponent(faFlightId)}/route`);
    },

    track: async (
      faFlightId: string,
      options?: { includeEstimated?: boolean; historical?: boolean },
    ): Promise<FlightTrackResponse> => {
      const historical = options?.historical ?? isHistoricalFlight(faFlightId);
      const prefix = historical ? "/history" : "";
      return this.get(`${prefix}/flights/${encodeURIComponent(faFlightId)}/track`, {
        include_estimated_positions: options?.includeEstimated ?? true,
      });
    },

    map: async (faFlightId: string, query: MapQuery = {}): Promise<MapImage> => {
      const width = query.width ?? 640;
      const height = query.height ?? 480;
      assertMapDimension("width", width);
      assertMapDimension("height", height);
      const historical = query.historical ?? isHistoricalFlight(faFlightId);
      const prefix = historical ? "/history" : "";
      return this.map(`${prefix}/flights/${encodeURIComponent(faFlightId)}/map`, {
        width,
        height,
        layer_on: query.layersOn,
        layer_off: query.layersOff,
        show_data_block: query.showDataBlock,
        airports_expand_view: query.airportsExpandView,
        show_airports: query.showAirports,
      });
    },
  };

  readonly history = {
    flights: (ident: string, query?: Omit<FlightListQuery, "historical">): Promise<FlightPage> =>
      this.flights.list(ident, { ...query, historical: true }),

    lastFlight: (registration: string): Promise<FlightPage> =>
      this.get(`/history/aircraft/${encodeURIComponent(registration)}/last_flight`),

    route: (faFlightId: string): Promise<FlightRoute> => this.flights.route(faFlightId, true),

    track: (faFlightId: string, includeEstimated = true): Promise<FlightTrackResponse> =>
      this.flights.track(faFlightId, { includeEstimated, historical: true }),

    map: (faFlightId: string, query: Omit<MapQuery, "historical"> = {}): Promise<MapImage> =>
      this.flights.map(faFlightId, { ...query, historical: true }),
  };

  readonly airports = {
    list: (maxPages = 1): Promise<AirportPage> => this.get("/airports", { max_pages: maxPages }),

    get: (code: string): Promise<Airport> => this.get(`/airports/${encodeURIComponent(code)}`),

    canonical: (code: string, idType: AirportIdType = "icao"): Promise<CanonicalAirportResponse> =>
      this.get(`/airports/${encodeURIComponent(code)}/canonical`, { id_type: idType }),

    delays: (code?: string): Promise<Record<string, unknown>> =>
      this.get(code ? `/airports/${encodeURIComponent(code)}/delays` : "/airports/delays"),

    flights: async (
      code: string,
      options?: { kind?: AirportFlightKind; window?: DateWindow; maxPages?: number; cursor?: string },
    ): Promise<AirportFlights> => {
      const kind = options?.kind ?? "all";
      const suffix = kind === "all" ? "" : `/${kind}`;
      return this.get(`/airports/${encodeURIComponent(code)}/flights${suffix}`, {
        ...dateQuery(options?.window),
        max_pages: options?.maxPages,
        cursor: options?.cursor,
      });
    },

    flightCounts: (code: string): Promise<AirportFlightCounts> =>
      this.get(`/airports/${encodeURIComponent(code)}/flights/counts`),

    flightsBetween: async (
      origin: string,
      destination: string,
      options?: {
        type?: FlightKind;
        connection?: ConnectionKind;
        window?: DateWindow;
        maxPages?: number;
        cursor?: string;
      },
    ): Promise<FlightsBetweenAirports> =>
      this.get(`/airports/${encodeURIComponent(origin)}/flights/to/${encodeURIComponent(destination)}`, {
        type: options?.type ?? "Airline",
        connection: options?.connection ?? "nonstop",
        ...dateQuery(options?.window),
        max_pages: options?.maxPages ?? 1,
        cursor: options?.cursor,
      }),

    nearby: (options: {
      code?: string;
      latitude?: number;
      longitude?: number;
      radius?: number;
      onlyInstrumentApproaches?: boolean;
      maxPages?: number;
      cursor?: string;
    }): Promise<NearbyAirports> => {
      const path = options.code ? `/airports/${encodeURIComponent(options.code)}/nearby` : "/airports/nearby";
      return this.get(path, {
        latitude: options.latitude,
        longitude: options.longitude,
        radius: options.radius ?? 250,
        only_iap: options.onlyInstrumentApproaches ?? false,
        max_pages: options.maxPages ?? 1,
        cursor: options.cursor,
      });
    },

    routes: (origin: string, destination: string, sortBy?: string): Promise<Record<string, unknown>> =>
      this.get(`/airports/${encodeURIComponent(origin)}/routes/${encodeURIComponent(destination)}`, {
        sort_by: sortBy,
      }),

    forecast: (code: string, timestamp?: Date, temperatureUnits?: "F" | "C"): Promise<Record<string, unknown>> =>
      this.get(`/airports/${encodeURIComponent(code)}/weather/forecast`, {
        timestamp,
        temperature_units: temperatureUnits,
      }),

    observations: (
      code: string,
      options?: { timestamp?: Date; temperatureUnits?: "F" | "C"; returnNearbyWeather?: boolean },
    ): Promise<Record<string, unknown>> =>
      this.get(`/airports/${encodeURIComponent(code)}/weather/observations`, {
        timestamp: options?.timestamp,
        temperature_units: options?.temperatureUnits,
        return_nearby_weather: options?.returnNearbyWeather,
      }),
  };

  readonly operators = {
    list: (maxPages = 1): Promise<OperatorPage> => this.get("/operators", { max_pages: maxPages }),

    get: (code: string): Promise<Operator> => this.get(`/operators/${encodeURIComponent(code)}`),

    canonical: (code: string, countryCode?: string): Promise<CanonicalOperatorResponse> =>
      this.get(`/operators/${encodeURIComponent(code)}/canonical`, { country_code: countryCode }),

    flights: async (
      code: string,
      options?: { kind?: OperatorFlightKind; window?: DateWindow; maxPages?: number; cursor?: string },
    ): Promise<OperatorFlights> => {
      const kind = options?.kind ?? "all";
      const suffix = kind === "all" ? "" : `/${kind}`;
      return this.get(`/operators/${encodeURIComponent(code)}/flights${suffix}`, {
        ...dateQuery(options?.window),
        max_pages: options?.maxPages ?? 1,
        cursor: options?.cursor,
      });
    },

    flightCounts: (code: string): Promise<OperatorFlightCounts> =>
      this.get(`/operators/${encodeURIComponent(code)}/flights/counts`),
  };

  readonly aircraft = {
    blocked: async (ident: string): Promise<boolean> => {
      const response = await this.get<BlockedAircraft>(`/aircraft/${encodeURIComponent(ident)}/blocked`);
      return response.blocked;
    },

    owner: (ident: string): Promise<AircraftOwner> => this.get(`/aircraft/${encodeURIComponent(ident)}/owner`),

    type: (icao: string): Promise<AircraftType> => this.get(`/aircraft/types/${encodeURIComponent(icao)}`),
  };

  readonly disruptions = {
    list: (
      entityType: DisruptionEntityType,
      options?: { timePeriod?: DisruptionTimePeriod; maxPages?: number },
    ): Promise<DisruptionCounts> =>
      this.get(`/disruption_counts/${entityType}/`, {
        time_period: options?.timePeriod ?? "today",
        max_pages: options?.maxPages ?? 1,
      }),

    get: (
      entityType: DisruptionEntityType,
      code: string,
      timePeriod: DisruptionTimePeriod = "today",
    ): Promise<DisruptionEntity> =>
      this.get(`/disruption_counts/${entityType}/${encodeURIComponent(code)}`, {
        time_period: timePeriod,
      }),
  };
}
