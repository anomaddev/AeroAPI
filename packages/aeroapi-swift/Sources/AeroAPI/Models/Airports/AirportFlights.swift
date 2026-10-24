//
//  AirportFlights.swift
//  
//
//  Created by Justin Ackermann on 9/28/23.
//

import Foundation

public struct AirportFlightCounts: Codable {
    
    public var departed: Int
    public var enroute: Int
    public var scheduledArrivals: Int
    public var scheduledDepartures: Int
    
}

public struct AirportCountRequest: AeroAPIRequest {
    
    public func path() throws -> String
    { return "/airports/\(ident)/flights/counts" }
    
    public var ident: String
    public var filters: [RequestFilters]
    
    public init(code: String) {
        self.ident = code
        self.filters = []
    }
}

public struct AirportFlightsResponse: Codable {
    
    var scheduledArrivals:      [Flight]?
    var scheduledDepartures:    [Flight]?
    
    var arrivals:   [Flight]?
    var departures: [Flight]?
    
    var links: [String: String]
    var numPages: Int
    
}

public struct FlightsBetweenAirportsRequest: AeroAPIRequest {
    
    public func path() throws -> String
    { return "/airports/\(origin)/flights/to/\(destination)" }
    
    public var origin: String
    public var destination: String
    public var filters: [RequestFilters]
    
    public init(
        airports: (origin: String, destination: String),
        type: FlightType! = .Airline,
        connectionType: FlightConnectionType! = .nonstop,
        dateRange: (start: Date, end: Date)? = nil,
        maxPages: Int! = 1,
        cursor: String? = nil
    ) throws {
        origin = airports.origin
        destination = airports.destination
        filters = [
            .maxPages(maxPages),
            .airportFlightType(type),
            .connectionType(connectionType)
        ]
        
        if let range = dateRange {
            let aweek = 84600 * 7
            let future = 84600 * 2
            let current = Date().seconds
            
            guard range.0.seconds < range.1.seconds
            else { throw AeroAPIError.startDateBeforeEndDate }
            
            guard (range.0.seconds > (current - aweek)) && (range.1.seconds < current + future)
            else { throw AeroAPIError.invalidDateAirportFlightsRequest }
            
            self.filters.append(.startDate(range.0))
            self.filters.append(.endDate(range.1))
        }
        
        if let cursor = cursor
        { self.filters.append(.cursor(cursor)) }
    }
}

public struct FlightsBetweenAirportsResponse: Codable {
    var flights: [FlightSegment]
    var numPages: Int?
    var links: [String: String]?
}
        
public struct FlightSegment: Codable {
    var segments: [Flight]
}

public struct AirportFlightsRequest: AeroAPIRequest {
    
    public func path() throws -> String {
        let base = "/airports/\(ident)/flights"
        
        switch requestType {
        case .scheduledArrivals:    return base + "/scheduled_arrivals"
        case .scheduledDepartures:  return base + "/scheduled_departures"
        case .arrivals:             return base + "/arrivals"
        case .departures:           return base + "/departures"
        default: break
        }
        
        return base
    }
    
    public var ident: String
    public var requestType: AirportFlightsRequestType
    public var filters: [RequestFilters]
    
    public init(
        code: String,
        airline: String? = nil,
        type: FlightType! = .Airline,
        dateRange: (start: Date, end: Date)? = nil,
        maxPages: Int! = 1,
        cursor: String? = nil,
        requestType: AirportFlightsRequestType! = .all
    ) throws {
        self.ident = code
        self.requestType = requestType
        self.filters = [
            .airportFlightType(type),
            .maxPages(1)
        ]
        
        if let airline = airline
        { self.filters.append(.airline(airline)) }
        
        if let range = dateRange {
            let aweek = 84600 * 7
            let future = 84600 * 2
            let current = Date().seconds
            
            guard range.0.seconds < range.1.seconds
            else { throw AeroAPIError.startDateBeforeEndDate }
            
            guard (range.0.seconds > (current - aweek)) && (range.1.seconds < current + future)
            else { throw AeroAPIError.invalidDateAirportFlightsRequest }
            
            self.filters.append(.startDate(range.0))
            self.filters.append(.endDate(range.1))
        }
        
        if let cursor = cursor
        { self.filters.append(.cursor(cursor)) }
    }
}

public enum AirportFlightsRequestType: String, Codable {
    case all
    case scheduledArrivals
    case scheduledDepartures
    case arrivals
    case departures
}

public enum FlightType: String, Codable {
    case Airline
    case GeneralAviation = "General_Aviation"
}

public enum FlightConnectionType: String, Codable {
    case nonstop
    case onestop
}

extension AeroAPI {
    
    // MARK: - AeroAPI Public
    
    /// Get the specified flights using an `AirportFlightsRequest` asynchronously using this method.
    /// - Parameter request: A `AirportFlightsRequest` to specify the search terms of the API call.
    /// - Returns: An `AirportFlightsResponse` containing the flights the request asked for.
    public func getAirportsFlights(request: AirportFlightsRequest) async throws -> AirportFlightsResponse
    { return try await self.request(request) }
    
    
    /// Get the specified flights using a `AirportFlightsRequest` and handing with a completion closure
    /// - Parameters:
    ///   - request: A `AirportFlightsRequest` to specify the search terms of the API call.
    ///   - completion: Optional `Error` and `AirportFlightsResponse` objects depending on the successfulness of the API call.
    public func getAirportFlights(request: AirportFlightsRequest,
                                  _ completion: @escaping (Result<AirportFlightsResponse, Error>) -> Void)
    { self.request(request) { completion($0) }}
    
    
    /// Get the count of flights at a given airport asynchronously
    /// - Parameter code: The ICAO, IATA or LID airport code
    /// - Returns: An `AirportFlightCounts` object containing the departed, enroute and scheduled arrivals & departures.
    public func getAirportFlightCounts(code: String) async throws -> AirportFlightCounts
    { return try await self.request(AirportCountRequest(code: code)) }
    
    
    /// Get the count of flights at a give airport with a completion closure
    /// - Parameter code: The ICAO, IATA or LID airport code
    /// - Returns: A completion with optional `Error` and `AirportFlightCounts` objects depending on the successfulnes of the API call.
    public func getAirportFlightCounts(code: String,
                                       _ completion: @escaping (Result<AirportFlightCounts, Error>) -> Void) {
        self.request(AirportCountRequest(code: code))
        { completion($0) }
    }
    
    
    /// Get the flights between two different airports asynchronously
    /// - Parameter request: The request parameters for the type of search of flights between airports.
    /// - Returns: A response with the flights and segments
    public func getFlightsBetweenAirports(request: FlightsBetweenAirportsRequest) async throws -> FlightsBetweenAirportsResponse
    { return try await self.request(request) }
    
    
    /// Get the flights between two different airports calling a result closure upon completion
    /// - Parameters:
    ///   - request: The request parameters for the type of search of flights between airports.
    ///   - completion: Contains a result containing the response of the request.
    public func getFlightsBetweenAirports(request: FlightsBetweenAirportsRequest,
                                          _ completion: @escaping (Result<FlightsBetweenAirportsResponse, Error>) -> Void) {
        self.request(request) { completion($0) }
    }
}
