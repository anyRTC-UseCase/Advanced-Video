//
//  ARDefaultValue.swift
//  OpenLive
//
//  Created by 余生丶 on 2020/10/16.
//

import UIKit

class ARDefaultValue: NSObject {
    static func setValue(_ value: Any, key: String) {
        UserDefaults.standard.set(value, forKey: key)
    }
    
    static func getStringValueFor(key: String) -> String? {
        return UserDefaults.standard.object(forKey: key) as? String
    }
    
    static func getDicValueFor(key: String) -> [String: Any]? {
        return UserDefaults.standard.object(forKey: key) as? [String: Any]
    }
    
    static func getDicListValueFor(key: String) -> [[String: Any]]? {
        return UserDefaults.standard.object(forKey: key) as? [[String: Any]]
    }
    
    static func getValueFor(key: String) -> Any? {
        return UserDefaults.standard.object(forKey: key)
    }
}
