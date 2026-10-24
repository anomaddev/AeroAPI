# AeroAPI

Monorepo for native FlightAware AeroAPI libraries.

| Package | Path | Runtime |
| --- | --- | --- |
| Swift package `AeroAPI` | `packages/aeroapi-swift` | iOS 15 and macOS 11 |
| npm package `aeroapi-web` | `packages/aeroapi-web` | Browsers and Node.js 18+ |

`Package.swift` stays at the repository root so Swift Package Manager and Xcode can add this repository as the iOS library. The sample iOS app is in `apps/ios-demo`.

## Swift

```swift
dependencies: [
    .package(url: "https://github.com/anomaddev/AeroAPI-Swift.git", branch: "main")
]
```

```swift
AeroAPI.manager.set(apiKey: "api-key-goes-here")
```

The Swift package expects [NomadUtilities](https://github.com/anomaddev/NomadUtilities) checked out next to this repository (`../NomadUtilities`). See `packages/aeroapi-swift/README.md` for the endpoint list.

## Web

```bash
npm install
npm test
npm run build
```

```ts
import { AeroAPI } from "aeroapi-web";

const api = new AeroAPI({ apiKey: process.env.AEROAPI_KEY ?? "" });
const page = await api.flights.list("UAL1", { identType: "designator" });
```

The web client calls `https://aeroapi.flightaware.com/aeroapi` with the `x-apikey` header and exposes the same flight, airport, operator, history, aircraft, and disruption endpoints as the Swift library. Details are in `packages/aeroapi-web/README.md`.
