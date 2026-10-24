export type IdentType = "designator" | "fa_flight_id" | "registration";
export type AirportIdType = "icao" | "iata" | "lid";
export type AirlineIdType = "icao" | "iata";
export type FlightType = "Airline" | "General_Aviation";
export type FlightConnectionType = "nonstop" | "onestop";
export type AirportFlightsRequestType =
  | "all"
  | "scheduledArrivals"
  | "scheduledDepartures"
  | "arrivals"
  | "departures";
export type AirlineFlightsRequestType = "all" | "enroute" | "arrivals" | "scheduled";
export type DisruptionCountType = "airline" | "origin" | "destination";
export type DisruptionCountTimePeriod =
  | "yesterday"
  | "today"
  | "tomorrow"
  | "plus2days"
  | "twoDaysAgo"
  | "minus2plus12hrs"
  | "next36hrs"
  | "week";
export type RouteRequestSort = "count" | "last_departure_time";
export type TemperatureUnits = "C" | "F" | "Celsius" | "Fahrenheit";
export type AirportType = "Airport" | "Heliport" | "Seaplane Base" | "Balloonport" | "Ultralight" | "Gliderport" | "Stolport";
export type MapDirection = "N" | "E" | "S" | "W" | "NE" | "SE" | "SW" | "NW";
export type AltChange = "-" | "C" | "D";
export type AirportStatusColor = "red" | "yellow" | "green";

