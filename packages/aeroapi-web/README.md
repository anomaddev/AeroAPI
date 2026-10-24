# aeroapi-web

TypeScript port of the iOS `AeroAPI` class. It runs in browsers and Node.js 18+ and calls the [FlightAware AeroAPI](https://www.flightaware.com/aeroapi/portal/documentation) with the same async method names as the Swift package.

UIKit, MapKit, and the offline timezone map stay on iOS. `getMap` returns PNG bytes and a data URL. Timestamps in responses stay ISO strings.

## Install

```bash
npm install
npm run build -w aeroapi-web
```

## Use

```ts
import { AeroAPI, FlightDataRequest } from "aeroapi-web";

AeroAPI.manager.setApiKey(process.env.AEROAPI_KEY ?? "");

const flight = await AeroAPI.manager.getFlightData("UAL1-1700000000-fa-1");
const page = await AeroAPI.manager.getFlightData(
  FlightDataRequest.ident({ ident: "UAL1", type: "designator" }),
);
```

`loadCache()` reads the airport, airline, and aircraft JSON shipped with the Swift package when you run it from this monorepo on Node.js. Pass parsed arrays instead when those files are not on disk:

```ts
await AeroAPI.manager.loadCache({ airports, airlines, aircraft });
const matches = Airport.search("SFO");
```

`getAirportInfo`, `getAirlineInfo`, and `getAircraftInfo` merge the live response onto that cache, matching the iOS client.

## Scripts

```bash
npm test -w aeroapi-web
npm run build -w aeroapi-web
```
