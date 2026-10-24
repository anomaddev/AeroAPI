import Foundation
import CoreLocation

public struct AirportsRequest: AeroAPIRequest {
    public func path() throws -> String
    { return "/airports" }
    
    public var filters: [RequestFilters]
    
    public init(maxPages: Int! = 1)
    { self.filters = [.maxPages(maxPages)] }
}

public struct AirportsResponse: Codable {
    public var airports: [AirportInfo]
    public var numPages: Int?
    public var links: [String: String]?
    
    public struct AirportInfo: Codable {
        public var code: String
        public var airportInfoUrl: String
    }
}

public struct CanonicalAirportRequest: AeroAPIRequest {
    public func path() throws -> String
    { return "/airports/\(code)/canonical" }
    
    public var code: String
    public var filters: [RequestFilters]
    
    init(code: String, idType: AirportIDType) {
        self.code = code
        self.filters = [.airportIDType(idType)]
    }
}

public struct CanonicalAirportResponse: Codable {
    var airports: [AirportID]
    
    public struct AirportID: Codable {
        var id: String
        var idType: AirportIDType
    }
}

public enum AirportIDType: String, Codable {
    case icao
    case iata
    case lid
}

/// Use this request for getting more Airport info from the AeroAPI
public struct AirportInfoRequest: AeroAPIRequest {
    public func path() throws -> String {
        return "/airports/\((icao ?? iata ?? code)!)"
    }
    
    public var icao: String?
    public var iata: String?
    public var code: String?
    public var filters: [RequestFilters]
    
    
    /// Init a request for more Airport info using the ICAO code
    /// - Parameter icao: The ICAO code of the airport
    public init(icao: String) {
        self.icao = icao
        self.filters = []
    }
    
    
    /// Init a request for more Airport info using the IATA code
    /// - Parameter iata: The IATA code of the airport
    public init(iata: String) {
        self.iata = iata
        self.filters = []
    }
    
    
    /// Init a request for more Airport info using any code for the Airport
    /// - Parameter code: The ICAO, IATA or LID code of the airport
    public init(code: String) {
        self.code = code
        self.filters = []
    }
}

/// An `Airport` Object contains all the airport's details
public class Airport: Codable {
    
    // TODO: Document
    public static func search(using text: String) -> [Airport] {
        let icao = AeroAPI.allAirports.filter { $0.codeIcao == text }
        let iata = AeroAPI.allAirports.filter { $0.codeIata == text }
        let name = AeroAPI.allAirports.filter { $0.name.contains(text) }
        
        return [
            icao,
            iata,
            name
        ].reduce([], +)
    }
    
    /// Active code used for airport. Could be ICAO, IATA or LID code.
    public var airportCode: String?
    
    /// ICAO Airport code
    public var codeIcao: String?
    
    /// IATA Airport code
    public var codeIata: String?
    
    /// Airport LID code
    public var codeLid: String?
    
    /// Name of the Airport
    public var name: String

    /// Type of Airport
    public var type: AirportType?
    
    /// Elevation in Meters
    public var elevation: Double?
    
    /// City of the Airport
    public var city: String
    
    /// State or Country of the Airport
    public var state: String?
    
    /// Country Code of the Airport
    public var countryCode: String
    
    /// Timezone of the Airport
    public var timezone: String?
    
    #if !os(macOS)
    public var TZ: TimeZone?
    { TimezoneMapper.latLngToTimezone(coordinate) }
    #endif
    
    /// Longitude represented as a `Double`
    public var longitude: Double
    
    /// Latitude represented as a `Double`
    public var latitude: Double
    
    public var url: String?
    public var wikiUrl: String?
    public var airportFlightsUrl: URL?
    public var alternatives: [Airport]?
    
    public var facebook: String?
    public var twitter: String?
    public var instagram: String?
    public var youtube: String?
    public var phone: String?
    public var email: String?
    
    public var coordinate: CLLocationCoordinate2D
    { CLLocationCoordinate2D(latitude: latitude, longitude: longitude) }
    
    // TODO: Make this hardcoded
    public var shortName: String {
        return name
            .replacingOccurrences(of: "Regional", with: "Regl.")
            .replacingOccurrences(of: "Metropolitan", with: "Metro.")
            .replacingOccurrences(of: "International", with: "Intl.")
            .replacingOccurrences(of: "Airport", with: "")
    }
}

public enum AirportType: String, Codable {
    
    case Airport
    case Heliport
    case SeaplaneBase = "Seaplane Base"
    case Balloonport
    case Ultralight
    case Gliderport
    case Stolport

}

extension AeroAPI {
    
    // MARK: - AeroAPI Public
    
    
    /// Lookup the code that the AeroAPI uses for a given airport
    /// - Parameters:
    ///   - code: Your version of the code for the airport you would like to search
    ///   - type: The Airport ID Type of code you are providing
    /// - Returns: A response containing all matching airports and their AeroAPI code & type
    public func airportCanonical(code: String, type: AirportIDType! = .icao) async throws -> CanonicalAirportResponse
    { return try await self.request(CanonicalAirportRequest(code: code, idType: type)) }
    
    /// Lookup the code that the AeroAPI uses for a given airport
    /// - Parameters:
    ///   - code: Your version of the code for the airport you would like to search
    ///   - type: The Airport ID Type of code you are providing
    ///   - completion: A result containing all matching airports and their AeroAPI code & type or an error if one occured
    public func airportCanonical(code: String,
                                 type: AirportIDType! = .icao,
                                 _ completion: @escaping (Result<CanonicalAirportResponse, Error>) -> Void)
    { self.request(CanonicalAirportRequest(code: code, idType: type)) { completion($0) }}
    
