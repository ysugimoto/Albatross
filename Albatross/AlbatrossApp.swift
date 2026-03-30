//
//  AlbatrossApp.swift
//  Albatross
//
//  Created by Yoshiaki Sugimoto on 2022/01/18.
//

import SwiftUI

func print(items: Any..., separator: String = " ", terminator: String = "\n") {
    #if __DEBUG__
        Swift.print(items[0], separator: separator, terminator: terminator)
    #endif
}

@main
struct AlbatrossApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
   
    var body: some Scene {
        Settings {
            EmptyView()
        }
        .defaultLaunchBehavior(.suppressed)
        .restorationBehavior(.disabled)
    }
}

func appVersion() -> String {
    if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
       let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String {
        let padding = build.count < 3 ? String(repeating: "0", count: 3 - build.count) : ""
        
        return "\(version)-\(padding)\(build)"
    }
    return "Unknown"
}
