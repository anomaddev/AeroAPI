import Foundation
import CoreLocation

public protocol AeroAPIRequest: Codable {
    var filters: [RequestFilters] { get set }
    
    func path() throws -> String
    func request() throws -> [URLQueryItem]
}

public struct CursorRequest: AeroAPIRequest {
    public func path() throws -> String
    { return cursor }
    
    public var cursor: String
    public var filters: [RequestFilters]
    
    init(cursor: String) {
        self.cursor = cursor
        self.filters = []
    }
}

public extension AeroAPIRequest {
    func request() throws -> [URLQueryItem] {
        return try self.filters.compactMap { filter -> [URLQueryItem] in
            switch filter {
            case .ident(let ident):
                return [URLQueryItem(name: "ident", value: ident)]
                
            case .identType(let type):
                return [URLQueryItem(name: "ident_type", value: type.rawValue)]
                
            case .airportIDType(let type):
                return [URLQueryItem(name: "id_type", value: type.rawValue)]
                
            case .airline(let airline):
                return [URLQueryItem(name: "airline", value: airline)]
                
            case .origin(let origin):
                return [URLQueryItem(name: "origin", value: origin)]
                
            case .destination(let dest):
                return [URLQueryItem(name: "destination", value: dest)]
                
            case .latitude(let lat):
                return [URLQueryItem(name: "latitude", value: "\(lat)")]
                
            case .longitude(let lng):
                return [URLQueryItem(name: "longitude", value: "\(lng)")]
                
            case .countryCode(let code):
                return [URLQueryItem(name: "country_code", value: code)]
                
            case .timestamp(let stamp):
                return [URLQueryItem(name: "timestamp", value: stamp.toFormat(AeroAPI.dateStringFormat))]
                
            case .startDate(let start):
                return [URLQueryItem(name: "start", value: start.toFormat(AeroAPI.dateStringFormat))]
                
            case .endDate(let end):
                return [URLQueryItem(name: "end", value: end.toFormat(AeroAPI.dateStringFormat))]
                
            case .startTimestamp(let start):
                return [URLQueryItem(name: "start", value: start)]
                
            case .endTimestamp(let end):
                return [URLQueryItem(name: "end", value: end)]
                
            case .disruptionTimePeriod(let time):
                return [URLQueryItem(name: "time_period", value: time.rawValue)]
                
            case .flightNumber(let number):
                return [URLQueryItem(name: "flight_number", value: "\(number)")]
                
            case .includeCodeshares(let include):
                return [URLQueryItem(name: "included_codeshares", value: "\(include)")]
                
            case .includeEstimated(let include):
                return [URLQueryItem(name: "include_estimated_positions", value: "\(include)")]
                
            case .cursor(let cursor):
                return [URLQueryItem(name: "cursor", value: cursor)]
                
            case .maxPages(let pages):
                return [URLQueryItem(name: "max_pages", value: "\(pages)")]
                
            case .airportFlightType(let type):
                return [URLQueryItem(name: "type", value: "\(type.rawValue)")]
                
            case .connectionType(let type):
                return [URLQueryItem(name: "connection", value: "\(type.rawValue)")]
                
            case .radius(let radius):
                return [URLQueryItem(name: "radius", value: "\(radius)")]
                
            case .onlyInstuments(let onlyIAP):
                return [URLQueryItem(name: "only_iap", value: "\(onlyIAP)")]
                
            case .returnNearbyWeather(let bool):
                return [URLQueryItem(name: "return_nearby_weather", value: "\(bool)")]
                
            case .routeSortBy(let sort):
                return [URLQueryItem(name: "sort_by", value: sort.rawValue)]
                
            case .maxFileAge(let max):
                return [URLQueryItem(name: "max_file_age", value: max)]
                
            case .temperatureUnits(let units):
                return [URLQueryItem(name: "temperature_units", value: units.rawValue)]
                
            case .height(let height):
                guard height > 0 && height <= 1500
                else { throw AeroAPIError.invalidMapHeight(height) }
                return [URLQueryItem(name: "height", value: "\(height)")]
                
            case .width(let width):
                guard width > 0 && width <= 1500
                else { throw AeroAPIError.invalidMapWidth(width) }
                return [URLQueryItem(name: "width", value: "\(width)")]
                
            case .layersOn(let layers):
                return layers.compactMap { return URLQueryItem(name: "layer_on", value: $0.rawValue) }
                
            case .layersOff(let layers):
                return layers.compactMap { return URLQueryItem(name: "layer_off", value: $0.rawValue) }
                
            case .showDataBlock(let show):
                return [URLQueryItem(name: "show_data_block", value: "\(show)")]
                
            case .airportsExpandView(let expand):
                return [URLQueryItem(name: "airports_expand_view", value: "\(expand)")]
                
            case .showAirports(let show):
                return [URLQueryItem(name: "show_airports", value: "\(show)")]
                
                // TODO: Implement
//            case .boundingBox(let top, let right, let bottom, let left):
//                return [URLQueryItem(name: "bounding_box", value: "")]
                
            }
        }.reduce([]) { $0 + $1 }
    }
}

/// AeroAPI Request Filters
public enum RequestFilters: Codable {
    case ident(String)
    case identType(IdentType)
    case airportIDType(AirportIDType)
    
    case airline(String)
    case origin(String)
    case destination(String)
    case latitude(Double)
    case longitude(Double)
    case countryCode(String)
    
    case timestamp(Date)
    case startDate(Date)
    case startTimestamp(String)
    case endDate(Date)
    case endTimestamp(String)
    case disruptionTimePeriod(DisruptionCountTimePeriod)
    
    case flightNumber(Int)
    case includeCodeshares(Bool)
    case includeEstimated(Bool)
    
    case cursor(String)
    case maxPages(Int)
    
    case airportFlightType(FlightType)
    case connectionType(FlightConnectionType)
    case radius(Int)
    case onlyInstuments(Bool)
    
    case returnNearbyWeather(Bool)
    case routeSortBy(RouteRequestSort)
    case maxFileAge(String)
    case temperatureUnits(TemperatureUnits)
    
    case height(Int)
    case width(Int)
    case layersOn([FlightAwareMapLayer])
    case layersOff([FlightAwareMapLayer])
    case showDataBlock(Bool)
    case airportsExpandView(Bool)
    case showAirports(Bool)
//    case boundingBox(
//        top: (Double, Double),
//        right: (Double, Double),
//        bottom: (Double, Double),
//        left: (Double, Double)
//    )
}

/// The flight's identifier type
public enum IdentType: String, Codable {
    /// The IATA or ICAO flight no
    case designator
    
    /// The FlightAware flight ID
    case faId = "fa_flight_id"
    
    /// The tail number of the aircraft
    case registration
}
