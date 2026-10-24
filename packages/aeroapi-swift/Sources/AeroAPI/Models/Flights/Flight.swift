//
//  Flight.swift
//  AeroAPI
//
//  Created by Justin Ackermann on 10/26/22.
//

// Core iOS
import Foundation

// Utilities
import SwiftDate
import NomadUtilities
import Defaults

public struct FlightDataResponse: Codable, _DefaultsSerializable {
    public var numPages: Int! = 1
    public var flights: [Flight]? = []
    public var links: [String: String]?
}

public struct FlightDataRequest: AeroAPIRequest {
    
    public func path() throws -> String
    { return "\(historical ? "/history" : "")/flights/\(ident)" }
    
    /// the ident of the flight
    public var ident: String
    
    /// whether the request is for historical data
    public var historical: Bool! = false
    
    /// the filters to apply to the request
    public var filters: [RequestFilters]
    
    /// Create a `FlightDataRequest` with a given FlightAware ID.
    /// - Parameter faId: A string representation of the unique FlightAware flight ID for a given flight
    /// - Parameter historical: A boolean value to determine if the request should be for historical data
    public init(faId: String, historical: Bool! = false) throws {
        self.ident = faId
        self.filters = [.identType(.faId)]
        
        guard let flightDate = Int(faId.split(separator: "-")[1])
        else { throw AeroAPIError.faIdDateInvalid(id: faId) }
        
        self.historical = historical
    }
    
    /// Create a `FlightDataRequest` with an given identifier, with or without a `Date` range
    /// - Parameters:
    ///   - ident: The ICAO or IATA flight code, registration for General Aviation or FlightAware Flight ID
    ///   - type: The type of identifier given. Designator, FAID or Registration.
    ///   - dateRange: The optional start and end dates you would like to perform the search under
    public init(ident: String,
                type: IdentType! = .designator,
                dateRange: (start: Date, end: Date)? = nil,
                maxPages: Int! = 1,
                cursor: String? = nil) {
        
        self.ident = ident
        self.filters = [.identType(type), .maxPages(maxPages)]
        
        if let range = dateRange {
            self.historical = range.start.seconds < Date().seconds
            self.filters.append(.startDate(range.start))
            self.filters.append(.endDate(range.end))
        }
        
        if let cursor = cursor
        { self.filters.append(.cursor(cursor)) }
    }
    
    public init(
        ident: String,
        type: IdentType! = .designator,
        historical: Bool! = true,
        filters: [RequestFilters]! = [],
        maxPages: Int! = 1,
        cursor: String? = nil
    ) {
        self.ident = ident
        self.historical = historical
        self.filters = filters + [.identType(type), .maxPages(maxPages)]
    }
}

public struct CanonicalFlightIDRequest: AeroAPIRequest {
    public func path() throws -> String
    { return "/flights/\(code)/canonical" }
    
    public var code: String
    public var filters: [RequestFilters]
    
    init(code: String,
         identType: IdentType? = nil,
         countryCode: String? = nil) {
        self.code = code
        self.filters = []
        
        if let identType = identType, identType != .faId
        { self.filters.append(.identType(identType)) }
        
        if let countryCode = countryCode
        { self.filters.append(.countryCode(countryCode)) }
    }
}

public struct CanonicalFlightIDResponse: Codable {
    var idents: [FlightID]
    
    public struct FlightID: Codable {
        var ident: String
        var identType: IdentType
    }
}

public struct Flight: Codable {
    
    /// Either the ICAO flight number or the Registration for General Aviation
    public var ident: String
    public var identIcao: String?
    public var identIata: String?
    public var faFlightId: String
    public var operatorIcao: String?
    public var operatorIata: String?
    public var flightNumber: String?
    public var registration: String?
    public var atcIdent: String?
    public var inboundFaFlightId: String?
    public var codeshares: [String]?
    public var codesharesIata: [String]?
    public var blocked: Bool?
    public var diverted: Bool?
    public var cancelled: Bool?
    public var positionOnly: Bool?
    public var origin: FlightAirport
    public var destination: FlightAirport?
    public var departureDelay: Int?
    public var arrivalDelay: Int?
    public var filedEte: Int?
    
    public var scheduledOut: Date?
    public var estimatedOut: Date?
    public var actualOut: Date?
    
    public var scheduledOff: Date?
    public var estimatedOff: Date?
    public var actualOff: Date?
    
    public var scheduledOn: Date?
    public var estimatedOn: Date?
    public var actualOn: Date?
    
    public var scheduledIn: Date!
    public var estimatedIn: Date?
    public var actualIn: Date?
    
    public var progressPercent: Int?
    public var status: FlightStatus?
    public var aircraftType: String?
    public var routeDistance: Int?
    public var filedAirspeed: Int?
    public var filedAltitude: Int?
    public var route: String?
    public var baggageClaim: String?
    public var seatsCabinBusiness: Int?
    public var seatsCabinCoach: Int?
    public var seatsCabinFirst: Int?
    public var gateOrigin: String?
    public var gateDestination: String?
    public var terminalOrigin: String?
    public var terminalDestination: String?
    public var type: String?
    
