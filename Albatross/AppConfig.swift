//
//  AppConfig.swift
//  Albatross
//
//  Created by Yoshiaki Sugimoto on 2022/01/23.
//

import Foundation
import Yams

struct Config: Codable {
    let remap: [String: String]
    let alias: AliasConfig
    let focus: [Focus]
    
    init() {
        remap = [:]
        alias = AliasConfig.init()
        focus = []
    }
}

struct AliasConfig: Codable {
    let global: [Alias]
    let apps: [AppAlias]
    
    init() {
        global = []
        apps = []
    }
}

struct Alias: Codable {
    let from: [String]
    // swiftlint:disable:next identifier_name
    let to: [String]?
    let toggles: [[String]]?
    var double: Bool?
    
    init() {
        from = []
        to = []
        toggles = []
    }
}

struct AppAlias: Codable {
    let name: String
    var alias: [Alias]
    
    init() {
        name = ""
        alias = []
    }
}

struct Focus: Codable {
    let key: String
    let app: String
    
    init() {
        key = ""
        app = ""
    }
}

enum ConfigError: Error {
    case openFail
    case createFail
    case invalid(String)
}

class AppConfig: NSObject {
    private let filePath: URL
    private var config: Config
    private var fileDescriptor: CInt?
    private var sources: [DispatchSourceFileSystemObject] = []
    private var subscribers: [(AppConfig) -> Void] = []
    
    override init() {
        self.config = Config()
        self.filePath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config")
            .appendingPathComponent("albatross")
            .appendingPathComponent("config")
            .appendingPathExtension("yml")
    }
    
    public func cancel() {
        for source in sources {
            source.cancel()
        }
        // swiftlint:disable:next identifier_name
        if let fd = fileDescriptor {
            close(fd)
        }
        sources = []
        fileDescriptor = nil
    }
    
    public func subscribe(callback: @escaping (AppConfig) -> Void) {
        subscribers.append(callback)
    }
    
    public func getFilePath() -> String {
        return filePath.path
    }
    
    public func getRemap() -> [String: String] {
        return config.remap
    }

    public func getAppAliases(appName: String) -> [Alias] {
        var stack: [String: Alias] = [:]
        
        for alias in config.alias.global {
            stack[alias.from.joined(separator: "")] = alias
        }
        
        for app in config.alias.apps {
            if app.name != appName {
                continue
            }
            for alias in app.alias {
                stack[alias.from.joined(separator: "")] = alias
            }
        }
        
        var aliases: [Alias] = []
        stack.forEach { elem in
            aliases.append(elem.value)
        }
        // return aliases
        return aliases.sorted {
            $0.from.count > $1.from.count
        }
    }
    
    public func getFocusConfig() -> [Focus] {
        return config.focus
    }
    
    public func load() throws {
        if !checkConfigFile() {
            throw ConfigError.createFail
        }
       
        // swiftlint:disable:next identifier_name
        if let fp = FileHandle(forReadingAtPath: filePath.path) {
            let decoder = YAMLDecoder()
            do {
                config = try decoder.decode(Config.self, from: fp.readDataToEndOfFile())
            } catch {
                throw ConfigError.invalid("Invalid Config: " + error.localizedDescription)
            }
        } else {
            throw ConfigError.openFail
        }
    }
    
    public func watch(callback: @escaping (AppConfig) -> Void) {
        let queue = DispatchQueue.global(qos: .default)
        let fd = open(filePath.path, O_EVTONLY)  // swiftlint:disable:this identifier_name
        
        // We need to monitor multiple file change events, .write and .rename because:
        // on Vim, file editing is processed with move (using swap file) so rename event will be fired
        // on other editor (e.g Visual Studio Code), simply write so write event will be fired
        for event in [DispatchSource.FileSystemEvent.write, DispatchSource.FileSystemEvent.rename] {
            let source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fd, eventMask: event, queue: queue)
            source.setEventHandler(handler: { () -> Void in
                // Need a bit delay to reload config after file change event finished
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    do {
                        try self.load()
                        print("Configuration reloaded successfully.")
                        callback(self)
                        self.cancel()
                        self.watch(callback: callback)
                    } catch {
                        AppAlert.display(message: "Configuration did not update because invalid setting")
                    }
                    
                }
            })
            source.activate()
            self.sources.append(source)
        }
       
        self.fileDescriptor = fd
    }
    
    private func checkConfigFile() -> Bool {
        if FileManager.default.fileExists(atPath: filePath.path) {
            return true
        }
        
        // Create app namespace config directory
        do {
            try FileManager.default.createDirectory(
                at: filePath.deletingLastPathComponent(),
                withIntermediateDirectories: true,
                attributes: nil
            )
        } catch {
            return false
        }
            
        // And put initial configuration file from bundle resource
        guard let asset = Bundle.main.url(forResource: "albatross", withExtension: "yml") else {
            return false
        }
        guard let data = try? Data(contentsOf: asset) else {
            return false
        }

        return FileManager.default.createFile(
            atPath: filePath.path,
            contents: data,
            attributes: [
                FileAttributeKey.posixPermissions: 0o644
            ])
    }
}
