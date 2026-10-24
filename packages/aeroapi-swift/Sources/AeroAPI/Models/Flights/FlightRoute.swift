//
//  FlightRoute.swift
//  
//
//  Created by Justin Ackermann on 9/28/23.
//

import Foundation

public struct FlightRouteRequest: AeroAPIRequest {
    
    public func path() throws -> String
    { "\(historical ? "/history" : "")/flights/\(faId)/route" }
    
    public let faId: String
    public var historical: Bool! = false
    public var filters: [RequestFilters]
    
    /// Create a `FlightRouteRequest` with a given FlightAware ID (faId).
    /// - Parameter faId: A string representation of the unique FlightAware flight ID for a given flight
    public init(faId: String) throws {
        self.faId = faId
        self.filters = []
        
        guard let flightDate = Int(faId.split(separator: "-")[1])
        else { throw AeroAPIError.faIdDateInvalid(id: faId) }
        
        let current = Date().seconds
        self.historical = current > flightDate
    }
}

public struct FlightRoute: Codable {
    
    public var routeDistance: String?
    public var fixes: [FlightFix]
    
}

public struct FlightFix: Codable {
    
    public var name: String
    public var latitude: Double?
    public var longitude: Double?
    public var distanceFromOrigin: Double?
    public var distanceThisLeg: Double?
    public var distanceToDestination: Double?
    public var outboundCourse: Double?
    public var type: String
    
}

extension AeroAPI {
    
    // MARK: - Flight Route Requests
    
    /// Get the flight route asynchronously using a FAID
    /// - Parameter faId: The unique FlightAware flight ID
    /// - Returns: A `FlightRoute` object containing the flight's route information
    public func getRoute(faId: String) async throws -> FlightRoute
    { return try await self.request(FlightRouteRequest(faId: faId)) }
    
    
    /// Get the flight route using a FAID with a completion closure
    /// - Parameters:
    ///   - faId: The unique FlightAware flight ID
    ///   - completion: A completion containing optional `Error` and `FlightRoute` objects depending on the successfulness of the API call
    public func getRoute(faId: String,
                         _ completion: @escaping (Result<FlightRoute, Error>) -> Void) {
        do {
            let request = try FlightRouteRequest(faId: faId)
            self.request(request) { completion($0) }
        } catch { completion(.failure(error)) }
    }
}