    public var lastPosition: LastPosition?
    
    /// This is a utility value that is not used by the FlightAware API. Use this value for when syncing with a database.
    public var updated: Date?
    
    /// the operating airline for the flight
    public var operating: Airline?
    { return self.operatorIcao?.airline ?? self.operatorIata?.airline }
    
    /// Calculated haversine distance between airports
    /// TODO: Fix Optional on destination
    public var distance: Distance
    { Distance(from: origin.airport.coordinate, to: destination!.airport.coordinate) }
    
    /// duration of the flight
    public var duration: TimeInterval? {
        let current = Date().since1970
        if scheduledIn.since1970 < current {
            guard let timein = actualIn?.since1970,
                  let timeout = actualOut?.since1970
            else {
                let timein = scheduledIn.since1970
                guard let timeout = scheduledOut?.since1970
                else { return nil }
                
                return timein - timeout
            }
            
            return timein - timeout
        } else {
            let timein = scheduledIn.since1970
            guard let timeout = scheduledOut?.since1970
            else { return nil }
            
            return timein - timeout
        }
    }
    
    /// scheduled out, estimated out & actual out
    public func departure() -> (Date, Date?, Date?) {
        return (
            self.scheduledOut!,
            self.estimatedOut,
            self.actualOut
        )
    }
    
    /// scheduled in, estimated in & actual in
    public func arrival() -> (Date, Date?, Date?) {
        return (
            self.scheduledIn,
            self.estimatedIn,
            self.actualIn
        )
    }
}

extension AeroAPI {
    
    // MARK: - Flight Data Requests
    
    /// Lookup the code that the AeroAPI uses for a given flight
    /// - Parameters:
    ///   - code: Your version of the code for the flight you would like to search
    ///   - type: The flight `IdentType` of code you are providing
    /// - Returns: A `CanonicalFlightIDResponse` containing all matching flight idents and their AeroAPI code & type
    public func flightIDCanonical(code: String,
                                  type: IdentType? = nil,
                                  countryCode: String? = nil) async throws -> CanonicalFlightIDResponse
    { return try await self.request(CanonicalFlightIDRequest(code: code, identType: type, countryCode: countryCode)) }
    
    /// Lookup the code that the AeroAPI uses for a given flight
    /// - Parameters:
    ///   - code: Your version of the code for the flight you would like to search
    ///   - type: The Flight `IdentType` of code you are providing
    ///   - completion: A result containing a `CanonicalFlightIDResponse` or an error if one occured
    public func flightIDCanonical(code: String,
                                 type: IdentType? = nil,
                                  countryCode: String? = nil,
                                 _ completion: @escaping (Result<CanonicalFlightIDResponse, Error>) -> Void)
    { self.request(CanonicalFlightIDRequest(code: code, identType: type, countryCode: countryCode)) { completion($0) }}
    
    /// Get flight information asynchronously using the unique FAID for a given flight
    /// - Parameter faId: The unique flight ID for the requested flight
    /// - Returns: An optional `Flight` object with the flight information
    public func getFlightData(faId: String) async throws -> Flight?
    { return try await getFlightData(.init(faId: faId)).flights?.first }
    
    
    /// Get flight information from a unique FAID using a completion based callback
    /// - Parameters:
    ///   - faId: The unique flight ID for the requested flight
    ///   - completion: A tuple containing an optional `Error` and `Flight` objects based on the successfulness of the request
    public func getFlightData(faId: String,_ completion: @escaping (Result<Flight, Error>) -> Void) {
        do {
            let request = try FlightDataRequest(faId: faId)
            getFlightData(request)
            { (result: Result<FlightDataResponse, Error>) in
                switch result {
                case .success(let response):
                    guard let flight = response.flights?.first
                    else { return } // THROW:
                    
                    completion(.success(flight))
                    
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } catch { completion(.failure(error)) }
    }
    
    /// Get flight information asynchronously from a `FlightDataRequest` using this function
    /// - Parameters:
    ///   - request: Use a `FlightDataRequest` to specify the parameters of the flight search
    /// - Returns: A `FlightDataResponse` containing the flights found using the search request
    public func getFlightData(_ request: FlightDataRequest) async throws -> FlightDataResponse
    { return try await self.request(request) }
    
    
    /// Get flight information from a `FlightDataRequest` using a completion based callback
    /// - Parameters:
    ///   - request: Use a `FlightDataRequest` to specify the parameters of the flight search
    ///   - completion: A tuple containing an optional `Error` and `Data` objects based on the successfulness of the request
    public func getFlightData(_ request: FlightDataRequest,
                              _ completion: @escaping (Result<FlightDataResponse, Error>) -> Void) {
        self.request(request) { completion($0) }
    }
    
}