export const FlightAwareMapLayer = {
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

export type FlightAwareMapLayer = (typeof FlightAwareMapLayer)[keyof typeof FlightAwareMapLayer];

export interface Coordinate {
  latitude: number;
  longitude: number;
}

export interface PageLinks {
  next?: string;
  [key: string]: string | undefined;
}

export interface DateRange {
  start: Date;
  end: Date;
}

export class Airport {
  airportCode?: string;
  codeIcao?: string;
  codeIata?: string;
  codeLid?: string;
  name = "";
  type?: AirportType | string;
  elevation?: number;
  city = "";
  state?: string;
  countryCode = "";
  timezone?: string;
  longitude = 0;
  latitude = 0;
  url?: string;
  wikiUrl?: string;
  airportFlightsUrl?: string;
  alternatives?: Airport[];
  facebook?: string;
  twitter?: string;
  instagram?: string;
  youtube?: string;
  phone?: string;
  email?: string;

  get coordinate(): Coordinate {
    return { latitude: this.latitude, longitude: this.longitude };
  }

  get shortName(): string {
    return this.name
      .replaceAll("Regional", "Regl.")
      .replaceAll("Metropolitan", "Metro.")
      .replaceAll("International", "Intl.")
      .replaceAll("Airport", "");
  }

  /** Case-sensitive ICAO, IATA, then name search, matching `Airport.search(using:)`. */
  static search(text: string, source?: Airport[]): Airport[] {
    const airports = source ?? referenceCache.airports;
    const icao = airports.filter((airport) => airport.codeIcao === text);
    const iata = airports.filter((airport) => airport.codeIata === text);
    const name = airports.filter((airport) => airport.name.includes(text));
    return [...icao, ...iata, ...name];
  }
}

export class Airline {
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
  alternatives?: Airline[];
  active?: boolean;
  operates?: string;
  facebook?: string;
  twitter?: string;
  instagram?: string;
  youtube?: string;
  reservations?: string;
  email?: string;
  website?: string;
  loyalty?: string;
  ally?: string;
}

export class Aircraft {
  name?: string;
  iata?: string;
  ident?: string;
  manufacturer?: string;
  type?: string;
  description?: string;
  engineCount?: number;
  engineType?: string;
  cruise?: number;
  range?: number;
}

export interface FlightAirport {
  code: string;
  codeIcao?: string;
  codeIata?: string;
  codeLid?: string;
  airportInfoUrl?: string;
}

export class Flight {
  ident = "";
  identIcao?: string;
  identIata?: string;
  faFlightId = "";
  operatorIcao?: string;
  operatorIata?: string;
  flightNumber?: string;
  registration?: string;
  atcIdent?: string;
  inboundFaFlightId?: string;
  codeshares?: string[];
  codesharesIata?: string[];
  blocked?: boolean;
  diverted?: boolean;
  cancelled?: boolean;
  positionOnly?: boolean;
  origin?: FlightAirport;
  destination?: FlightAirport;
  departureDelay?: number;
  arrivalDelay?: number;
  filedEte?: number;
  scheduledOut?: string;
  estimatedOut?: string;
  actualOut?: string;
  scheduledOff?: string;
  estimatedOff?: string;
  actualOff?: string;
  scheduledOn?: string;
  estimatedOn?: string;
  actualOn?: string;
  scheduledIn?: string;
  estimatedIn?: string;
  actualIn?: string;
  progressPercent?: number;
  status?: string;
  aircraftType?: string;
  routeDistance?: number;
  filedAirspeed?: number;
  filedAltitude?: number;
  route?: string;
  baggageClaim?: string;
  seatsCabinBusiness?: number;
  seatsCabinCoach?: number;
  seatsCabinFirst?: number;
  gateOrigin?: string;
  gateDestination?: string;
  terminalOrigin?: string;
  terminalDestination?: string;
  type?: string;
  lastPosition?: LastPosition;
  updated?: string;

  get operating(): Airline | undefined {
    return airlineFor(this.operatorIcao) ?? airlineFor(this.operatorIata);
  }

  /** Scheduled, estimated, and actual out times. */
  departure(): [string | undefined, string | undefined, string | undefined] {
    return [this.scheduledOut, this.estimatedOut, this.actualOut];
  }

  /** Scheduled, estimated, and actual in times. */
  arrival(): [string | undefined, string | undefined, string | undefined] {
    return [this.scheduledIn, this.estimatedIn, this.actualIn];
  }

  /** Flight duration in seconds. */
  duration(now = Date.now()): number | null {
    const scheduledIn = millis(this.scheduledIn);
    if (scheduledIn == null) return null;
    if (scheduledIn < now) {
      const actualIn = millis(this.actualIn);
      const actualOut = millis(this.actualOut);
      if (actualIn != null && actualOut != null) return (actualIn - actualOut) / 1000;
      const scheduledOut = millis(this.scheduledOut);
      if (scheduledOut == null) return null;
      return (scheduledIn - scheduledOut) / 1000;
    }
    const scheduledOut = millis(this.scheduledOut);
    if (scheduledOut == null) return null;
    return (scheduledIn - scheduledOut) / 1000;
  }

  /** Haversine distance in kilometers between the cached origin and destination airports. */
  distanceKm(): number | null {
    const origin = airportFor(this.origin?.code);
    const destination = airportFor(this.destination?.code);
    if (!origin || !destination) return null;
    return haversineKm(origin.coordinate, destination.coordinate);
  }
}

export interface FlightDataResponse {
  numPages?: number;
  flights?: Flight[];
  links?: PageLinks;
}

export interface CanonicalFlightId {
  ident: string;
  identType: IdentType;
}

export interface CanonicalFlightIdResponse {
  idents: CanonicalFlightId[];
}

export interface LastPosition {
  faFlightId?: string;
  altitude: number;
  altitudeChange: AltChange | string;
  groundspeed: number;
  heading?: number;
  latitude: number;
  longitude: number;
  timestamp: string;
  updateType?: string;
}

export interface FlightPositionAirport {
  code: string;
  codeIcao?: string;
  codeIata?: string;
  codeLid?: string;
  timezone?: string;
  name?: string;
  city?: string;
  airportInfoUrl?: string;
}

export interface FlightSearchResponse {
  ident: string;
  identIcao?: string;
  identIata?: string;
  faFlightId: string;
  origin: FlightPositionAirport;
  destination: FlightPositionAirport;
  waypoints?: number[];
  firstPositionTime?: string;
  lastPosition: LastPosition;
  boundingBox?: number[];
  identPrefix?: string;
  aircraftType?: string;
  foresightPredictionsAvailable?: boolean;
  actualOff?: string;
  actualOn?: string;
  predictedOut?: string;
  predictedOff?: string;
  predictedOn?: string;
  predictedIn?: string;
  predictedOutSource?: string;
  predictedOffSource?: string;
  predictedOnSource?: string;
  predictedInSource?: string;
}

export interface FlightFix {
  name: string;
  latitude?: number;
  longitude?: number;
  distanceFromOrigin?: number;
  distanceThisLeg?: number;
  distanceToDestination?: number;
  outboundCourse?: number;
  type: string;
}

export interface FlightRoute {
  routeDistance?: string;
  fixes?: FlightFix[];
}

export interface FlightTrackPoint {
  faFlightId?: string;
  altitude: number;
  altitudeChange?: AltChange | string;
  groundspeed: number;
  heading?: number;
  latitude: number;
  longitude: number;
  timestamp: string;
  updateType?: string;
}

export interface MapImage {
  bytes: Uint8Array;
  dataUrl: string;
}

export interface MapBounds {
  NWCoord: Coordinate;
  NECoord: Coordinate;
  SECoord: Coordinate;
  SWCoord: Coordinate;
}

export type AdvancedSearchParameter =
  | { kind: "origin"; airport: Airport }
  | { kind: "originOrDest"; airport: Airport }
  | { kind: "destination"; airport: Airport }
  | { kind: "mapBounds"; bounds: MapBounds };

export interface AirportsResponse {
  airports?: Array<{ code: string; airportInfoUrl?: string }>;
  numPages?: number;
  links?: PageLinks;
}

export interface CanonicalAirportId {
  id: string;
  idType: AirportIdType;
}

export interface CanonicalAirportResponse {
  airports: CanonicalAirportId[];
}

export interface AirportFlightCounts {
  departed: number;
  enroute: number;
  scheduledArrivals: number;
  scheduledDepartures: number;
}

export interface AirportFlightsResponse {
  scheduledArrivals?: Flight[];
  scheduledDepartures?: Flight[];
  arrivals?: Flight[];
  departures?: Flight[];
  links?: PageLinks;
  numPages?: number;
}

export interface FlightSegment {
  segments: Flight[];
}

export interface FlightsBetweenAirportsResponse {
  flights?: FlightSegment[];
  numPages?: number;
  links?: PageLinks;
}

export interface AirportNearby extends Airport {
  distance?: number;
  heading?: number;
  direction?: MapDirection | string;
}

export interface AirportsNearbyResponse {
  airports?: AirportNearby[];
  numPages?: number;
  links?: PageLinks;
}

export interface DelayReason {
  category: string;
  color: AirportStatusColor | string;
  delaySecs: number;
  reason: string;
}

export interface AirportStatus {
  airport: string;
  category: string;
  color: AirportStatusColor | string;
  delaySecs: number;
  reasons?: DelayReason[];
}

export interface AirportsDelayedResponse {
  delays?: AirportStatus[];
  numPages?: number;
  links?: PageLinks;
}

export interface ObservedClouds {
  altitude?: number;
  symbol: string;
  type: string;
}

export interface WeatherObservation {
  airportCode: string;
  cloudFriendly?: string;
  clouds?: ObservedClouds[];
  conditions?: string;
  pressure?: number;
  pressureUnits?: string;
  rawData?: string;
  tempAir?: number;
  tempDewpoint?: number;
  tempPerceived?: number;
  relativeHumidity?: number;
  time?: string;
  visibility?: number;
  visibilityUnits?: string;
  windDirection?: number;
  windFriendly?: string;
  windSpeed?: number;
  windSpeedGust?: number;
  windUnits?: string;
}

export interface AirportWeatherObservationsResponse {
  observations?: WeatherObservation[];
  numPages?: number;
  links?: PageLinks;
}

export interface ForecastWinds {
  symbol: string;
  direction: string;
  speed: number;
  units?: string;
  peakGusts?: number;
}

export interface ForecastClouds {
  symbol: string;
  coverage?: string;
  altitude?: string;
  special?: string;
}

export interface ForecastLine {
  type: string;
  start?: string;
  end?: string;
  turbulenceLayers?: string;
  icingLayers?: string;
  barometricPressure?: number;
  significantWeather?: string;
  winds?: ForecastWinds;
  visibility?: { symbol: string; visibility: string; units?: string };
  clouds?: ForecastClouds[];
}

export interface AirportWeatherForecastResponse {
  airportCode?: string;
  rawForecast?: string[];
  time?: string;
  decodedForecast?: { start?: string; end?: string; lines?: ForecastLine[] };
}

export interface AirportRoute {
  aircraftTypes?: string[];
  count: number;
  filedAltitudeMax?: number;
  filedAltitudeMin?: number;
  lastDepartureTime?: string;
  route: string;
  routeDistance?: string;
}

export interface AirportRouteResponse {
  routes?: AirportRoute[];
  numPages?: number;
  links?: PageLinks;
}

export interface OperatorsSummary {
  code: string;
  operatorInfoUrl?: string;
}

export interface AirlinesResponse {
  operators?: OperatorsSummary[];
  numPages?: number;
  links?: PageLinks;
}

export interface CanonicalAirlineId {
  id: string;
  idType: AirlineIdType;
}

export interface CanonicalAirlineResponse {
  operators: CanonicalAirlineId[];
}

export interface AirlineFlightCountResponse {
  airborne?: number;
  flightsLast24Hours?: number;
}

export interface AirlineFlightsResponse {
  arrivals?: Flight[];
  scheduled?: Flight[];
  enroute?: Flight[];
  links?: PageLinks;
  numPages?: number;
}

export interface BlockedResponse {
  blocked: boolean;
}

export interface LastFlightResponse {
  flights?: Flight[];
}

export interface AircraftOwner {
  name?: string;
  location?: string;
  location2?: string;
  website?: string;
}

export interface AircraftOwnerResponse {
  owner?: AircraftOwner;
}

export interface DisruptionEntity {
  cancellations: number;
  delays: number;
  total: number;
  entityName?: string;
  entityId?: string;
}

export interface DisruptionCountResponse {
  entities?: DisruptionEntity[];
  totalCancellationsNational?: number;
  totalCancellationsWorldwide?: number;
  totalDelaysWorldwide?: number;
  numPages?: number;
  links?: PageLinks;
}

export interface Codeshare {
  ident: string;
  identIcao?: string;
  identIata?: string;
  actualIdent?: string;
}

export interface ScheduledFlight {
  faFlightId?: string;
  ident: string;
  identIcao?: string;
  identIata?: string;
  actualIdent?: string;
  actualIdentIcao?: string;
  actualIdentIata?: string;
  aircraftType?: string;
  scheduledIn?: string;
  scheduledOut?: string;
  origin?: string;
  originIcao?: string;
  originIata?: string;
  originLid?: string;
  destination?: string;
  destinationIcao?: string;
  destinationIata?: string;
  destinationLid?: string;
  mealService?: string;
  seatsCabinBusiness?: number;
  seatsCabinCoach?: number;
  seatsCabinFirst?: number;
  codeshares?: Codeshare[];
  updated?: string;
  archived?: boolean;
}

export interface ScheduledFlightResponse {
  numPages?: number;
  scheduled?: ScheduledFlight[];
  links?: PageLinks;
}

export const referenceCache: {
  airports: Airport[];
  airlines: Airline[];
  aircraft: Aircraft[];
} = {
  airports: [],
  airlines: [],
  aircraft: [],
};

export function airportFor(code?: string): Airport | undefined {
  if (!code) return undefined;
  return referenceCache.airports.find((airport) => airport.codeIcao === code || airport.codeIata === code);
}

export function airlineFor(code?: string): Airline | undefined {
  if (!code) return undefined;
  return referenceCache.airlines.find((airline) => airline.icao === code || airline.iata === code);
}

export function aircraftFor(code?: string): Aircraft | undefined {
  if (!code) return undefined;
  return referenceCache.aircraft.find((aircraft) => aircraft.ident === code || aircraft.iata === code);
}

export function hydrate<T extends object>(ctor: new () => T, value: object): T {
  return Object.assign(new ctor(), value);
}

export function asFlight(value: object): Flight {
  const flight = hydrate(Flight, value);
  if (flight.origin) flight.origin = { ...flight.origin };
  if (flight.destination) flight.destination = { ...flight.destination };
  return flight;
}

export function asFlights(values: object[] | undefined): Flight[] | undefined {
  return values?.map((value) => asFlight(value));
}

export function asAirport(value: object): Airport {
  return hydrate(Airport, value);
}

export function asAirline(value: object): Airline {
  return hydrate(Airline, value);
}

export function asAircraft(value: object): Aircraft {
  return hydrate(Aircraft, value);
}

export function haversineKm(from: Coordinate, to: Coordinate): number {
  const earthKm = 6371;
  const latDelta = radians(to.latitude - from.latitude);
  const lonDelta = radians(to.longitude - from.longitude);
  const lat1 = radians(from.latitude);
  const lat2 = radians(to.latitude);
  const a = Math.sin(latDelta / 2) ** 2 + Math.cos(lat1) * Math.cos(lat2) * Math.sin(lonDelta / 2) ** 2;
  return 2 * earthKm * Math.asin(Math.min(1, Math.sqrt(a)));
}

function radians(degrees: number): number {
  return (degrees * Math.PI) / 180;
}

function millis(value?: string): number | null {
  if (!value) return null;
  const parsed = Date.parse(value);
  return Number.isNaN(parsed) ? null : parsed;
}

export function codeshareFrom(flight: ScheduledFlight): Codeshare {
  return {
    ident: flight.ident,
    identIcao: flight.identIcao,
    identIata: flight.identIata,
    actualIdent: flight.actualIdent,
  };
}

/** Swift `mergeCodeshares`, without the debug prints. */
export function mergeCodeshares(flights: ScheduledFlight[]): ScheduledFlight[] {
  const children = flights.filter((flight) => flight.actualIdent != null && flight.actualIdent !== "");
  const parents = flights.filter((flight) => flight.actualIdent == null);
  const orphaned = children.filter(
    (code) => !parents.some((flight) => code.actualIdent === flight.ident),
  );
  const groups = new Map<string, ScheduledFlight[]>();
  for (const flight of orphaned) {
    const key = flight.actualIdent ?? "";
    const group = groups.get(key) ?? [];
    group.push(flight);
    groups.set(key, group);
  }
  const orphans: ScheduledFlight[] = [];
  for (const [key, group] of groups) {
    const parent = group.find((flight) => flight.actualIdent === key);
    if (!parent?.actualIdent) continue;
    const next: ScheduledFlight = {
      ...parent,
      ident: parent.actualIdent,
      identIata: parent.actualIdentIata,
      identIcao: parent.actualIdentIcao,
      codeshares: group.map(codeshareFrom),
      actualIdent: undefined,
      actualIdentIata: undefined,
      actualIdentIcao: undefined,
    };
    orphans.push(next);
  }
  const merges = orphans.filter((flight) =>
    orphans.some((share) => share.codeshares?.some((item) => item.ident === flight.ident)),
  );
  const masters = merges.flatMap((flight) => {
    const master = orphans.find((share) => share.codeshares?.some((item) => item.ident === flight.ident));
    return master ? [master] : [];
  });
  const uniqueMasters = [...new Set(masters)];
  const leftovers = orphans.filter(
    (flight) => !merges.some((item) => flight.ident === item.ident) && !uniqueMasters.some((item) => flight.ident === item.ident),
  );
  const merged = uniqueMasters.map((master) => {
    const scheduled: ScheduledFlight = { ...master, codeshares: [...(master.codeshares ?? [])] };
    const match = merges.filter((flight) => scheduled.codeshares?.some((item) => item.ident === flight.ident));
    for (const item of match) scheduled.codeshares?.push(...(item.codeshares ?? []));
    return scheduled;
  });
  return [...merged, ...leftovers, ...parents];
}
