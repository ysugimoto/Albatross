//
//  KeyboardObserver.swift
//  Albatross
//
//  Created by Yoshiaki Sugimoto on 2022/01/18.
//

import Cocoa

enum KeyboardOberserError: Error {
    case startFail
}

class KeyboardObserver: NSObject {
    private let alias: KeyAlias
    private let focus: AppFocus
    private var isPaused: Bool = false
    private var isControl: Bool = false
    
    init(alias: KeyAlias, focus: AppFocus) {
        self.alias = alias
        self.focus = focus
    }
    
    public func pause() {
        isPaused = true
    }
    
    public func resume() {
        isPaused = false
    }
    
    public func start() throws {
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(
                (1 << CGEventType.keyUp.rawValue) |
                (1 << CGEventType.keyDown.rawValue) |
                (1 << CGEventType.flagsChanged.rawValue)
            ),
            callback: { (_: CGEventTapProxy, type: CGEventType, event: CGEvent, ref: UnsafeMutableRawPointer?
            ) -> Unmanaged<CGEvent>? in
                // If event refernece comes from our observer handle it
                if let observer = ref {
                    let this = Unmanaged<KeyboardObserver>.fromOpaque(observer).takeUnretainedValue()
                    
                    // If remapping is paused, do nothing
                    if this.isPaused {
                        return Unmanaged.passUnretained(event)
                    }
                    // Handle key remap event
                    return this.handleEvent(event: event, type: type)
                }
                return Unmanaged.passUnretained(event)
            },
            userInfo: UnsafeMutableRawPointer(Unmanaged.passRetained(self).toOpaque())
        ) else {
            throw KeyboardOberserError.startFail
        }
        
        CFRunLoopAddSource(
            CFRunLoopGetCurrent(),
            CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0),
            .commonModes
        )
        CGEvent.tapEnable(tap: tap, enable: true)
        CFRunLoopRun()
    }
    
    private func handleEvent(event: CGEvent, type: CGEventType) -> Unmanaged<CGEvent> {
        switch type {
        case CGEventType.keyDown:
            print("keydown", event.getIntegerValueField(.keyboardEventKeycode), event.flags)
            if isControl {
                tryFocus(event: event)
            }
            if let converted = convertEvent(event: event, type: type) {
                let keyCode = converted.getIntegerValueField(.keyboardEventKeycode)
                if isMetaKey(keyCode) {
                    postEmuratedEvent(keyCode: keyCode)
                    return Unmanaged.passUnretained(event)
                }
                return Unmanaged.passUnretained(converted)
            }
        case CGEventType.keyUp:
            print("keyup", event.getIntegerValueField(.keyboardEventKeycode), event.flags)
            if let converted = convertEvent(event: event, type: type) {
                let keyCode = converted.getIntegerValueField(.keyboardEventKeycode)
                if isMetaKey(keyCode) {
                    postEmuratedEvent(keyCode: keyCode)
                    return Unmanaged.passUnretained(event)
                }
                return Unmanaged.passUnretained(converted)
            }
        case CGEventType.flagsChanged:
            print("meta", event.getIntegerValueField(.keyboardEventKeycode), event.flags)
            
            // If meta key is pressed, we should handle in this case but we need to consider combination key remapping.
            // On combination key remapping, it should be handled in keyDown and keyUp case
            // so this case treats single metaKey is pressed and handle only keyUp case
            if event.flags.rawValue != defaultCGEventFlags {
                if let converted = convertEvent(event: event, type: CGEventType.flagsChanged) {
                    // If metakey event is converted, need to emurate keyDown/keyUp event to tap
                    postEmuratedEvent(keyCode: converted.getIntegerValueField(.keyboardEventKeycode))
                    return Unmanaged.passUnretained(event)
                }
                if event.flags.rawValue == controlKeyCGEventFlags {
                    isControl = true
                }
            } else {
                isControl = false
            }
        default:
            break
        }
        return Unmanaged.passUnretained(event)
    }
    
    private func convertEvent(event: CGEvent, type: CGEventType) -> CGEvent? {
        let aliases = alias.getAliases()
        print(aliases, event.getIntegerValueField(.keyboardEventKeycode))
        
        if let sources = aliases[event.getIntegerValueField(.keyboardEventKeycode)] {
            print(sources)
            for source in sources {
                if source.match(event: event, type: type) {
                    return source.convert(event: event)
                }
            }
        }
        return nil
    }
    
    private func postEmuratedEvent(keyCode: Int64) {
        let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(keyCode), keyDown: true)!
        let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(keyCode), keyDown: false)!

        keyDown.flags = CGEventFlags(rawValue: getFlagsForKeyCode(keyCode: keyCode))
        keyUp.flags = CGEventFlags(rawValue: defaultCGEventFlags)
        
        keyDown.post(tap: CGEventTapLocation.cghidEventTap)
        keyUp.post(tap: CGEventTapLocation.cghidEventTap)
    }
    
    private func tryFocus(event: CGEvent) {
        let focuses = focus.getFocusConfig()
        
        if let appName = focuses[event.getIntegerValueField(.keyboardEventKeycode)] {
            print("Focus app", appName)
            let workspace = NSWorkspace.shared
            let apps = workspace.runningApplications
            
            for app in apps {
                if let name = app.localizedName {
                    if name == appName {
                        app.activate(options: .activateIgnoringOtherApps)
                    }
                }
            }
        }
        
    }
}
