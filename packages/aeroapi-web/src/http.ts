import { AeroErrors } from "./errors.js";

export const DEFAULT_BASE_URL = "https://aeroapi.flightaware.com/aeroapi";

export type QueryValue = string | number | boolean | Date | undefined | null;
export type Query = Record<string, QueryValue | QueryValue[]>;

export interface TransportResponse {
  ok: boolean;
  status: number;
  text(): Promise<string>;
}

export type Transport = (
  url: string,
  init: { method: string; headers: Record<string, string> },
) => Promise<TransportResponse>;

/** FlightAware timestamp format: `yyyy-MM-dd'T'HH:mm:ss'Z'`. */
export function formatAeroDate(date: Date): string {
  const pad = (value: number) => String(value).padStart(2, "0");
  return (
    `${date.getUTCFullYear()}-${pad(date.getUTCMonth() + 1)}-${pad(date.getUTCDate())}` +
    `T${pad(date.getUTCHours())}:${pad(date.getUTCMinutes())}:${pad(date.getUTCSeconds())}Z`
  );
}

export function encodeQuery(query: Query | undefined): string {
  if (!query) return "";
  const params = new URLSearchParams();
  for (const [key, raw] of Object.entries(query)) {
    const values = Array.isArray(raw) ? raw : [raw];
    for (const value of values) {
      if (value === undefined || value === null) continue;
      const text = value instanceof Date ? formatAeroDate(value) : String(value);
      params.append(key, text);
    }
  }
  const text = params.toString();
  return text ? `?${text}` : "";
}

export function camelize<T>(value: unknown): T {
  return convert(value) as T;
}

function convert(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(convert);
  if (value !== null && typeof value === "object") {
    const output: Record<string, unknown> = {};
    for (const [key, child] of Object.entries(value as Record<string, unknown>)) {
      const camel = key.replace(/_([a-z0-9])/g, (_, char: string) => char.toUpperCase());
      output[camel] = convert(child);
    }
    return output;
  }
  return value;
}

export function decodeBase64(value: string): Uint8Array {
  const binary = atob(value);
  const bytes = new Uint8Array(binary.length);
  for (let index = 0; index < binary.length; index += 1) {
    bytes[index] = binary.charCodeAt(index);
  }
  return bytes;
}

export async function send<T>(
  transport: Transport,
  baseUrl: string,
  apiKey: string,
  path: string,
  query?: Query,
): Promise<T> {
  if (!apiKey) throw AeroErrors.apiKeyNotSet();

  const url = `${baseUrl.replace(/\/$/, "")}${path}${encodeQuery(query)}`;
  let response: TransportResponse;
  try {
    response = await transport(url, {
      method: "GET",
      headers: {
        "x-apikey": apiKey,
        accept: "application/json",
      },
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Network request failed";
    throw AeroErrors.network(message);
  }

  const body = await response.text();
  if (!response.ok) {
    throw AeroErrors.http(response.status, body);
  }
  if (!body) {
    throw AeroErrors.noData(response.status);
  }

  let parsed: unknown;
  try {
    parsed = JSON.parse(body);
  } catch {
    throw AeroErrors.invalidJSON(response.status, body);
  }
  return camelize<T>(parsed);
}
