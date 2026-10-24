//
//  AircraftOwner.swift
//  
//
//  Created by Justin Ackermann on 10/3/23.
//

import Foundation

public struct AircraftOwnerRequest: AeroAPIRequest {
    public func path() throws -> String
    { return "/aircraft/\(ident)/owner" }
    
    public var ident: String
    public var filters: [RequestFilters]
    
    public init(ident: String) {
        self.ident = ident
        self.filters = []
    }
}

public struct AircraftOwnerResponse: Codable {
    public var owner: Owner
    
    public struct Owner: Codable {
        var name: String?
        var location: String?
        var location2: String?
        var website: String?
    }
}

extension AeroAPI {
    
    // MARK: - AeroAPI Public
 
    
    /// A function to get the ownership details of a given registration
    /// - Parameter registration: The tail number of the requested aircraft
    /// - Returns: A response containing all the Aircraft ownership details
    public func getOwner(for registration: String) async throws -> AircraftOwnerResponse
    { return try await self.request(AircraftOwnerRequest(ident: registration)) }
    
    
    /// A function to get the ownership details of a given registration
    /// - Parameters:
    ///   - registration: The tail number of the requested aircraft
    ///   - completion: A response containing all the Aircraft ownership details in a result closure
    public func getOwner(for registration: String,
                         _ completion: @escaping (Result<AircraftOwnerResponse, Error>) -> Void) {
        self.request(AircraftOwnerRequest(ident: registration))
        { completion($0) }
    }
}
