//
//  Aircraft.swift
//  Atlas Inflight
//
//  Created by Justin Ackermann on 5/30/21.
//

// Core iOS
import Foundation

#if os(iOS)
import UIKit
#endif

public struct AircraftTypeInfoRequest: AeroAPIRequest {
    public func path() throws -> String
    { return "/aircraft/types/\(icao)" }
    
    public var icao: String
    public var filters: [RequestFilters]
    
    public init(icao: String) {
        self.icao = icao
        self.filters = []
    }
}

public struct BlockedCheck: AeroAPIRequest {
    public func path() throws -> String
    { return "/aircraft/\(ident)/blocked" }
    
    public var ident: String
    public var filters: [RequestFilters]
    
    public init(ident: String) {
        self.ident = ident
        self.filters = []
    }
}

public struct BlockedReponse: Codable {
    public var blocked: Bool
}

public struct LastFlightRequest: AeroAPIRequest {
    public func path() throws -> String
    { return "/history/aircraft/\(registration)/last_flight" }
    
    public var registration: String
    public var filters: [RequestFilters]
    
    public init(tailno: String) {
        self.registration = tailno
        self.filters = []
    }
}

public struct LastFlightResponse: Codable {
    public var flights: [Flight]
}

public struct Aircraft: Codable {
    
    public var name: String?
    public var iata: String?
    public var ident: String?
    
    public var manufacturer: String?
    public var type: String?
    public var description: String?
    public var engineCount: Int?
    public var engineType: String?
    
    public var cruise: Double?
    public var range: Int?
    
    #if os(iOS)
    public var png: UIImage?
    { UIImage(named: ident ?? "blank", in: .module, compatibleWith: nil) }
    #endif
    
}

extension AeroAPI {
    
    // MARK: - AeroAPI Public
    
    
    /// Gets the last flight of a given tail number
    /// - Parameter tailno: The tail number of the aircraft you would like to search
    public func lastFlightFor(tailno: String) async throws -> Flight? {
        let last: LastFlightResponse = try await self.request(LastFlightRequest(tailno: tailno))
        return last.flights.first
    }
    
    /// Gets the last flight of a given tail number
    /// - Parameters:
    ///   - tailno: The tail number of the aircraft you would like to search
    ///   - completion: A result closure containing the flight or the error that occured
    public func lastFlightFor(tailno: String,
                              _ completion: @escaping (Result<Flight?, Error>) -> Void) {
        self.request(LastFlightRequest(tailno: tailno))
        { (result: Result<LastFlightResponse, Error>) in
            switch result {
            case .success(let returned):
                completion(.success(returned.flights.first))
            
            case .failure(let failure):
                completion(.failure(failure))
            }
        }
    }
    
    /// Async request to check if an aircraft registration is block
    /// - Parameter registration: Aircraft registration
    /// - Returns: A `Bool` indicating if the registration is block or not
    public func checkBlocked(for registration: String) async throws -> Bool {
        let response: BlockedReponse = try await self.request(BlockedCheck(ident: registration))
        return response.blocked
    }
    
    /// Async request to check if an aircraft registration is block
    /// - Parameters:
    ///   - registration: Aircraft registration
    ///   - completion: A result of `Bool` indicating if the registration is block or not
    public func checkBlocked(for registration: String,
                             _ completion: @escaping (Result<Bool, Error>) -> Void) {
        self.request(BlockedCheck(ident: registration))
        { (result: Result<BlockedReponse, Error>) in
            switch result {
            case .success(let response): completion(.success(response.blocked))
            case .failure(let error): completion(.failure(error))
            }
        }
    }
    
    /// Async request function for `AircraftTypeInfoRequest`
    /// - Parameter request: `AircraftTypeInfoRequest`
    /// - Returns: `Aircraft`
    public func getAircraftInfo(icao: String) async throws -> Aircraft {
        let request = AircraftTypeInfoRequest(icao: icao)
        let aicraft: Aircraft = try await self.request(request)
        return mergeWithCached(aircraft: aicraft, icao: icao)
    }
    
    /// Completion based request function for `AircraftTypeInfoRequest`
    /// - Parameter request: `AircraftTypeInfoRequest`
    /// - Returns: Completion of optionals `Error` and `Aircraft`
    public func getAircraftInfo(icao: String,_ completion: @escaping (Result<Aircraft, Error>) -> Void) {
        let request = AircraftTypeInfoRequest(icao: icao)
        self.request(request)
        { (result: Result<Aircraft, Error>) in
            switch result {
            case .success(let aircraft):
                completion(.success(self.mergeWithCached(aircraft: aircraft, icao: icao)))
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Merges the AeroAPI info with the cached Aircraft info
    /// - Parameter aircraft: `Aircraft` object that was returned by the AeroAPI
    /// - Parameter icao: `String` that's the ICAO for the aircraft information that was requested
    internal func mergeWithCached(aircraft: Aircraft, icao: String) -> Aircraft {
        if var cached = (AeroAPI.allAircraft.first(where: { $0.ident == icao })) {
            cached.manufacturer = aircraft.manufacturer
            cached.type         = aircraft.type
            cached.description  = aircraft.description
            cached.engineCount  = aircraft.engineCount
            cached.engineType   = aircraft.engineType
            
            return cached
        }
        
        return aircraft
    }
}

extension String {
    public var aircraft: Aircraft?
    { AeroAPI.allAircraft.first(where: { $0.ident == self || $0.iata == self }) }
}
    
//    var distance: Distance? {
//        if let range = range { return Distance(is: range, in: .kilometers) }
//        else { return nil }
//    }
//
//    var speed: Speed? {
//        if let mach = mach { return Speed(is: mach, in: .mach) }
//        else { return nil }
//    }
    
//    convenience init(_ row: [String]) {
//        self.init()
//
//        self.name   = row[0]
//        self.iata   = row[1]
//        self.icao   = row[2]
//        self.mach   = NumberFormatter().number(from: row[3])?.double
//        self.range  = NumberFormatter().number(from: row[4])?.int
//        self.icon   = IconAsset.plane.raw
//    }

//    var aircraftIcao: Aircraft? {
//        do {
//            let aircraft = Models.allAircraft
//            guard !aircraft.isEmpty else { throw NSError() } // THROW:
//            return aircraft.filter { $0.icao == self }.first
//        } catch { return nil }
//    }
//
//    var aircraftIata: Aircraft? {
//        do {
//            let aircraft = Models.allAircraft
//            guard !aircraft.isEmpty else { throw NSError() } // THROW:
//            return aircraft.filter { $0.iata == self }.first
//        } catch { return nil }
//    }
//
//    var aircraft: Aircraft? {
//        do {
//            let aircraft = Models.allAircraft
//            guard !aircraft.isEmpty else { throw NSError() } // THROW:
//
//            let icao = aircraft.first { $0.icao == self }
//            let iata = aircraft.first { $0.iata == self }
//
//            guard let plane = icao ?? iata
//            else { throw AtlasError.fall }
//
//            return plane
//        } catch { return nil }
//    }
//
//    func isAircraft() throws -> Aircraft {
//        let realm = try Realm()
//        let aircraft = realm.objects(Aircraft.self)
//        let icao = aircraft.first { $0.icao == self }
//        let iata = aircraft.first { $0.iata == self }
//
//        guard let plane = icao ?? iata
//        else { throw NSError() }
//        return plane
//    }
