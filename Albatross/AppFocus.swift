//
//  AppFocus.swift
//  Albatross
//
//  Created by Yoshiaki Sugimoto on 2024/08/25.
//

import Foundation

class AppFocus: NSObject {
    private var config: AppConfig
    
    init(config: AppConfig) {
        self.config = config
    }
    
    public func updateConfig(config: AppConfig) {
        self.config = config
    }
    
    public func getFocusConfig() -> [Int64: String] {
        var focusMap: [Int64: String] = [:]
        
        for f in config.getFocusConfig() {
            if let key = keyCodeMap[f.key] {
                focusMap[key.0] = f.app
            }
        }
        return focusMap
    }
}
