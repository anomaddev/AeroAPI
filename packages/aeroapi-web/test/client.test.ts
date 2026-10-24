import assert from "node:assert/strict";
import { createServer, type IncomingMessage, type Server } from "node:http";
import { once } from "node:events";
import test from "node:test";
import {
  AeroAPI,
  AeroAPIError,
  Airport,
  Flight,
  FlightAwareMapLayer,
  FlightDataRequest,
  MapDataRequest,
  ScheduledFlightRequest,
  airportFlights,
  airlineFlights,
  airportsNear,
  flightsBetween,
} from "../dist/index.js";

const ONE_PIXEL_PNG =
  "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==";

interface CapturedRequest {
  method: string | undefined;
  url: string | undefined;
  apiKey: string | string[] | undefined;
}

async function listen(handler: (request: IncomingMessage) => { status: number; json: unknown }): Promise<{
  server: Server;
  baseUrl: string;
  requests: CapturedRequest[];
}> {
  const requests: CapturedRequest[] = [];
  const server = createServer((request, response) => {
    requests.push({ method: request.method, url: request.url, apiKey: request.headers["x-apikey"] });
    const result = handler(request);
    response.statusCode = result.status;
    response.setHeader("content-type", "application/json");
    response.end(JSON.stringify(result.json));
  });
  server.listen(0, "127.0.0.1");
  await once(server, "listening");
  const address = server.address();
  if (!address || typeof address === "string") throw new Error("missing port");
  return { server, baseUrl: `http://127.0.0.1:${address.port}/aeroapi`, requests };
}

async function close(server: Server): Promise<void> {
  server.close();
  await once(server, "close");
}

function pathOf(url: string | undefined): string {
  return new URL(url ?? "", "http://127.0.0.1").pathname;
}

test("getFlightData looks up one flight and a filtered page", async () => {
  const fixture = await listen((request) => {
    if (request.url?.includes("ident_type=fa_flight_id")) {
      return { status: 200, json: { num_pages: 1, flights: [{ ident: "UAL1", fa_flight_id: "UAL1-1700000000-fa-1" }] } };
    }
    return {
      status: 200,
      json: { num_pages: 2, flights: [{ ident: "UAL4", fa_flight_id: "UAL4-1700000000-fa-1", operator_icao: "UAL" }] },
    };
  });
  try {
    const api = new AeroAPI({ apiKey: "test-key", baseUrl: fixture.baseUrl });
    const flight = await api.getFlightData("UAL1-1700000000-fa-1");
    assert.ok(flight instanceof Flight);
    assert.equal(flight?.faFlightId, "UAL1-1700000000-fa-1");
    const page = await api.getFlightData(FlightDataRequest.ident({ ident: "UAL4", type: "designator", maxPages: 2 }));
    assert.equal(page.numPages, 2);
    assert.equal(page.flights?.[0]?.operatorIcao, "UAL");
    assert.equal(fixture.requests[0]?.apiKey, "test-key");
    const listed = new URL(fixture.requests[1]?.url ?? "", "http://127.0.0.1");
    assert.equal(listed.pathname, "/aeroapi/flights/UAL4");
    assert.equal(listed.searchParams.get("ident_type"), "designator");
    assert.equal(listed.searchParams.get("max_pages"), "2");
  } finally {
    await close(fixture.server);
  }
});

test("getMap decodes history images and getTrack rejects an empty track", async () => {
  const fixture = await listen((request) => {
    if (request.url?.includes("/map")) return { status: 200, json: { map: ONE_PIXEL_PNG } };
    return { status: 200, json: { positions: [] } };
  });
  try {
    const api = new AeroAPI({ apiKey: "test-key", baseUrl: fixture.baseUrl });
    const faId = "UAL1-1600000000-fa-1";
    const image = await api.getMap(
      new MapDataRequest(faId, { width: 32, height: 32, layersOn: [FlightAwareMapLayer.track], layersOff: [FlightAwareMapLayer.radar], showAirports: true }),
    );
    assert.equal(image.bytes[0], 0x89);
    assert.match(image.dataUrl, /^data:image\/png;base64,/);
    const mapUrl = new URL(fixture.requests[0]?.url ?? "", "http://127.0.0.1");
    assert.equal(mapUrl.pathname, `/aeroapi/history/flights/${faId}/map`);
    assert.equal(mapUrl.searchParams.get("width"), "32");
    assert.deepEqual(mapUrl.searchParams.getAll("layer_off"), [FlightAwareMapLayer.radar]);
    await assert.rejects(() => api.getTrack(faId), (error: unknown) => {
      assert.ok(error instanceof AeroAPIError);
      assert.equal(error.code, "flightTrackEmpty");
      return true;
    });
  } finally {
    await close(fixture.server);
  }
});

test("airport, operator, aircraft, and disruption methods use the Swift paths", async () => {
  const fixture = await listen(() => ({ status: 200, json: { blocked: false, name: "Live", ident: "B738", entities: [] } }));
  try {
    const api = new AeroAPI({ apiKey: "test-key", baseUrl: fixture.baseUrl });
    const window = { start: new Date(Date.now() - 60_000), end: new Date(Date.now() + 60_000) };
    await api.getAirportFlights(airportFlights("KSFO", { requestType: "arrivals", dateRange: window }));
    await api.getFlightsBetweenAirports(flightsBetween("KSFO", "KLAX"));
    await api.getAirportsNear(airportsNear({ latitude: 37.6, longitude: -122.4, radius: 25 }));
    await api.getAirlineFlights(airlineFlights("UAL", { requestType: "enroute" }));
    assert.equal(await api.checkBlocked("N12345"), false);
    await api.getAircraftInfo("B738");
    await api.disruptionsAt({ entity: "UAL", type: "airline", timePeriod: "today" });
    assert.deepEqual(fixture.requests.map((request) => pathOf(request.url)), [
      "/aeroapi/airports/KSFO/flights/arrivals",
      "/aeroapi/airports/KSFO/flights/to/KLAX",
      "/aeroapi/airports/nearby",
      "/aeroapi/operators/UAL/flights/enroute",
      "/aeroapi/aircraft/N12345/blocked",
      "/aeroapi/aircraft/types/B738",
      "/aeroapi/disruption_counts/airline/UAL",
    ]);
  } finally {
    await close(fixture.server);
  }
});

