//
//  FlightTrack.swift
//  
//
//  Created by Justin Ackermann on 11/23/22.
//

import Foundation

// Utilities
import CoreLocation

public struct FlightTrackRequest: AeroAPIRequest {
    
    public func path() throws -> String
    { return "\(historical ? "/history" : "")/flights/\(faId)/track" }
    
    public var faId: String
    public var historical: Bool = false
    public var filters: [RequestFilters]
    
    public init(_ faId: String,
                showEstimated: Bool! = true) throws {
        self.faId = faId
        self.filters = [
            .includeEstimated(showEstimated)
        ]
        
        guard let flightDate = Int(faId.split(separator: "-")[1])
        else { throw AeroAPIError.faIdDateInvalid(id: faId) }
        
        let current = Date().seconds
        self.historical = current > flightDate
    }
}

public struct FlightTrack: Codable {
    /// This is only null when faId was used to get track
    public var faFlightId: String?
    
    public var altitude: Int
    public var altitudeChange: AltChange
    public var groundspeed: Int
    public var heading: Int?
    public var latitude: Double
    public var longitude: Double
    public var timestamp: Date
    public var updateType: UpdateType?
    
    public var coord: CLLocationCoordinate2D
    { .init(latitude: latitude, longitude: longitude) }
}

/// If a current position is currently changing altitude, this field will indicate the direction of the change.
public enum AltChange: String, Codable {
    
    /// No Change in Alt
    case Null = "-"
    
    /// Climbing
    case C
    
    /// Descending
    case D
}

public enum UpdateType: String, Codable {
    case P, O, Z, A, M, D, X, S
}

extension AeroAPI {
    
    // MARK: - Flight Track Requests
    
    /// Get the flight track of a given FAID asynchronously
    /// - Parameters:
    ///   - faId: The unique FlightAware flight ID
    ///   - includeEstimatedPositions: A `Boolean` to indicate if the returned track should include estimated tracks
    /// - Returns: An array of `FlightTrack` objects
    public func getTrack(faId: String,
                         includeEstimatedPositions: Bool! = false) async throws -> [FlightTrack] {
        let data: [String: [FlightTrack]] = try await self.request(
            FlightTrackRequest(faId, showEstimated: includeEstimatedPositions)
        )
        
        guard let positions = data["positions"]
        else { throw AeroAPIError.failedDecodingFlightTrackResponse }
        
        guard !(positions.isEmpty)
        else { throw AeroAPIError.flightTrackEmpty }
        
        return positions
    }
    
    
    /// Get the flight track of a given FAID with a completion closure
    /// - Parameters:
    ///   - faId: The unique FlightAware flight ID
    ///   - includeEstimatedPositions: A `Boolean` to indicate if the returned track should include estimated tracks
    ///   - completion: A tuple containing an optional `Error` or an array of `FlightTrack` objects, based on the successfulness of the request
    public func getTrack(faId: String,
                         includeEstimatedPositions: Bool! = false,
                         _ completion: @escaping (Result<[FlightTrack], Error>) -> Void) {
        do {
            let request = try FlightTrackRequest(faId, showEstimated: includeEstimatedPositions)
            self.request(request)
            { (result: Result<[String: [FlightTrack]], Error>) in
                switch result {
                case .success(let parsed):
                    guard let positions = parsed["positions"]
                    else { return } // TODO: Throw
                    completion(.success(positions))
                    
                case .failure(let failure):
                    completion(.failure(failure))
                }
            }
        } catch { completion(.failure(error)) }
    }
}

