//
//  FlightStatus.swift
//  
//
//  Created by Justin Ackermann on 11/23/22.
//

import Foundation

#if os(iOS)
import UIKit
#endif

// TODO: More detailed status handling

/// The Status of a Flight
public enum FlightStatus: String, Codable, CaseIterable {
    
    #if os(iOS)
    static var base: UIColor = UIColor(
        _colorLiteralRed: 47/255,
        green: 47/255,
        blue: 47/255,
        alpha: 1
    )
    
    static var success: UIColor = UIColor(
        _colorLiteralRed: 13/255,
        green: 165/255,
        blue: 28/255,
        alpha: 1
    )
    
    static var error: UIColor = UIColor(
        _colorLiteralRed: 196/255,
        green: 25/255,
        blue: 48/255,
        alpha: 1
    )

    static var warning: UIColor = UIColor(
        _colorLiteralRed: 225/255,
        green: 145/255,
        blue: 17/255,
        alpha: 1
    )
    
    /// The `FlightStatus` Color
    public var color: UIColor {
        switch self {
        case .Scheduled,
                .Unknown,
                .ResultUnknown:
            return Self.base
            
        case .OnTime,
                .EnrouteOnTime,
                .EnRoute,
                .Taxiing,
                .LandedTaxiing,
                .LeftGate,
                .Arrived,
                .GateArrival:
            return Self.success
            
        case .Delayed,
                .EnrouteDelayed,
                .DelayedArrival,
                .TaxxingDelayed,
                .ScheduledDelay:
            return Self.warning
            
        case .Cancelled,
                .Diverted,
                .ReturnedToGate:
            return Self.error
        }
        
    }
    #endif
    
    /// Diverted
    case Diverted
    
    /// Returned to Gate
    case ReturnedToGate = "Returned to Gate"
    
    /// Arrived
    case Arrived
    
    /// Arrived at Gate
    case GateArrival = "Arrived / Gate Arrival"
    
    /// Delayed Arrival
    case DelayedArrival = "Arrived / Delayed"
    
    /// Left the gate
    case LeftGate = "Left Gate"
    
    /// Taxiing
    case Taxiing = "Taxiing / Left Gate"
    
    /// Taxiing Delayed
    case TaxxingDelayed = "Taxiing / Delayed"
    
    /// Landed and Taxiing
    case LandedTaxiing = "Landed / Taxiing"
    
    /// Inflight and On Time
    case OnTime
    
    /// Inflight and Delayed
    case Delayed
    
    /// Inflight and enroute
    case EnRoute
    
    /// Inflight and enroute on time
    case EnrouteOnTime = "En Route / On Time"
    
    /// Inflight and enroute delayed
    case EnrouteDelayed = "En Route / Delayed"
    
    /// Flight is Scheduled
    case Scheduled
    
    /// Flight status is Unknown
    case Unknown
    
    /// Result is Unknown
    case ResultUnknown = "result unknown"
    
    /// Flight is Cancelled
    case Cancelled
    
    /// Flight has a Scheduled Delay
    case ScheduledDelay = "Scheduled / Delayed"
    
    /// Has the flight arrived
    public var hasArrived: Bool {
        switch self {
        case .GateArrival,
            .DelayedArrival,
            .Arrived: return true
        default: return false
        }
    }
    
    /// Is the flight taxiing
    public var isTaxiing: Bool {
        switch self {
        case .Taxiing,
            .TaxxingDelayed,
            .LandedTaxiing,
            .LeftGate: return true
        default: return false
        }
    }
    
    /// Is the flight inflight
    public var isInflight: Bool {
        switch self {
        case .OnTime,
            .EnRoute,
            .EnrouteOnTime,
            .EnrouteDelayed,
            .Delayed: return true
        default: return false
        }
    }
    
    /// Is the flight delayed
    public var isDelayed: Bool {
        switch self {
        case .Delayed,
            .EnrouteDelayed,
            .DelayedArrival,
            .TaxxingDelayed,
            .ScheduledDelay: return true
        default: return false
        }
    }
    
    /// Has the flight been diverted
    public var hasDiverted: Bool {
        switch self {
        case .Diverted,
            .ReturnedToGate: return true
        default: return false
        }
    }
    
    /// A human readable label for the status
    public var label: String {
        switch self {
        case .Scheduled: return "Scheduled"
            
        case .Arrived,
            .GateArrival,
            .DelayedArrival: return "Arrived"
            
        case .OnTime,
            .EnrouteOnTime,
            .EnRoute: return "On Time"
            
        case .Taxiing,
            .TaxxingDelayed,
            .LeftGate,
            .LandedTaxiing: return "Taxiing"
            
        case .Delayed,
            .EnrouteDelayed,
            .ScheduledDelay: return "Delayed"
            
        case .Cancelled: return "Cancelled"
        case .Diverted: return "Diverted"
        case .ReturnedToGate: return "Return to Gate"
        case .Unknown, .ResultUnknown: return "Status Unknown"
        }
    }
}

