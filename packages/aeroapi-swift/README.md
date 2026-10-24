# AeroAPI Swift

iOS and macOS client for the FlightAware AeroAPI. The Swift package manifest stays at the repository root so Xcode and Swift Package Manager can add this git repository directly. Sources live in this directory.

## Install

In a `Package.swift`:

```swift
.package(url: "https://github.com/anomaddev/AeroAPI-Swift.git", branch: "main")
```

In Xcode: File → Add Package Dependencies, then use the repository URL above.

The package depends on a sibling checkout of [NomadUtilities](https://github.com/anomaddev/NomadUtilities) at `../NomadUtilities`, plus Alamofire, ZippyJSON, SwiftDate, and Defaults.

## API key

```swift
AeroAPI.manager.set(apiKey: "api-key-goes-here")
```

The sample app is in `apps/ios-demo`.

## Supported endpoints

Request and response fields for these paths are in the Redoc page at `docs/http/index.html`, published to [https://anomaddev.github.io/aeroapi-swift/http/](https://anomaddev.github.io/aeroapi-swift/http/).

### Flights

- GET /flights/{id}/map
- GET /flights/{id}/position
- GET /flights/{id}/route
- GET /flights/{id}/track
- GET /flights/{ident}
- GET /flights/{ident}/canonical

### Airports

- GET /airports
- GET /airports/{id}
- GET /airports/{id}/canonical
- GET /airports/{id}/delays
- GET /airports/{id}/flights
- GET /airports/{id}/flights/arrivals
- GET /airports/{id}/flights/counts
- GET /airports/{id}/flights/departures
- GET /airports/{id}/flights/scheduled_arrivals
- GET /airports/{id}/flights/scheduled_departures
- GET /airports/{id}/flights/to/{dest_id}
- GET /airports/{id}/nearby
- GET /airports/{id}/routes/{dest_id}
- GET /airports/{id}/weather/forecast
- GET /airports/{id}/weather/observations
- GET /airports/delays
- GET /airports/nearby

### Operators

- GET /operators
- GET /operators/{id}
- GET /operators/{id}/canonical
- GET /operators/{id}/flights
- GET /operators/{id}/flights/arrivals
- GET /operators/{id}/flights/counts
- GET /operators/{id}/flights/enroute
- GET /operators/{id}/flights/scheduled

### History

- GET /history/aircraft/{registration}/last_flight
- GET /history/flights/{id}/map
- GET /history/flights/{id}/route
- GET /history/flights/{id}/track
- GET /history/flights/{ident}

### Miscellaneous

- GET /aircraft/{ident}/blocked
- GET /aircraft/{ident}/owner
- GET /aircraft/types/{type}
- GET /disruption_counts/{entity_type}
- GET /disruption_counts/{entity_type}/{id}