    /// Get a list of Airport codes
    /// - Parameter maxPages: The number of pages to return
    /// - Returns: A response containing the list of airport codes
    public func getAirports(maxPages: Int! = 1) async throws -> AirportsResponse
    { return try await self.request(AirportsRequest(maxPages: maxPages)) }
    
    
    /// Get a list of Airport codes
    /// - Parameters:
    ///   - maxPages: The number of pages to return
    ///   - completion: A result containing the airport list or the error that occured
    public func getAirports(maxPages: Int! = 1,
                            _ completion: @escaping (Result<AirportsResponse, Error>) -> Void)
    { self.request(AirportsRequest(maxPages: maxPages)) { completion($0) }}
    
    /// Async request function for `AirportInfoRequest`
    /// - Parameter code: The requested `Airport` code in ICAO, IATA or LID string
    /// - Returns: `Airport`
    public func getAirportInfo(code: String) async throws -> Airport {
        let request = AirportInfoRequest(code: code)
        let airport: Airport = try await self.request(request)
        return mergeWithCached(airport: airport, code: code)
    }
    
    /// Async request function for `AirportInfoRequest`
    /// - Parameter icao: The requested `Airport` icao string
    /// - Returns: `Airport`
    public func getAirportInfo(icao: String) async throws -> Airport {
        let request = AirportInfoRequest(icao: icao)
        let airport: Airport = try await self.request(request)
        return mergeWithCached(airport: airport, icao: icao)
    }
    
    /// Async request function for `AirportInfoRequest`
    /// - Parameter iata: The requested `Airport` iata string
    /// - Returns: `Airport`
    public func getAirportInfo(iata: String) async throws -> Airport {
        let request = AirportInfoRequest(iata: iata)
        let airport: Airport = try await self.request(request)
        return mergeWithCached(airport: airport, iata: iata)
    }
    
    /// Completion based request function for `AirportInfoRequest`
    /// - Parameter code: The requested `Airport` code string
    /// - Returns: Completion of optionals `Error` and `Airport`
    public func getAirportInfo(code: String,_ completion: @escaping (Result<Airport, Error>) -> Void) {
        let request = AirportInfoRequest(code: code)
        self.request(request)
        { (result: Result<Airport, Error>) in
            switch result {
            case .success(let airport):
                completion(.success(self.mergeWithCached(airport: airport, code: code)))
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Completion based request function for `AirportInfoRequest`
    /// - Parameter icao: The requested `Airport` icao string
    /// - Returns: Completion of optionals `Error` and `Airport`
    public func getAirportInfo(icao: String,_ completion: @escaping (Result<Airport, Error>) -> Void) {
        let request = AirportInfoRequest(icao: icao)
        self.request(request)
        { (result: Result<Airport, Error>) in
            switch result {
            case .success(let airport):
                completion(.success(self.mergeWithCached(airport: airport, code: icao)))
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Completion based request function for `AirportInfoRequest`
    /// - Parameter iata: The requested `Airport` iata string
    /// - Returns: Completion of optionals `Error` and `Airport`
    public func getAirportInfo(iata: String,_ completion: @escaping (Result<Airport, Error>) -> Void) {
        let request = AirportInfoRequest(iata: iata)
        self.request(request)
        { (result: Result<Airport, Error>) in
            switch result {
            case .success(let airport):
                completion(.success(self.mergeWithCached(airport: airport, code: iata)))
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Gets all the airports that are nearby a give airport asynchronously
    /// - Parameter request: The request object containing the parameters for which Airport you will search around.
    /// - Returns: A response with the nearby airports.
    public func getAirportsNear(request: AirportsNearbyRequest) async throws -> AirportsNearbyResponse
    { return try await self.request(request) }
    
    
    /// Gets all the airports that are nearby a give airport with a result closure response
    /// - Parameters:
    ///   - request: The request object containing parameters for which Airport you will search around.
    ///   - completion: A result with the state of the API request
    public func getAirportsNear(request: AirportsNearbyRequest,
                                _ completion: @escaping (Result<AirportsNearbyResponse, Error>) -> Void) {
        self.request(request) { completion($0) }
    }
    
    /// Merges the AeroAPI info with the cached Airport info
    /// - Parameter airport: `Airport` object that was returned by the AeroAPI
    /// - Parameter icao: `String` that's the ICAO for the aircraft information that was requested
    /// - Parameter iata: `String` that's the IATA for the aircraft information that was requested
    /// - Returns: An `Airport` object with merged data if cached data found
    internal func mergeWithCached(
        airport: Airport,
        icao: String! = nil,
        iata: String! = nil,
        code: String! = nil
    ) -> Airport {
        if let cached = (AeroAPI.allAirports.first(where: {
            ($0.codeIcao == icao || $0.codeIata == iata || $0.airportCode == code)
        })) {
            cached.airportCode  = airport.airportCode
            cached.codeLid      = airport.codeLid
            cached.name         = airport.name
            cached.type         = airport.type
            cached.elevation    = airport.elevation
            cached.city         = airport.city
            cached.state        = airport.state
            cached.longitude    = airport.longitude
            cached.latitude     = airport.latitude
            cached.timezone     = airport.timezone
            cached.countryCode  = airport.countryCode
            cached.url          = airport.url
            cached.wikiUrl      = airport.wikiUrl
            cached.airportFlightsUrl = airport.airportFlightsUrl
            cached.alternatives = airport.alternatives
            
            return cached
        }
        
        return airport
    }
}

extension String {
    public var airport: Airport?
    { AeroAPI.allAirports.first(where: { $0.codeIcao == self || $0.codeIata == self }) }
}
