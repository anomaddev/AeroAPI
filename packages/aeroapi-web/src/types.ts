export type IdentType = "designator" | "fa_flight_id" | "registration";
export type AirportIdType = "icao" | "iata" | "lid";
export type FlightKind = "Airline" | "General_Aviation";
export type ConnectionKind = "nonstop" | "onestop";
export type AirportFlightKind =
  | "all"
  | "scheduled_arrivals"
  | "scheduled_departures"
  | "arrivals"
  | "departures";
export type OperatorFlightKind = "all" | "enroute" | "arrivals" | "scheduled";
export type DisruptionEntityType = "airline" | "origin" | "destination";
export type DisruptionTimePeriod =
  | "yesterday"
  | "today"
  | "tomorrow"
  | "plus2days"
  | "twoDaysAgo"
  | "minus2plus12hrs"
  | "next36hrs"
  | "week";

export const MapLayer = {
  usCities: "US Cities",
  europeBoundaries: "european country boundaries",
  asiaBoundaries: "asia country boundaries",
  majorAirports: "major airports",
  countryBoundaries: "country boundaries",
  usStateBoundaries: "US state boundaries",
  water: "water",
  usMajorRoads: "US major roads",
  radar: "radar",
  track: "track",
  flights: "flights",
  airports: "airports",
} as const;

export type MapLayerName = (typeof MapLayer)[keyof typeof MapLayer];

export interface PageLinks {
  next?: string;
  [key: string]: string | undefined;
}

export interface Flight {
  ident: string;
  identIcao?: string;
  identIata?: string;
  faFlightId: string;
  operatorIcao?: string;
  operatorIata?: string;
  flightNumber?: string;
  registration?: string;
  origin?: FlightEndpoint;
  destination?: FlightEndpoint;
  scheduledOut?: string;
  estimatedOut?: string;
  actualOut?: string;
  scheduledIn?: string;
  estimatedIn?: string;
  actualIn?: string;
  status?: string;
  aircraftType?: string;
  cancelled?: boolean;
  diverted?: boolean;
  blocked?: boolean;
  progressPercent?: number;
}

export interface FlightEndpoint {
  code?: string;
  codeIcao?: string;
  codeIata?: string;
  name?: string;
  city?: string;
  timezone?: string;
}

export interface FlightPage {
  flights?: Flight[];
  numPages?: number;
  links?: PageLinks;
}

export interface CanonicalIdent {
  ident: string;
  identType: IdentType;
}

export interface CanonicalFlightResponse {
  idents: CanonicalIdent[];
}

export interface FlightPosition {
  faFlightId?: string;
  altitude?: number;
  groundspeed?: number;
  heading?: number;
  latitude?: number;
  longitude?: number;
  timestamp?: string;
  updateType?: string;
}

export interface FlightRoute {
  routeDistance?: string | number;
  fixes?: Array<Record<string, unknown>>;
}

export interface FlightTrackPoint {
  faFlightId?: string;
  altitude: number;
  altitudeChange?: string;
  groundspeed: number;
  heading?: number;
  latitude: number;
  longitude: number;
  timestamp: string;
  updateType?: string;
}

export interface FlightTrackResponse {
  positions?: FlightTrackPoint[];
  actualDistance?: number;
}

export interface MapImage {
  /** Raw image bytes decoded from the AeroAPI `map` field. */
  bytes: Uint8Array;
  /** Data URL that can be used as an `<img>` source. */
  dataUrl: string;
}

export interface AirportSummary {
  code: string;
  airportInfoUrl?: string;
}

export interface AirportPage {
  airports?: AirportSummary[];
  numPages?: number;
  links?: PageLinks;
}

export interface Airport {
  code?: string;
  name?: string;
  city?: string;
  state?: string;
  countryCode?: string;
  timezone?: string;
  latitude?: number;
  longitude?: number;
  elevation?: number;
}

export interface CanonicalAirport {
  id: string;
  idType: AirportIdType;
}

export interface CanonicalAirportResponse {
  airports: CanonicalAirport[];
}

export interface AirportFlightCounts {
  departed: number;
  enroute: number;
  scheduledArrivals: number;
  scheduledDepartures: number;
}

export interface AirportFlights {
  scheduledArrivals?: Flight[];
  scheduledDepartures?: Flight[];
  arrivals?: Flight[];
  departures?: Flight[];
  numPages?: number;
  links?: PageLinks;
}

export interface FlightSegment {
  segments: Flight[];
}

export interface FlightsBetweenAirports {
  flights: FlightSegment[];
  numPages?: number;
  links?: PageLinks;
}

export interface NearbyAirport extends Airport {
  distance?: number;
  heading?: number;
  direction?: string;
}

export interface NearbyAirports {
  airports: NearbyAirport[];
  numPages?: number;
  links?: PageLinks;
}

export interface OperatorSummary {
  code: string;
  operatorInfoUrl?: string;
}

export interface OperatorPage {
  operators?: OperatorSummary[];
  numPages?: number;
  links?: PageLinks;
}

export interface Operator {
  icao?: string;
  iata?: string;
  name?: string;
  callsign?: string;
  country?: string;
  location?: string;
  phone?: string;
  shortname?: string;
  url?: string;
  wikiUrl?: string;
}

export interface CanonicalOperator {
  ident: string;
  identType: string;
}

export interface CanonicalOperatorResponse {
  operators: CanonicalOperator[];
}

export interface OperatorFlights {
  arrivals?: Flight[];
  scheduled?: Flight[];
  enroute?: Flight[];
  numPages?: number;
  links?: PageLinks;
}

export interface OperatorFlightCounts {
  departed?: number;
  enroute?: number;
  scheduled?: number;
  [key: string]: number | undefined;
}

export interface BlockedAircraft {
  blocked: boolean;
}

export interface AircraftOwner {
  name?: string;
  location?: string;
  location2?: string;
  website?: string;
}

export interface AircraftType {
  name?: string;
  iata?: string;
  ident?: string;
  manufacturer?: string;
  type?: string;
  description?: string;
  engineCount?: number;
  engineType?: string;
}

export interface DisruptionEntity {
  cancellations: number;
  delays: number;
  total: number;
  entityName?: string;
  entityId?: string;
}

export interface DisruptionCounts {
  entities: DisruptionEntity[];
  totalCancellationsNational?: number;
  totalCancellationsWorldwide?: number;
  totalDelaysWorldwide?: number;
  numPages?: number;
  links?: PageLinks;
}

export interface DateWindow {
  start: Date;
  end: Date;
}

export interface FlightListQuery {
  identType?: IdentType;
  start?: Date;
  end?: Date;
  maxPages?: number;
  cursor?: string;
  historical?: boolean;
}

export interface MapQuery {
  width?: number;
  height?: number;
  layersOn?: MapLayerName[];
  layersOff?: MapLayerName[];
  showDataBlock?: boolean;
  airportsExpandView?: boolean;
  showAirports?: boolean;
  historical?: boolean;
}
