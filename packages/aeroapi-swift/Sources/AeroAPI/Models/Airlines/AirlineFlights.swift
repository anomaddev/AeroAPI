//
//  AirlineFlights.swift
//  
//
//  Created by Justin Ackermann on 10/1/23.
//

import Foundation

public struct AirlineFlightsResponse: Codable {
    
    var arrivals:   [Flight]?
    var scheduled:  [Flight]?
    var enroute:    [Flight]?
    
    var links: [String: String]?
    var numPages: Int
    
}

public struct AirlineFlightsRequest: AeroAPIRequest {
    
    public func path() throws -> String {
        let base = "/operators/\(ident)/flights"
        
        switch requestType {
        case .enroute:              return base + "/enroute"
        case .arrivals:             return base + "/arrivals"
        case .scheduled:            return base + "/scheduled"
        default: break
        }
        
        return base
    }
    
    public var ident: String
    public var requestType: AirlineFlightsRequestType
    public var filters: [RequestFilters]
    
    public init(
        airline: String,
        dateRange: (start: Date, end: Date)? = nil,
        maxPages: Int! = 1,
        cursor: String? = nil,
        requestType: AirlineFlightsRequestType! = .all
    ) throws {
        self.ident = airline
        self.requestType = requestType
        self.filters = [
            .maxPages(1)
        ]
        
        if let range = dateRange {
            let aweek = 84600 * 7
            let future = 84600 * 2
            let current = Date().seconds
            
            guard range.0.seconds < range.1.seconds
            else { throw AeroAPIError.startDateBeforeEndDate }
            
            guard (range.0.seconds > (current - aweek)) && (range.1.seconds < current + future)
            else { throw AeroAPIError.invalidDateAirportFlightsRequest } // TODO: Refactor to error over all requests
            
            self.filters.append(.startDate(range.0))
            self.filters.append(.endDate(range.1))
        }
        
        if let cursor = cursor
        { self.filters.append(.cursor(cursor)) }
    }
}

public enum AirlineFlightsRequestType: String, Codable {
    case all
    case enroute
    case arrivals
    case scheduled
}

extension AeroAPI {
    
    // MARK: - AeroAPI Public
    
    /// Get the specified flights using an `AirlineFlightsRequest` asynchronously using this method.
    /// - Parameter request: A `AirlineFlightsRequest` to specify the search terms of the API call.
    /// - Returns: An `AirportFlightsResponse` containing the flights the request asked for.
    public func getAirlineFlights(request: AirlineFlightsRequest) async throws -> AirlineFlightsResponse
    { return try await self.request(request) }
    
    
    /// Get the specified flights using a `AirlineFlightsRequest` and handing with a completion closure
    /// - Parameters:
    ///   - request: A `AirlineFlightsRequest` to specify the search terms of the API call.
    ///   - completion: Optional `Error` and `AirportFlightsResponse` objects depending on the successfulness of the API call.
    public func getAirlineFlights(request: AirlineFlightsRequest,
                                  _ completion: @escaping (Result<AirlineFlightsResponse, Error>) -> Void)
    { self.request(request) { completion($0) }}
    
    
    /// Get the count of flights at a given airport asynchronously
    /// - Parameter code: The ICAO, IATA or LID airport code
    /// - Returns: An `AirportFlightCounts` object containing the departed, enroute and scheduled arrivals & departures.
    public func getAirlineFlightCounts(icao: String) async throws -> AirlineFlightsResponse
    { return try await self.request(AirlineFlightsRequest(airline: icao)) }
    
    
    /// Get the count of flights at a give airport with a completion closure
    /// - Parameter code: The ICAO, IATA or LID airport code
    /// - Returns: A completion with optional `Error` and `AirportFlightCounts` objects depending on the successfulnes of the API call.
    public func getAirlineFlightCounts(icao: String,
                                       _ completion: @escaping (Result<AirlineFlightsResponse, Error>) -> Void) {
        do {
            let request = try AirlineFlightsRequest(airline: icao)
            self.request(request) { completion($0) }
        } catch { completion(.failure(error)) }
    }
}
