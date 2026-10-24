//
//  AdvancedSearch.swift
//
//
//  Created by Justin Ackermann on 11/27/23.
//

import Foundation

extension AeroAPI {
    
    public func advancedSearch(param: AdvancedSearchParameter) async throws -> FlightDataResponse
    { return try await AeroAPI.manager.request(param) }
    
    /// Makes the given request and returns the specified `Flight`s
    /// - Parameter request: `AdvancedSearhParameter`
    /// - Returns: The `Flight`s object requested from the API Request
    internal func request(_ param: AdvancedSearchParameter) async throws -> FlightDataResponse {
        guard let apiKey = apiKey
        else { throw AeroAPIError.apiKeyNotSet }
        
        let url = try makeUrl(param)
        let urlRequest = try URLRequest(
            url: url,
            method: .get,
            headers: [
                .init(name: "x-apikey", value: apiKey)
            ]
        )
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        let statusCode = (response as? HTTPURLResponse)?.statusCode
        
        guard let statusCode = statusCode, statusCode == 200
        else { throw AeroAPIError.HTTPResponseError(statusCode) }
        
        if AeroAPI.debug {
            let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]
            print("=== JSON DATA ===")
            print(json ?? [:])
            print("=================")
        }
        
        let decoded = try decoder.decode(FlightDataResponse.self, from: data)
        return decoded
    }
    
    /// Makes the url of the API all for the given `AdvancedSearchRequest`
    /// - Parameter param: `AdvancedSearchRequest` of call
    /// - Returns: URL rendererd with components
    internal func makeUrl(_ param: AdvancedSearchParameter) throws -> URL {
        let path = "/flights/search/advanced"
        
        var components = AeroAPI.components
        components.path = "/aeroapi" + path
        components.queryItems = param.query
        
        guard let url = components.url
        else { throw AeroAPIError.invalidURLFromComponents }
        
        if AeroAPI.debug {
            print("REQUESTING: \(url.absoluteString)")
            print()
        }
        
        return url
    }
}

public enum AdvancedSearchParameter {
    
    case Origin(Airport)
    case OriginOrDest(Airport)
    case Destination(Airport)
    
    case MapBounds(MapBounds)
    
    var query: [URLQueryItem] {
        switch self {
        case .MapBounds(let bounds):
            let lon = [bounds.NECoord.longitude, bounds.NWCoord.longitude].sorted(by: { $0 < $1 })
            let lat = [bounds.NWCoord.latitude, bounds.SWCoord.latitude].sorted(by: { $0 < $1 })
            let query = "{range lat \(lat[0]) \(lat[1])} {range lon \(lon[0]) \(lon[1])} {< alt 500}"
            
            if AeroAPI.debug {
                print("RAW QUERY: \(query)")
                print()
            }
            
            return [
                URLQueryItem(name: "query", value: query),
                URLQueryItem(name: "max_pages", value: "5")
            ]
            
        default: return [URLQueryItem(name: "", value: "")]
        }
    }
}
