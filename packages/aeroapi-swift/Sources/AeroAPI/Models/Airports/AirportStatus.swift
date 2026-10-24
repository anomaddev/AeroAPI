//
//  AirportStatus.swift
//  
//
//  Created by Justin Ackermann on 9/28/23.
//

import Foundation

public struct AirportStatusRequest: AeroAPIRequest {
    
    public func path() throws -> String {
        if let ident = ident { return "/airports/\(ident)/delays" }
        else { return "/airports/delays" }
    }
    
    public var ident: String!
    public var filters: [RequestFilters]
    
    /// A request to get the Airport Delay Status
    /// - Parameter code: The ICAO, IATA, or LID code for the airport
    internal init(code: String) {
        self.ident = code
        self.filters = []
    }
    
    internal init(
        maxPages: Int! = 5,
        cursor: String? = nil
    ) {
        self.filters = [.maxPages(5)]
        
        if let cursor = cursor
        { self.filters.append(.cursor(cursor)) }
    }
}

public struct AirportsDelayedResponse: Codable {
    var delays: [AirportStatus]
    var numPages: Int?
    var links: [String: String]?
}

public struct AirportStatus: Codable {
    
    public var airport: String
    public var category: String
    public var color: AirportStatusColor
    public var delaySecs: Int
    public var reasons: [DelayReason]
    
}

public struct DelayReason: Codable {
    public var category: String
    public var color: AirportStatusColor
    public var delaySecs: Int
    public var reason: String
}

public enum AirportStatusColor: String, Codable {
    case red, yellow, green
}

extension AeroAPI {
    
    // MARK: - AeroAPI Public
    
    /// This method will get the `AirportStatus` and any delay reasons asynchronously
    /// - Parameter code: The ICAO, IATA or LID code for the airport. ICAO is preferred.
    /// - Returns: An `AirportStatus` object containing the length of the delay and an array of `DelayReason` objects.
    public func getAirportStatus(code: String) async throws -> AirportStatus
    { return try await self.request(AirportStatusRequest(code: code)) }
    
    /// This method will get the `AirportStatus` and any delay reasons with a completion closure
    /// - Parameters:
    ///   - code: The ICAO, IATA or LID code for the airport. ICAO is preferred.
    ///   - completion: A completion with optional `Error` and `AirportStatus` objects depending on the successfulness of the API call.
    public func getAirportStatus(code: String,
                                 _ completion: @escaping (Result<AirportStatus, Error>) -> Void) {
        self.request(AirportStatusRequest(code: code))
        { completion($0) }
    }
    
    /// This method will get all airports worldwide reporting delays
    /// - Returns: A response containing all the airports currently experiencing delays worldwide.
    public func getAirportsDelayed() async throws -> AirportsDelayedResponse
    { return try await self.request(AirportStatusRequest()) }
}
