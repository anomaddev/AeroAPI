import Foundation

public struct Codeshare: Codable {
    
    public var ident: String
    public var identIcao: String?
    public var identIata: String?
    
    public var actualIdent: String?
    
    public init(_ flight: ScheduledFlight) {
        ident = flight.ident
        identIcao = flight.identIcao
        identIata = flight.identIata
        actualIdent = flight.actualIdent // THROW:
    }
    
    public init(_ icao: String, actual: String) {
        ident = icao
        identIcao = icao
        actualIdent = actual
    }
}
