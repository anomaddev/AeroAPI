//
//  Airline.swift
//  AtlasInFlight
//
//  Created by Justin Ackermann on 4/28/22.
//

// Core iOS
import Foundation

#if os(iOS)
import UIKit
#endif

public struct AirlinesRequest: AeroAPIRequest {
    public func path() throws -> String
    { return "/operators" }
    
    public var filters: [RequestFilters]
    
    public init(maxPages: Int! = 1)
    { self.filters = [.maxPages(maxPages)] }
}

public struct AirlinesResponse: Codable {
    public var operators: [Operators]
    public var numPages: Int?
    public var links: [String: String]?
    
    public struct Operators: Codable {
        var code: String
        var operatorInfoUrl: String
    }
}

public struct CanonicalAirlineRequest: AeroAPIRequest {
    public func path() throws -> String
    { return "/operators/\(code)/canonical" }
    
    public var code: String
    public var filters: [RequestFilters]
    
    init(code: String, countryCode: String? = nil) {
        self.code = code
        self.filters = []
        
        if let countryCode = countryCode
        { self.filters.append(.countryCode(countryCode)) }
    }
}

public struct CanonicalAirlineResponse: Codable {
    var operators: [AirlineID]
    
    public struct AirlineID: Codable {
        var id: String
        var idType: AirlineIDType
    }
}

public enum AirlineIDType: String, Codable {
    case icao
    case iata
}

public struct AirlineFlightCountResponse: Codable {
    
    public var airborne: Int
    public var flightsLast24Hours: Int
    
}

public struct AirlineFlightCountRequest: AeroAPIRequest {
    
    public func path() throws -> String
    { return "/operators/\((icao ?? iata)!)/flights/counts" }
    
    public var icao: String?
    public var iata: String?
    public var filters: [RequestFilters]
    
    public init(icao: String) {
        self.icao = icao
        self.filters = []
    }
    
    public init(iata: String) {
        self.iata = iata
        self.filters = []
    }
}

public struct AirlineInfoRequest: AeroAPIRequest {
    public func path() throws -> String {
        return "/operators/\((icao ?? iata)!)"
    }
    
    public var icao: String?
    public var iata: String?
    public var filters: [RequestFilters]
    
    public init(icao: String) {
        self.icao = icao
        self.filters = []
    }
    
    public init(iata: String) {
        self.iata = iata
        self.filters = []
    }
}

public struct Airline: Codable {
    
    // MARK: - Codable
    public var icao: String?
    public var iata: String?
    public var name: String?
    public var callsign: String?
    public var country: String?
    public var location: String?
    public var phone: String?
    public var shortname: String?
    public var url: String?
    public var wikiUrl: String?
    public var alternatives: [Airline]?
    
    public var active: Bool! = false
    
    public var operates: String?
    public var facebook: String?
    public var twitter: String?
    public var instagram: String?
    public var youtube: String?
    public var reservations: String?
    public var email: String?
    public var website: String?
    public var loyalty: String?
    public var ally: String?
    
    // MARK: - Computed
    
    // TODO: Add 'unkwn' image asset
    #if os(iOS)
    public var icon: UIImage?
    { UIImage(named: icao ?? "unkwn", in: .module, compatibleWith: nil) }
    #endif
}

extension AeroAPI {
    
    // MARK: - AeroAPI Public
    
    /// Lookup the code that the AeroAPI uses for a given airport
    /// - Parameters:
    ///   - code: Your version of the code for the airport you would like to search
    ///   - type: The Airport ID Type of code you are providing
    /// - Returns: A response containing all matching airports and their AeroAPI code & type
    public func airlineCanonical(code: String, countryCode: String? = nil) async throws -> CanonicalAirlineResponse
    { return try await self.request(CanonicalAirlineRequest(code: code, countryCode: countryCode)) }
    
    /// Lookup the code that the AeroAPI uses for a given airport
    /// - Parameters:
    ///   - code: Your version of the code for the airport you would like to search
    ///   - type: The Airport ID Type of code you are providing
    ///   - completion: A result containing all matching airports and their AeroAPI code & type or an error if one occured
    public func airlineCanonical(code: String,
                                 countryCode: String? = nil,
                                 _ completion: @escaping (Result<CanonicalAirlineResponse, Error>) -> Void)
    { self.request(CanonicalAirlineRequest(code: code, countryCode: countryCode)) { completion($0) }}
    
