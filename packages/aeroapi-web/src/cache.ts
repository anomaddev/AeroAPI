import { AeroErrors } from "./errors.js";
import {
  Aircraft,
  Airline,
  Airport,
  asAircraft,
  asAirline,
  asAirport,
  referenceCache,
} from "./models.js";

export interface CacheInput {
  airports?: object[];
  airlines?: object[];
  aircraft?: object[];
}

function databaseDirectory(): Promise<string> {
  return Promise.all([import("node:path"), import("node:url")]).then(([{ dirname, join }, { fileURLToPath }]) =>
    join(dirname(fileURLToPath(import.meta.url)), "../../aeroapi-swift/Sources/AeroAPI/Databases"),
  );
}

async function readDatabase(name: string): Promise<object[]> {
  try {
    const [{ readFile }, directory] = await Promise.all([import("node:fs/promises"), databaseDirectory()]);
    const { join } = await import("node:path");
    const text = await readFile(join(directory, `${name}.json`), "utf8");
    const parsed = JSON.parse(text) as unknown;
    if (!Array.isArray(parsed)) throw AeroErrors.network(`${name}.json is not an array`);
    return parsed as object[];
  } catch (error) {
    if (error instanceof Error && error.name === "AeroAPIError") throw error;
    throw AeroErrors.network(
      `Could not read the ${name} cache. Pass the parsed array to loadCache(), or run it from this monorepo on Node.js.`,
    );
  }
}

export async function loadReferenceCache(input: CacheInput = {}): Promise<void> {
  const [airports, airlines, aircraft] = await Promise.all([
    input.airports ? Promise.resolve(input.airports) : readDatabase("airports"),
    input.airlines ? Promise.resolve(input.airlines) : readDatabase("airlines"),
    input.aircraft ? Promise.resolve(input.aircraft) : readDatabase("aircraft"),
  ]);
  replace(referenceCache.airports, airports.map((item) => asAirport(item)));
  replace(referenceCache.airlines, airlines.map((item) => asAirline(item)));
  replace(referenceCache.aircraft, aircraft.map((item) => asAircraft(item)));
}

function replace<T>(target: T[], next: T[]): void {
  target.splice(0, target.length, ...next);
}

export function mergeAirport(airport: Airport, keys: { icao?: string; iata?: string; code?: string }): Airport {
  const cached = referenceCache.airports.find(
    (item) =>
      (keys.icao != null && item.codeIcao === keys.icao) ||
      (keys.iata != null && item.codeIata === keys.iata) ||
      (keys.code != null && item.airportCode === keys.code),
  );
  if (!cached) return airport;
  cached.airportCode = airport.airportCode;
  cached.codeLid = airport.codeLid;
  cached.name = airport.name;
  cached.type = airport.type;
  cached.elevation = airport.elevation;
  cached.city = airport.city;
  cached.state = airport.state;
  cached.longitude = airport.longitude;
  cached.latitude = airport.latitude;
  cached.timezone = airport.timezone;
  cached.countryCode = airport.countryCode;
  cached.url = airport.url;
  cached.wikiUrl = airport.wikiUrl;
  cached.airportFlightsUrl = airport.airportFlightsUrl;
  cached.alternatives = airport.alternatives;
  return cached;
}

export function mergeAirline(airline: Airline, keys: { icao?: string; iata?: string }): Airline {
  const cached = referenceCache.airlines.find(
    (item) => (keys.icao != null && item.icao === keys.icao) || (keys.iata != null && item.iata === keys.iata),
  );
  if (!cached) return airline;
  cached.callsign = airline.callsign;
  cached.name = airline.name;
  cached.shortname = airline.shortname;
  cached.country = airline.country;
  cached.location = airline.location;
  cached.url = airline.url;
  cached.wikiUrl = airline.wikiUrl;
  cached.alternatives = airline.alternatives;
  return cached;
}

export function mergeAircraft(aircraft: Aircraft, icao: string): Aircraft {
  const cached = referenceCache.aircraft.find((item) => item.ident === icao);
  if (!cached) return aircraft;
  cached.manufacturer = aircraft.manufacturer;
  cached.type = aircraft.type;
  cached.description = aircraft.description;
  cached.engineCount = aircraft.engineCount;
  cached.engineType = aircraft.engineType;
  return cached;
}
