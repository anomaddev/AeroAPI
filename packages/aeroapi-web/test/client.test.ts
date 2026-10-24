import assert from "node:assert/strict";
import { createServer, type IncomingMessage, type Server } from "node:http";
import { once } from "node:events";
import test from "node:test";
import { AeroAPI, AeroAPIError, MapLayer } from "../dist/index.js";

const ONE_PIXEL_PNG =
  "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==";

interface CapturedRequest {
  method: string | undefined;
  url: string | undefined;
  apiKey: string | string[] | undefined;
  accept: string | string[] | undefined;
}

async function listen(handler: (request: IncomingMessage, body: string) => { status: number; json: unknown }): Promise<{
  server: Server;
  baseUrl: string;
  requests: CapturedRequest[];
}> {
  const requests: CapturedRequest[] = [];
  const server = createServer((request, response) => {
    requests.push({
      method: request.method,
      url: request.url,
      apiKey: request.headers["x-apikey"],
      accept: request.headers.accept,
    });
    const result = handler(request, "");
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

test("lists flights and camel-cases the payload", async () => {
  const fixture = await listen(() => ({
    status: 200,
    json: {
      num_pages: 1,
      links: { next: "/flights/UAL1?cursor=abc" },
      flights: [{ ident: "UAL1", fa_flight_id: "UAL1-1700000000-fa-1", operator_icao: "UAL" }],
    },
  }));
  try {
    const api = new AeroAPI({ apiKey: "test-key", baseUrl: fixture.baseUrl });
    const page = await api.flights.list("UAL1", { identType: "designator", maxPages: 2 });
    assert.equal(page.numPages, 1);
    assert.equal(page.links?.next, "/flights/UAL1?cursor=abc");
    assert.equal(page.flights?.[0]?.faFlightId, "UAL1-1700000000-fa-1");
    assert.equal(page.flights?.[0]?.operatorIcao, "UAL");
    assert.equal(fixture.requests[0]?.apiKey, "test-key");
    assert.equal(fixture.requests[0]?.method, "GET");
    const url = new URL(fixture.requests[0]?.url ?? "", "http://127.0.0.1");
    assert.equal(url.pathname, "/aeroapi/flights/UAL1");
    assert.equal(url.searchParams.get("ident_type"), "designator");
    assert.equal(url.searchParams.get("max_pages"), "2");
  } finally {
    await close(fixture.server);
  }
});

test("routes historical calls and decodes a map image", async () => {
  const fixture = await listen((request) => {
    if (request.url?.includes("/map")) return { status: 200, json: { map: ONE_PIXEL_PNG } };
    return { status: 200, json: { positions: [{ altitude: 100, groundspeed: 250, latitude: 1, longitude: 2, timestamp: "2020-01-01T00:00:00Z" }] } };
  });
  try {
    const api = new AeroAPI({ apiKey: "test-key", baseUrl: fixture.baseUrl });
    const faId = "UAL1-1600000000-fa-1";
    const track = await api.history.track(faId, false);
    assert.equal(track.positions?.[0]?.groundspeed, 250);
    const image = await api.flights.map(faId, {
      width: 32,
      height: 32,
      layersOn: [MapLayer.track],
      layersOff: [MapLayer.radar],
      showAirports: true,
      historical: true,
    });
    assert.equal(image.bytes[0], 0x89);
    assert.equal(image.bytes[1], 0x50);
    assert.match(image.dataUrl, /^data:image\/png;base64,/);
    const mapUrl = new URL(fixture.requests[1]?.url ?? "", "http://127.0.0.1");
    assert.equal(mapUrl.pathname, `/aeroapi/history/flights/${faId}/map`);
    assert.equal(mapUrl.searchParams.get("width"), "32");
    assert.equal(mapUrl.searchParams.get("height"), "32");
    assert.deepEqual(mapUrl.searchParams.getAll("layer_on"), [MapLayer.track]);
    assert.deepEqual(mapUrl.searchParams.getAll("layer_off"), [MapLayer.radar]);
    assert.equal(mapUrl.searchParams.get("show_airports"), "true");
  } finally {
    await close(fixture.server);
  }
});

test("covers airport, operator, aircraft, and disruption routes", async () => {
  const fixture = await listen(() => ({ status: 200, json: { blocked: false, entities: [], airports: [], operators: [] } }));
  try {
    const api = new AeroAPI({ apiKey: "test-key", baseUrl: fixture.baseUrl });
    const window = { start: new Date(Date.now() - 60_000), end: new Date(Date.now() + 60_000) };
    await api.airports.flights("KSFO", { kind: "arrivals", window, maxPages: 1 });
    await api.airports.flightsBetween("KSFO", "KLAX");
    await api.airports.nearby({ latitude: 37.6, longitude: -122.4, radius: 25 });
    await api.operators.flights("UAL", { kind: "enroute" });
    const blocked = await api.aircraft.blocked("N12345");
    await api.aircraft.type("B738");
    await api.disruptions.get("airline", "UAL", "today");
    assert.equal(blocked, false);
    const paths = fixture.requests.map((request) => new URL(request.url ?? "", "http://127.0.0.1").pathname);
    assert.deepEqual(paths, [
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

test("rejects a missing key, HTTP errors, bad map sizes, and invalid date windows", async () => {
  const api = new AeroAPI({ apiKey: "" });
  await assert.rejects(() => api.flights.list("UAL1"), (error: unknown) => {
    assert.ok(error instanceof AeroAPIError);
    assert.equal(error.code, "apiKeyNotSet");
    return true;
  });

  const fixture = await listen(() => ({ status: 401, json: { title: "Unauthorized" } }));
  try {
    const authed = new AeroAPI({ apiKey: "nope", baseUrl: fixture.baseUrl });
    await assert.rejects(() => authed.airports.get("KSFO"), (error: unknown) => {
      assert.ok(error instanceof AeroAPIError);
      assert.equal(error.status, 401);
      assert.equal(error.code, "HTTPResponseError");
      return true;
    });
  } finally {
    await close(fixture.server);
  }

  const future = "UAL1-9999999999-fa-1";
  const sized = new AeroAPI({ apiKey: "test-key", fetch: async () => { throw new Error("should not fetch"); } });
  await assert.rejects(() => sized.flights.map(future, { width: 0, height: 10 }), (error: unknown) => {
    assert.ok(error instanceof AeroAPIError);
    assert.equal(error.code, "invalidMapWidth");
    return true;
  });
  await assert.rejects(
    () => sized.airports.flights("KSFO", { window: { start: new Date("2020-01-02"), end: new Date("2020-01-01") } }),
    (error: unknown) => {
      assert.ok(error instanceof AeroAPIError);
      assert.equal(error.code, "startDateBeforeEndDate");
      return true;
    },
  );
  await assert.rejects(() => sized.flights.route("not-a-flight-id"), (error: unknown) => {
    assert.ok(error instanceof AeroAPIError);
    assert.equal(error.code, "faIdDateInvalid");
    return true;
  });
});