    /// Get a list of Airline codes
    /// - Parameter maxPages: The number of pages to return
    /// - Returns: A response containing the list of airline codes
    public func getAirlines(maxPages: Int! = 1) async throws -> AirlinesResponse
    { return try await self.request(AirlinesRequest(maxPages: maxPages)) }
    
    
    /// Get a list of Airline codes
    /// - Parameters:
    ///   - maxPages: The number of pages to return
    ///   - completion: A result containing the airline list or the error that occured
    public func getAirlines(maxPages: Int! = 1,
                            _ completion: @escaping (Result<AirlinesResponse, Error>) -> Void)
    { self.request(AirlinesRequest(maxPages: maxPages)) { completion($0) }}
    
    /// Get the count of flights for a given airline within the last 24 hours asynchronously
    /// - Parameter icao: The ICAO code for the requested airport
    /// - Returns: A `AirlineFlightCountResponse` with the count of flights for the airport
    public func getAirlineCountsOnRecord(icao: String) async throws -> AirlineFlightCountResponse
    { return try await self.request(AirlineFlightCountRequest.init(icao: icao)) }
    
    
    /// Get the count of flights for a given airline within the last 24 hours, in a completion closure
    /// - Parameters:
    ///   - icao: The ICAO code for the requested airport
    ///   - completion: A completion with optional `Error` and `AirlineFlightCountResponse` objects depending on the successfulness of the API call.
    public func getAirlineCountsOnRecord(icao: String,
                                         _ completion: @escaping (Result<AirlineFlightCountResponse, Error>) -> Void) {
        self.request(AirlineFlightCountRequest(icao: icao))
        { completion($0) }
    }
    
    /// Async request function for `AirlineInfoRequest`
    /// - Parameter icao: The requested `Airline` icao string
    /// - Returns: `Airline`
    public func getAirlineInfo(icao: String) async throws -> Airline {
        let request = AirlineInfoRequest(icao: icao)
        let airline: Airline = try await self.request(request)
        return mergeWithCached(airline: airline, icao: icao)
    }
    
    /// Async request function for `AirlineInfoRequest`
    /// - Parameter iata: The requested `Airline` iata string
    /// - Returns: `Airline`
    public func getAirlineInfo(iata: String) async throws -> Airline {
        let request = AirlineInfoRequest(iata: iata)
        let airline: Airline = try await self.request(request)
        return mergeWithCached(airline: airline, iata: iata)
    }
    
    /// Completion based request function for `AirlineInfoRequest`
    /// - Parameter icao: The requested `Airline` icao string
    /// - Returns: Completion of optionals `Error` and `Airline`
    public func getAirlineInfo(icao: String,_ completion: @escaping (Result<Airline, Error>) -> Void) {
        let request = AirlineInfoRequest(icao: icao)
        self.request(request) { completion ($0) }
    }
    
    /// Completion based request function for `AirlineInfoRequest`
    /// - Parameter iata: The requested `Airline` iata string
    /// - Returns: Completion of optionals `Error` and `Airline`
    public func getAirlineInfo(iata: String,_ completion: @escaping (Result<Airline, Error>) -> Void) {
        let request = AirlineInfoRequest(iata: iata)
        self.request(request) { completion($0) }
    }
    
    /// Merges the AeroAPI info with the cached Airline info
    /// - Parameter airline: `Airline` object that was returned by the AeroAPI
    /// - Parameter icao: `String` that's the ICAO for the aircraft information that was requested
    /// - Parameter iata: `String` that's the IATA for the aircraft information that was requested
    internal func mergeWithCached(
        airline: Airline,
        icao: String! = nil,
        iata: String! = nil
    ) -> Airline {
        if var cached = (AeroAPI.allAirlines.first(where: { ($0.icao == icao || $0.iata == iata) })) {
            cached.callsign     = airline.callsign
            cached.name         = airline.name
            cached.shortname    = airline.shortname
            cached.country      = airline.country
            cached.location     = airline.location
            cached.url          = airline.url
            cached.wikiUrl      = airline.wikiUrl
            cached.alternatives = airline.alternatives
            
            return cached
        }
        
        return airline
    }
}

extension String {
    public var airline: Airline?
    { AeroAPI.allAirlines.first(where: { $0.icao == self || $0.iata == self }) }
}
