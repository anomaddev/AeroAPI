//
//  MapData.swift
//  
//
//  Created by Justin Ackermann on 10/4/23.
//

import Foundation

public struct MapDataRequest: AeroAPIRequest {
    
    public func path() throws -> String
    { return "\(historical ? "/history" : "")/flights/\(faId)/map" }
    
    public var faId: String
    public var filters: [RequestFilters]
    
    public var historical: Bool
    
    public init(
        faId: String,
        height: Int! = 480,
        width: Int! = 640,
        layersOn: [FlightAwareMapLayer]? = nil,
        layersOff: [FlightAwareMapLayer]? = nil,
        showData: Bool? = nil,
        airportsExpand: Bool? = nil,
        showAirports: Bool? = nil
//        boundingBox: [Double]? = nil
    ) throws {
        self.faId = faId
        self.filters = [
            .height(height),
            .width(width)
        ]
        
        if let layersOn = layersOn
        { self.filters.append(.layersOn(layersOn)) }
        
        if let layersOff = layersOff
        { self.filters.append(.layersOn(layersOff)) }
        
        if let showData = showData
        { self.filters.append(.showDataBlock(showData)) }
        
        if let airportsExpand = airportsExpand
        { self.filters.append(.airportsExpandView(airportsExpand)) }
        
        if let showAirports = showAirports
        { self.filters.append(.showAirports(showAirports)) }
        
        guard let flightDate = Int(faId.split(separator: "-")[1])
        else { throw AeroAPIError.faIdDateInvalid(id: faId) }
        
        let current = Date().seconds
        self.historical = current > flightDate
    }
}

public enum FlightAwareMapLayer: String, Codable {
    
    case USCities           = "US Cities"
    case EuropeBoundaries   = "european country boundaries"
    case AsiaBoundaries     = "asia country boundaries"
    case MajorAirports      = "major airports"
    case CountryBoundaries  = "country boundaries"
    case USStateBoundaries  = "US state boundaries"
    case Water              = "water"
    case USMajorRoads       = "US major roads"
    case Radar              = "radar"
    case Track              = "track"
    case Flights            = "flights"
    case Airports           = "airports"
    
}

extension AeroAPI {
    
    // MARK: - AeroAPI Public
    public func getMap(for request: MapDataRequest) async throws -> Data {
        return try await getData(request)
    }

    public func getMap(for request: MapDataRequest,
                       _ completion: @escaping (Result<Data, Error>) -> Void) {
        getData(request)
        { (result: Result<Data, Error>) in
            switch result {
            case .success(let data):
                completion(.success(data))
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
