//
//  FlightAirport.swift
//  
//
//  Created by Justin Ackermann on 11/23/22.
//

import Foundation

public struct FlightAirport: Codable {
    public var code: String
    public var codeIcao: String?
    public var codeIata: String?
    public var codeLid: String?
    public var airportInfoUrl: String?
    
    public var airport: Airport!
    { code.airport }
}