test("rejects a missing key, HTTP errors, bad map sizes, and invalid dates", async () => {
  const api = new AeroAPI({ apiKey: "" });
  await assert.rejects(() => api.getFlightData(FlightDataRequest.ident({ ident: "UAL1" })), (error: unknown) => {
    assert.ok(error instanceof AeroAPIError);
    assert.equal(error.code, "apiKeyNotSet");
    return true;
  });

  const fixture = await listen(() => ({ status: 401, json: { title: "Unauthorized" } }));
  try {
    const authed = new AeroAPI({ apiKey: "nope", baseUrl: fixture.baseUrl });
    await assert.rejects(() => authed.getAirportInfo({ code: "KSFO" }), (error: unknown) => {
      assert.ok(error instanceof AeroAPIError);
      assert.equal(error.status, 401);
      assert.equal(error.code, "HTTPResponseError");
      return true;
    });
  } finally {
    await close(fixture.server);
  }

  assert.throws(() => new MapDataRequest("UAL1-9999999999-fa-1", { width: 0, height: 10 }), (error: unknown) => {
    assert.ok(error instanceof AeroAPIError);
    assert.equal(error.code, "invalidMapWidth");
    return true;
  });
  assert.throws(
    () => airportFlights("KSFO", { dateRange: { start: new Date("2020-01-02"), end: new Date("2020-01-01") } }).query(),
    (error: unknown) => {
      assert.ok(error instanceof AeroAPIError);
      assert.equal(error.code, "startDateBeforeEndDate");
      return true;
    },
  );
  await assert.rejects(() => new AeroAPI({ apiKey: "k" }).getRoute("not-a-flight-id"), (error: unknown) => {
    assert.ok(error instanceof AeroAPIError);
    assert.equal(error.code, "faIdDateInvalid");
    return true;
  });
});

test("Airport.search, shortName, and getAirportInfo merge an injected cache", async () => {
  const api = new AeroAPI({ apiKey: "test-key", fetch: async () => { throw new Error("unused"); } });
  await api.loadCache({
    airports: [{ airportCode: "KSFO", codeIcao: "KSFO", codeIata: "SFO", name: "San Francisco International Airport", city: "San Francisco", countryCode: "US", latitude: 37.62, longitude: -122.38 }],
    airlines: [{ icao: "UAL", iata: "UA", name: "Cached United", callsign: "UNITED" }],
    aircraft: [{ ident: "B738", iata: "738", name: "737-800", range: 5400 }],
  });
  const found = Airport.search("SFO");
  assert.equal(found.length, 1);
  assert.equal(found[0]?.shortName, "San Francisco Intl. ");
  assert.equal(AeroAPI.manager === AeroAPI.manager, true);

  const fixture = await listen(() => ({
    status: 200,
    json: { airport_code: "KSFO", name: "San Francisco Intl", city: "San Francisco", country_code: "US", latitude: 37.6, longitude: -122.4, timezone: "America/Los_Angeles" },
  }));
  try {
    const live = new AeroAPI({ apiKey: "test-key", baseUrl: fixture.baseUrl });
    const airport = await live.getAirportInfo({ icao: "KSFO" });
    assert.equal(airport.name, "San Francisco Intl");
    assert.equal(airport.codeIata, "SFO");
    assert.equal(airport.timezone, "America/Los_Angeles");
    assert.equal(airport, AeroAPI.allAirports.find((item) => item.codeIcao === "KSFO"));
  } finally {
    await close(fixture.server);
  }
});

test("flight helpers and scheduled codeshare merge", async () => {
  const api = new AeroAPI();
  await api.loadCache({
    airports: [
      { airportCode: "KSFO", codeIcao: "KSFO", codeIata: "SFO", name: "San Francisco International Airport", city: "San Francisco", countryCode: "US", latitude: 37.62, longitude: -122.38 },
      { airportCode: "KLAX", codeIcao: "KLAX", codeIata: "LAX", name: "Los Angeles International Airport", city: "Los Angeles", countryCode: "US", latitude: 33.94, longitude: -118.41 },
    ],
    airlines: [{ icao: "UAL", iata: "UA", name: "Cached United", callsign: "UNITED" }],
    aircraft: [],
  });
  const flight = Object.assign(new Flight(), {
    ident: "UAL1",
    faFlightId: "UAL1-1-fa-1",
    origin: { code: "KSFO" },
    destination: { code: "KLAX" },
    scheduledOut: "2020-01-01T00:00:00Z",
    scheduledIn: "2020-01-01T01:30:00Z",
    operatorIcao: "UAL",
  });
  assert.equal(flight.duration(Date.parse("2020-01-01T02:00:00Z")), 90 * 60);
  assert.equal(flight.departure()[0], "2020-01-01T00:00:00Z");
  assert.equal(flight.operating?.callsign, "UNITED");
  const distance = flight.distanceKm();
  assert.ok(distance != null && distance > 400 && distance < 600);

  const origin = AeroAPI.allAirports[0];
  assert.ok(origin);
  const request = ScheduledFlightRequest.ident(1, 2024, origin, "UAL1");
  assert.equal(request.path(), "");
  assert.equal(request.query().ident, "UAL1");
});
