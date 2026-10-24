//
//  Alliance.swift
//  AtlasInFlight
//
//  Created by Justin Ackermann on 8/14/22.
//

// Core iOS
import Foundation

#if os(iOS)
import UIKit
#endif

class Alliance: Codable {
    
    var name: String?
    var code: String?
    var members: String?
    
    #if os(iOS)
    var icon: UIImage?
    { UIImage(named: code?.lowercased() ?? "plane") }
    #endif
    
//    convenience init(_ row: [String]) {
//        self.init()
//        self.name       = row[0]
//        self.code       = row[1]
//        self.members    = row[2]
//    }
}

extension String {
//    var alliance: Alliance? {
//        do {
//            let realm = try Realm()
//            let alliance = realm.objects(Alliance.self)
//            let code = alliance.first { $0.code == self }
//
//            guard let team = code
//            else { throw AtlasError.fall }
//
//            return team
//        } catch { return nil }
//    }
}

