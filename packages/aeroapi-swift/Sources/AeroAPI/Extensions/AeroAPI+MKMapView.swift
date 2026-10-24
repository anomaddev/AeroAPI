//
//  AeroAPI+MKMapView.swift
//
//
//  Created by Justin Ackermann on 11/27/23.
//

import Foundation
import CoreLocation
import MapKit

extension MKMapView {
    public func coordBounds() -> MapBounds  {
        let rect = visibleMapRect
        let nwPoint = MKMapPoint(x: rect.origin.x, y: rect.origin.y)
        let nePoint = MKMapPoint(x: rect.maxX, y: rect.origin.y)
        let sePoint = MKMapPoint(x: rect.maxX, y: rect.maxY)
        let swPoint = MKMapPoint(x: rect.origin.x, y: rect.maxY)
        
        return MapBounds(
            NWCoord: nwPoint.coordinate,
            NECoord: nePoint.coordinate,
            SECoord: sePoint.coordinate,
            SWCoord: swPoint.coordinate
        )
    }
}

public struct MapBounds {
    
    public let NWCoord: CLLocationCoordinate2D
    public let NECoord: CLLocationCoordinate2D
    public let SECoord: CLLocationCoordinate2D
    public let SWCoord: CLLocationCoordinate2D
    
}
