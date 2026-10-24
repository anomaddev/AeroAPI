//
//  FlightPosition.swift
//  
//
//  Created by Justin Ackermann on 10/3/23.
//

import Foundation
import CoreLocation

public struct FlightPositionRequest: AeroAPIRequest {
    
    public func path() throws -> String
    { return "/flights/\(faId)/position" }
    
    public var faId: String
    public var filters: [RequestFilters]
    
    public init(faId: String) {
        self.faId = faId
        self.filters = []
    }
}

public struct FlightSearchResponse: Codable {
    
    public var ident: String
    public var identIcao: String?
    public var identIata: String?
    public var faFlightId: String
    
    public var origin: FlightPositionAirport
    public var destination: FlightPositionAirport
    
    public var waypoints: [Double]
    
    public var firstPositionTime: Date?
    public var lastPosition: LastPosition
    
    public var boundingBox: [Double]
    public var identPrefix: String?
    public var aircraftType: String?
    public var foresightPredictionsAvailable: Bool
    
    public var actualOff: Date?
    public var actualOn: Date?
    public var predictedOut: Date?
    public var predictedOff: Date?
    public var predictedOn: Date?
    public var predictedIn: Date?
    
    public var predictedOutSource: PredictionType?
    public var predictedOffSource: PredictionType?
    public var predictedOnSource: PredictionType?
    public var predictedInSource: PredictionType?
    
}

public struct FlightPositionAirport: Codable {
    public var code: String
    public var codeIcao: String?
    public var codeIata: String?
    public var codeLid: String?
    public var timezone: String?
    public var name: String?
    public var city: String?
    public var airportInfoUrl: String?
}

public struct LastPosition: Codable {
    public var faFlightId: String?
    public var altitude: Int
    public var altitudeChange: AltChange
    public var groundspeed: Int
    public var heading: Int?
    public var latitude: Double
    public var longitude: Double
    public var timestamp: Date
    public var updateType: UpdateType?
    
    public var coordinate: CLLocationCoordinate2D
    { return .init(latitude: latitude, longitude: longitude) }
}

public enum PredictionType: String, Codable {
    case Foresight
    case HistoricalAvg = "Historical Average"
}

extension AeroAPI {
    
    // MARK: - Flight Position Requests
    
    /// Gets a flights current position with additional details
    /// - Parameter faId: The FightAware ID for the flight you would like to search for
    /// - Returns: A `FlightSearchResponse` containing all the relavent info
    public func getPosition(faId: String) async throws -> FlightSearchResponse
    { return try await self.request(FlightPositionRequest(faId: faId)) }
    
    /// Gets a flights current position with additional details
    /// - Parameters:
    ///   - faId: The FightAware ID for the flight you would like to search for
    ///   - completion: The result containing A `FlightSearchResponse` containing all the relavent info or the error if one occurs
    public func getPosition(faId: String,
                            _ completion: @escaping (Result<FlightSearchResponse, Error>) -> Void)
    { self.request(FlightPositionRequest(faId: faId)) { completion($0) }}
}
