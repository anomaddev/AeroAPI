import Foundation

/// Errors for the AeroAPI
public enum AeroAPIError: Error {
    
    /// API key is not set
    case apiKeyNotSet
    
    /// No FlightAware ID for flight
    case noFaId
    
    /// Could not generate URL from components of AeroAPIRequest
    case invalidURLFromComponents
    
    /// When the HTTP response errors present the code
    case HTTPResponseError(_ code: Int?)
    
    /// When the HTTP response is 200, but no data was returned
    case noDataReturnedForValidStatusCode
    
    
    // Data errors
    /// no errors were thrown but no flight data was returned either
    case noFlightDataForValidRequest
    
    /// no errors were thrown but no flight track data was returned either
    case noFlightTrackDataForValidRequest
    
    /// no errors were thrown but no flight route data was returned either
    case noFlightRouteForValidRequest
    
    /// no errors were thrown but no airport status data was returned either
    case noAirportStatusForValidRequest
    
    /// no errors were thrown but no airport flights were returned either
    case noAirportFlightsForValidRequest
    
    /// no errors were thrown but no airport count stats were returned either
    case noAirportFlightCountStats
    
    /// no errors were thrown but no airline flight count stats were returned either
    case noAirlineFlightCountsForRequest
    
    
    // Map errors
    /// invalid height was given to a map data request
    case invalidMapHeight(Int)
    
    /// invalid width was given to a map data request
    case invalidMapWidth(Int)
    
    
    // Date errors
    /// start date for search cannot be completed
    case startDateCreationInvalid
    
    /// end date for search cannot be completed
    case endDateCreationInvalid
    
    /// date range invalid for `AirportFlightsRequest`
    case invalidDateAirportFlightsRequest
    
    /// start date cannot be before end date
    case startDateBeforeEndDate
    
    
    // Flight Info Errors
    /// the date value in the provided FAID is invalid
    case faIdDateInvalid(id: String)
    
    // Flight Track errors
    /// flight track response is empty
    case flightTrackEmpty
    
    
    // Decoder errors
    /// failed to decode ScheduledFlightResponse
    case failedDecodingScheduledFlightResponse
    
    /// failed to decode FlightDataResponse
    case failedDecodingFlightDataResponse
    
    /// failed to decode FlightTrackResponse
    case failedDecodingFlightTrackResponse
    
    /// failed to decode JSON map byte array
    case failedDecodingMapData
    
    /// failed to decode Base64 Data to UIImage
    case invalidUIImageFromData
    
    /// Generic error
    case fall
    
    /// Throw in all other cases
    case unexpected(code: Int)
}

extension AeroAPIError: CustomStringConvertible {
    public var description: String {
        switch self {
            
        case .apiKeyNotSet:
            return "No API Key set for the AeroAPI module."
            
        case .noFaId:
            return "No faId found for this scheduled flight."
            
        case .invalidURLFromComponents:
            return "Could not generate URL from components of AeroAPIRequest."
            
        case .HTTPResponseError(let code):
            return "HTTP Response Error Code: \(code ?? 9999)"
            
        case .noDataReturnedForValidStatusCode:
            return "The HTTP Response was 200 but we did not return any data."
            
        case .noFlightDataForValidRequest:
            return "No flight data was returned for a request that returned no error."
            
        case .noFlightTrackDataForValidRequest:
            return "No flight track data was returned for a request that returned no error."
            
        case .noFlightRouteForValidRequest:
            return "No flight route data was returned for a request that returned no error."
            
        case .noAirportStatusForValidRequest:
            return "No airport status data was returned for a request that returned no error."
            
        case .noAirportFlightsForValidRequest:
            return "No airport flights data was returned for a request that returned no error."
            
        case .noAirportFlightCountStats:
            return "No airport flight count stats data was returned for a request that returned no error."
            
        case .noAirlineFlightCountsForRequest:
            return "No airline flight count stats data was returned for a request that returned no error."
            
        case .invalidMapHeight(let height):
            return "The height (\(height)) given to the request for map data is invalid. It must be between 1 and 1500!"
            
        case .invalidMapWidth(let width):
            return "The width (\(width)) given to the request for map data is invalid. It must be between 1 and 1500!"
            
        case .startDateCreationInvalid:
            return "Failed to create start date using calendar"
            
        case .endDateCreationInvalid:
            return "Failed to create end date using calendar"
            
        case .invalidDateAirportFlightsRequest:
            return "Start and End dates for an AirportFlightsRequest must be no further than a week in the past and two days in the future."
            
        case .startDateBeforeEndDate:
            return "Start Date cannot be before the End Date."
            
        case .faIdDateInvalid(let id):
            return "The FAID date string is invalid: \(id)"
            
        case .failedDecodingScheduledFlightResponse:
            return "Failed to decode the ScheduledFlightResponse"
            
        case .failedDecodingFlightDataResponse:
            return "Failed to decode the FlightDataResponse"
            
        case .failedDecodingMapData:
            return "Failed to decode 'map' from JSON data response"
            
        case .invalidUIImageFromData:
            return "Failed to decode UIImage from Base64 String"
            
        // MARK: - desc,FlightTrack
        case .flightTrackEmpty:
            return "Flight Track response is empty"
            
        case .failedDecodingFlightTrackResponse:
            return "Failed to decode the FlightTrackResponse"
         
        // MARK: - desc,Generic
        case .fall:
            return "An ignorable generic error occured."
            
        case .unexpected(let code):
            return "An unexpected error occurred: \(code)"
        }
    }
}

