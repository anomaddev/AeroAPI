//
//  AirportRoutes.swift
//  
//
//  Created by Justin Ackermann on 10/1/23.
//

import Foundation

public struct AirportRouteRequest: AeroAPIRequest {
    
    public func path() throws -> String
    { return "/airports/\(origin)/routes/\(destination)" }
    
    public var origin: String
    public var destination: String
    public var filters: [RequestFilters]
    
    public init(origin: String,
         destination: String,
         sortBy: RouteRequestSort! = .count,
         maxFileAge: String! = "2 weeks", // TODO: Enum this hardcore
         maxPages: Int! = 1,
         cursor: String? = nil
    ) {
        self.origin = origin
        self.destination = destination
        self.filters = [
            .maxPages(maxPages)
        ]
        
        if let cursor = cursor
        { self.filters.append(.cursor(cursor)) }
    }
}

public struct AirportRouteResponse: Codable {
    
    var routes: [AirportRoute]
    var numPages: Int?
    var links: [String: String]?
    
}

public struct AirportRoute: Codable {
    
    public var aircraftTypes: [String]
    public var count: Int
    public var filedAltitudeMax: Int
    public var filedAltitudeMin: Int
    public var lastDepartureTime: Date
    public var route: String
    public var routeDistance: String
    
}

public enum RouteRequestSort: String, Codable {
    case count, last_departure_time
}

extension AeroAPI {
    
    // MARK: - AeroAPI Public

    /// Get all the posted routes between two airports asynchronously
    /// - Parameters:
    ///   - origin: The ICAO, IATA or LID code for the origin airport
    ///   - destination: The ICAO, IATA or LID code for the destination airport
    ///   - sortBy: The method you would like to sort by. Default is count.
    ///   - maxFileAge: The max file age you would like to search. Must be 2 weeks or less or 1 month or 1 year. Default is 2 weeks.
    ///   - maxPages: Max number of pages to return. Default is 3.
    /// - Returns: A response containing all the routes returned
    public func getRoutesBetween(
        origin: String,
        destination: String,
        sortBy: RouteRequestSort! = .count,
        maxFileAge: String! = "2 weeks",
        maxPages: Int! = 3
    ) async throws -> AirportRouteResponse {
        return try await self.request(
            AirportRouteRequest(
                origin: origin,
                destination: destination,
                sortBy: sortBy,
                maxFileAge: maxFileAge,
                maxPages: maxPages
            )
        )
    }
    
    /// Get all the posted routes between two airports with a result completion
    /// - Parameters:
    ///   - origin: The ICAO, IATA or LID code for the origin airport
    ///   - destination: The ICAO, IATA or LID code for the destination airport
    ///   - sortBy: The method you would like to sort by. Default is count.
    ///   - maxFileAge: The max file age you would like to search. Must be 2 weeks or less or 1 month or 1 year. Default is 2 weeks.
    ///   - maxPages: Max number of pages to return. Default is 3.
    ///   - completion: A result closure containing the result of the API call
    public func getRoutesBetween(
        origin: String,
        destination: String,
        sortBy: RouteRequestSort! = .count,
        maxFileAge: String! = "2 weeks",
        maxPages: Int! = 3,
        _ completion: @escaping (Result<AirportRouteResponse, Error>) -> Void
    ) {
        self.request(
            AirportRouteRequest(
                origin: origin,
                destination: destination,
                sortBy: sortBy,
                maxFileAge: maxFileAge,
                maxPages: maxPages
            )
        ) { completion($0) }
    }
}
