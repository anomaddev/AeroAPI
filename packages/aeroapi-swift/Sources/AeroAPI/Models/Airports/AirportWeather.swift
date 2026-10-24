//
//  AirportWeather.swift
//  
//
//  Created by Justin Ackermann on 10/1/23.
//

import Foundation

public struct AirportWeatherObservationRequest: AeroAPIRequest {
    
    public func path() throws -> String
    { return "/airports/\(code)/weather/observations" }
    
    public var code: String
    public var filters: [RequestFilters]
    
    public init(
        code: String,
        tempUnits: TemperatureUnits! = .F,
        timestamp: Date! = Date(),
        returnNearby: Bool! = true,
        maxPages: Int! = 3
    ) {
        self.code = code
        self.filters = [
            .temperatureUnits(tempUnits),
            .timestamp(timestamp),
            .returnNearbyWeather(returnNearby),
            .maxPages(maxPages)
        ]
    }
}

public struct AirportWeatherObservationsResponse: Codable {
    
    public var observations: [WeatherObservation]
    public var numPages: Int?
    public var links: [String: String]?
    
}

public struct WeatherObservation: Codable {
    
    public var airportCode: String
    public var cloudFriendly: String?
    public var clouds: [ObservedClouds]
    public var conditions: String?
    public var pressure: Double?
    public var pressureUnits: PressureUnits?
    public var rawData: String
    public var tempAir: Int?
    public var tempDewpoint: Int?
    public var tempPerceived: Int?
    public var relativeHumidity: Int?
    public var time: Date
    public var visibility: Double?
    public var visibilityUnits: VisibilityUnits?
    public var windDirection: Int
    public var windFriendly: String
    public var windSpeed: Int
    public var windSpeedGust: Int
    public var windUnits: WindUnits
    
}

public struct ObservedClouds: Codable {
    
    public var altitude: Int?
    public var symbol: String
    public var type: String
    
}

public enum PressureUnits: String, Codable {
    case mb
    case hg = "in Hg"
}

public enum VisibilityUnits: String, Codable {
    case meters
    case SM
}

public enum WindUnits: String, Codable {
    case MPS
    case KT
}

public struct AirportWeatherForecastRequest: AeroAPIRequest {
    
    public func path() throws -> String
    { return "/airports/\(code)/weather/forecast" }
    
    public var code: String
    public var filters: [RequestFilters]
    
    public init(
        code: String,
        timestamp: Date! = Date(),
        returnNearby: Bool! = true
    ) {
        self.code = code
        self.filters = [
            .timestamp(timestamp),
            .returnNearbyWeather(returnNearby)
        ]
    }
}

public struct AirportWeatherForecastResponse: Codable {
    
    public var airportCode: String
    public var rawForecast: [String]
    public var time: Date
    public var decodedForecast: AirportWeatherForecast
    
}

public struct AirportWeatherForecast: Codable {
    
    public var start: Date
    public var end: Date
    public var lines: [ForecastLine]
    
}

public struct ForecastLine: Codable {
    
    public var type: String
    public var start: Date
    public var end: String?
    
    public var turbulenceLayers: String?
    public var icingLayers: String?
    public var barometricPressure: Double?
    public var significantWeather: String?
    
    public var winds: ForecastWinds?
    public var windshear: ForecastWindshear?
    public var visibility: ForecastVisibility?
    public var clouds: [ForecastClouds]?
    
}

public struct ForecastWinds: Codable {
    public var symbol: String
    public var direction: String
    public var speed: Int
    public var units: String?
    public var peakGusts: Int?
}

public struct ForecastWindshear: Codable {
    public var symbol: String
    public var direction: String
    public var speed: String
    public var units: String?
    public var height: String
}

public struct ForecastVisibility: Codable {
    public var symbol: String
    public var visibility: String
    public var units: String?
}

public struct ForecastClouds: Codable {
    public var symbol: String
    public var coverage: ForecastCoverage?
    public var altitude: String?
    public var special: String?
}

public enum ForecastCoverage: String, Codable {
    case skyclear = "sky_clear"
    case few
    case scattered
    case broken
    case overcast
}

public enum TemperatureUnits: String, Codable {
    case C, F, Celsius, Fahrenheit
}

extension AeroAPI {
    
    // MARK: - AeroAPI Public
    
    /// Get the weather forecast for the given airport asynchronously
    /// - Parameters:
    ///   - code: The ICAO, IATA or LID code for the airport.
    ///   - timestamp: The time you would like to receive the forecast for.
    ///   - returnNearby: If no reports are available, return one from an airport within 30 miles.
    /// - Returns: A response with the weather forecast information.
    public func getAirportForecast(
        code: String,
        timestamp: Date! = Date(),
        returnNearby: Bool! = true
    ) async throws -> AirportWeatherForecastResponse {
        return try await self.request(
            AirportWeatherForecastRequest(
                code: code,
                timestamp: timestamp,
                returnNearby: returnNearby
            )
        )
    }
    
    /// Get the weather forecast for the given airport in a result closure
    /// - Parameters:
    ///   - code: The ICAO, IATA or LID code for the airport.
    ///   - timestamp: The time you would like to receive the forecast for.
    ///   - returnNearby: If no reports are available, return one from an airport within 30 miles.
    ///   - completion: A response with the weather forecast information.
    public func getAirportForecast(
        code: String,
        timestamp: Date! = Date(),
        returnNearby: Bool! = true,
        _ completion: @escaping (Result<AirportWeatherForecastResponse, Error>) -> Void
    ) {
        self.request(
            AirportWeatherForecastRequest(
                code: code,
                timestamp: timestamp,
                returnNearby: returnNearby
            )
        ) { completion($0) }
    }
    
    /// Get the weather observations for the given airport asynchronously
    /// - Parameters:
    ///   - code: The ICAO, IATA or LID code for the airport.
    ///   - units: The temperature units you would like the data returned in.
    ///   - timestamp: The time you would like to receive the forecast for.
    ///   - returnNearby: If no reports are available, return one from an airport within 30 miles.
    /// - Returns: A response with the weather observation information.
    public func getAirportObservations(
        code: String,
        units: TemperatureUnits! = .F,
        timestamp: Date! = Date(),
        returnNearby: Bool! = true
    ) async throws -> AirportWeatherObservationsResponse {
        return try await self.request(
            AirportWeatherObservationRequest(
                code: code,
                tempUnits: units,
                timestamp: timestamp,
                returnNearby: returnNearby
            )
        )
    }
    
    /// Get the weather observations for the given airport in a result closure
    /// - Parameters:
    ///   - code: The ICAO, IATA or LID code for the airport.
    ///   - units: The temperature units you would like the data returned in.
    ///   - timestamp: The time you would like to receive the forecast for.
    ///   - returnNearby: If no reports are available, return one from an airport within 30 miles.
    ///   - completion: A response with the weather observation information.
    public func getAirportObservations(
        code: String,
        units: TemperatureUnits! = .F,
        timestamp: Date! = Date(),
        returnNearby: Bool! = true,
        _ completion: @escaping (Result<AirportWeatherObservationsResponse, Error>) -> Void
    ) {
        self.request(
            AirportWeatherObservationRequest(
                code: code,
                tempUnits: units,
                timestamp: timestamp,
                returnNearby: returnNearby
            )
        ) { completion($0) }
    }
}