extension AeroAPIError: LocalizedError {
    public var errorDescription: String? {
        var key: String = ""
        switch self {
            
        case .apiKeyNotSet:
            key = "apiKeyNotSet"
        
        case .noFaId:
            key = "noFaId"
        
        case .invalidURLFromComponents:
            key = "invalidURLFromComponents"
            
        case .HTTPResponseError:
            key = "HTTPResponseError"
            
        case .noDataReturnedForValidStatusCode:
            key = "noDataReturnedForValidStatusCode"
            
        case .noFlightDataForValidRequest:
            key = "noFlightDataForValidRequest"
            
        case .noFlightTrackDataForValidRequest:
            key = "noFlightTrackDataForValidRequest"
            
        case .noFlightRouteForValidRequest:
            key = "noFlightRouteForValidRequest"
            
        case .noAirportStatusForValidRequest:
            key = "noAirportStatusForValidRequest"
            
        case .noAirportFlightsForValidRequest:
            key = "noAirportFlightsForValidRequest"
            
        case .noAirportFlightCountStats:
            key = "noAirportFlightCountStats"
            
        case .noAirlineFlightCountsForRequest:
            key = "noAirlineFlightCountsForRequest"
            
        case .invalidMapHeight:
            key = "invalidMapHeight"
            
        case .invalidMapWidth:
            key = "invalidMapWidth"
        
        case .startDateCreationInvalid:
            key = "startDateCreationInvalid"
        
        case .endDateCreationInvalid:
            key = "endDateCreationInvalid"
            
        case .invalidDateAirportFlightsRequest:
            key = "invalidDateAirportFlightsRequest"
            
        case .startDateBeforeEndDate:
            key = "startDateBeforeEndDate"
            
        case .faIdDateInvalid:
            key = "faIdDateInvalid"
        
        case .failedDecodingScheduledFlightResponse:
            key = "failedDecodingScheduledFlightResponse"
        
        case .failedDecodingFlightDataResponse:
            key = "failedDecodingFlightDataResponse"
            
        case .failedDecodingMapData:
            key = "failedDecodingMapData"
            
        case .invalidUIImageFromData:
            key = "invalidUIImageFromData"
            
        // MARK: - errorDesc,FlightTrack
        case .flightTrackEmpty:
            key = "flightTrackEmpty"
            
        case .failedDecodingFlightTrackResponse:
            key = "failedDecodingFlightTrackResponse"
            
        // MARK: - errorDesc,Generic
        case .fall:
            key = "fall"
        
        case .unexpected:
            key = "unexpected"
        }
        
        return NSLocalizedString(
            key,
            comment: self.description
        )
    }
}
