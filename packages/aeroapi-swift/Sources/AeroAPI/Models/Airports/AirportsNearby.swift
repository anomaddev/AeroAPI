//
//  File.swift
//  
//
//  Created by Justin Ackermann on 10/1/23.
//

import Foundation

public struct AirportsNearbyRequest: AeroAPIRequest {
    
    public func path() throws -> String {
        if let code = code { return "/airports/\(code)/nearby" }
        else { return "/airports/nearby" }
    }
    
    /// ICAO, IATA or LID airport code
    public var code: String!
    
    /// filters on the request
    public var filters: [RequestFilters]
    
    public init(
        code: String,
        radius: Int! = 250,
        onlyIAP: Bool! = false,
        maxPages: Int! = 1,
        cursor: String? = nil
    ) {
        self.code = code
        self.filters = [
            .radius(radius),
            .onlyInstuments(onlyIAP),
            .maxPages(1)
        ]
        
        if let cursor = cursor
        { self.filters.append(.cursor(cursor)) }
    }
    
    public init(
        latitude: Double,
        longitude: Double,
        radius: Int! = 250,
        onlyIAP: Bool! = false,
        maxPages: Int! = 1,
        cursor: String? = nil
    ) {
        self.filters = [
            .latitude(latitude),
            .longitude(longitude),
            .radius(radius),
            .onlyInstuments(onlyIAP),
            .maxPages(1)
        ]
        
        if let cursor = cursor
        { self.filters.append(.cursor(cursor)) }
    }
}

public struct AirportsNearbyResponse: Codable {
    
    public var airports: [AirportNearby]
    public var numPages: Int?
    public var links: [String: String]?
    
}

public class AirportNearby: Airport {
    
    public var distance: Int!
    public var heading: Int!
    public var direction: MapDirection!
    
}

/// Specifies the direction to search on the map
public enum MapDirection: String, Codable {
    /// North
    case N
    
    /// East
    case E
    
    /// South
    case S
    
    /// West
    case W
    
    /// North East
    case NE
    
    /// South East
    case SE
    
    /// South West
    case SW
    
    /// North West
    case NW
}
