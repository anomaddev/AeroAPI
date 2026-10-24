//
//  DisruptionCounts.swift
//  
//
//  Created by Justin Ackermann on 10/3/23.
//

import Foundation

public struct DisruptionCountsRequest: AeroAPIRequest {
    
    public func path() throws -> String {
        let base = "/disruption_counts/\(entityType)/"
        if let code = code { return base + code }
        else { return base }
    }
    
    public var code: String? = nil
    public var entityType: DisruptionCountType
    public var filters: [RequestFilters]
    
    public init(
        type: DisruptionCountType,
        timePeriod: DisruptionCountTimePeriod! = .today,
        maxPages: Int! = 1
    ) {
        self.entityType = type
        self.filters = [
            .disruptionTimePeriod(timePeriod),
            .maxPages(maxPages)
        ]
    }
    
    public init(
        code: String? = nil,
        type: DisruptionCountType,
        timePeriod: DisruptionCountTimePeriod! = .today
    ) {
        self.code = code
        self.entityType = type
        self.filters = [.disruptionTimePeriod(timePeriod)]
    }
}

public struct DisruptionCountResponse: Codable {
    
    var entities: [DisruptionEntity]
    var totalCancellationsNational: Int
    var totalCancellationsWorldwide: Int
    var totalDelaysWorldwide: Int
    
    var numPages: Int?
    var links: [String: String]?
    
}

public struct DisruptionEntity: Codable {
    
    var cancellations: Int
    var delays: Int
    var total: Int
    var entityName: String?
    var entityId: String?
    
}

public enum DisruptionCountType: String, Codable {
    case airline
    case origin
    case destination
}

public enum DisruptionCountTimePeriod: String, Codable {
    case yesterday
    case today
    case tomorrow
    case plus2days
    case twoDaysAgo
    case minus2plus12hrs
    case next36hrs
    case aweek = "week"
}

extension AeroAPI {
    
    // MARK: - AeroAPI Public
    
    
    /// Get the disruption counts of a specific entity
    /// - Parameters:
    ///   - entity: The ICAO, IATA or LID code
    ///   - type: The airline, origin or destination type request
    ///   - timePeriod: The time period you would like for counts
    /// - Returns: An object containing the disruption entity
    public func disruptionsAt(
        entity: String,
        type: DisruptionCountType,
        timePeriod: DisruptionCountTimePeriod! = .today
    ) async throws -> DisruptionEntity {
        return try await self.request(DisruptionCountsRequest(
            code: entity,
            type: type,
            timePeriod: timePeriod
        ))
    }
    
    /// Get the disruption counts of a specific entity
    /// - Parameters:
    ///   - entity: The ICAO, IATA or LID code
    ///   - type: The airline, origin or destination type request
    ///   - timePeriod: The time period you would like for counts
    ///   - completion: A result closure containing the disruption entity or error that occured
    public func disruptionsAt(
        entity: String,
        type: DisruptionCountType,
        timePeriod: DisruptionCountTimePeriod! = .today,
        _ completion: @escaping (Result<DisruptionEntity, Error>) -> Void
    ) {
        self.request(DisruptionCountsRequest(
            code: entity,
            type: type,
            timePeriod: timePeriod
        )) { completion($0) }
    }
    
    /// Get the disruption counts for a given airline
    /// - Parameters:
    ///   - code: The ICAO or IATA for a give Airline
    ///   - timePeriod: The time period of the counts
    ///   - maxPages: The max number of pages returned
    /// - Returns: An object containing the disruption count information
    public func disruptionCounts(
        airline code: String,
        timePeriod: DisruptionCountTimePeriod! = .today,
        maxPages: Int! = 1
    ) async throws -> DisruptionCountResponse {
        return try await self.request(
            DisruptionCountsRequest(
                type: .airline,
                timePeriod: timePeriod,
                maxPages: maxPages
            )
        )
    }
    
    
    /// Get the disruption counts for a given airline
    /// - Parameters:
    ///   - code: The ICAO or IATA for a give Airline
    ///   - timePeriod: The time period of the counts
    ///   - maxPages: The max number of pages returned
    ///   - completion: A result containing the disruption count response or error
    public func disruptionCounts(
        airline code: String,
        timePeriod: DisruptionCountTimePeriod! = .today,
        maxPages: Int! = 1,
        _ completion: @escaping (Result<DisruptionCountResponse, Error>) -> Void
    ) {
        self.request(
            DisruptionCountsRequest(
                type: .airline,
                timePeriod: timePeriod,
                maxPages: maxPages
            )
        ) { completion($0) }
    }
    
    /// Get the disruption counts for a given type
    /// - Parameters:
    ///   - type: The airline, origin or destination request
    ///   - timePeriod: The time period of the counts
    ///   - maxPages: The max number of pages returned
    public func disruptionCounts(
        type: DisruptionCountType! = .origin,
        timePeriod: DisruptionCountTimePeriod! = .today,
        maxPages: Int! = 1
    ) async throws -> DisruptionCountResponse {
        return try await self.request(
            DisruptionCountsRequest(
                type: type,
                timePeriod: timePeriod,
                maxPages: maxPages
            )
        )
    }
    
    /// Get the disruption counts for a given type
    /// - Parameters:
    ///   - type: The airline, origin or destination request
    ///   - timePeriod: The time period of the counts
    ///   - maxPages: The max number of pages returned
    ///   - completion: A result closure that contains disruption count information
    public func disruptionCounts(
        type: DisruptionCountType! = .origin,
        timePeriod: DisruptionCountTimePeriod! = .today,
        maxPages: Int! = 1,
        _ completion: @escaping (Result<DisruptionCountResponse, Error>) -> Void
    ) {
        self.request(
            DisruptionCountsRequest(
                type: type,
                timePeriod: timePeriod,
                maxPages: maxPages
            )
        ) { completion($0) }
    }
}
