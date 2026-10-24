# Changelog

All notable changes to this project are documented here.

## 0.5.0 — Unreleased

First versioned release of the AeroAPI monorepo.

### Swift package `AeroAPI` (iOS 15 / macOS 11)
- FlightAware AeroAPI client with async methods for flights (info, canonical ident, position, route, track, map) and airports, plus bundled airport, airline, and aircraft databases and asset catalogs.
- Moved into `packages/aeroapi-swift`, with `Package.swift` kept at the repository root; sample iOS app in `apps/ios-demo`.
- `NomadUtilities` is now a versioned remote dependency (`from: "0.1.0"`) instead of a `../NomadUtilities` sibling checkout; `Defaults` requirement raised to 9.x to match it.

### npm package `aeroapi` (browsers and Node.js 18+)
- New TypeScript client (formerly the `aeroapi-web` workspace) that mirrors the Swift method names (`getFlightData`, `getAirportInfo`, `getMap`, …) and calls `https://aeroapi.flightaware.com/aeroapi` with the `x-apikey` header.
- Published as `aeroapi` with public access; the root workspace is renamed `aeroapi-monorepo`.

### Docs
- OpenAPI description of the HTTP contract (`docs/http/openapi.yaml`) with a Redoc page published to GitHub Pages.
- MIT license.
