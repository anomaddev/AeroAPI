# aeroapi-web

TypeScript client for the [FlightAware AeroAPI](https://www.flightaware.com/aeroapi/portal/documentation). It runs in browsers and Node.js 18+ and covers the same endpoints as the iOS Swift package in this repository.

## Install

From this monorepo:

```bash
npm install
npm run build -w aeroapi-web
```

The package entry is `aeroapi-web`.

## Use

```ts
import { AeroAPI } from "aeroapi-web";

const api = new AeroAPI({ apiKey: process.env.AEROAPI_KEY ?? "" });

const flights = await api.flights.list("UAL1", { identType: "designator" });
const airport = await api.airports.get("KSFO");
const map = await api.flights.map(flights.flights?.[0]?.faFlightId ?? "");
```

`map.bytes` is the decoded PNG. `map.dataUrl` can be assigned to an image element.

Timestamps in responses stay ISO strings. Request dates are sent as `yyyy-MM-dd'T'HH:mm:ss'Z'`. Response objects use camelCase keys.

## Scripts

```bash
npm test -w aeroapi-web
npm run build -w aeroapi-web
```
