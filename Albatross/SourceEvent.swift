//
//  SourceEvent.swift
//  Albatross
//
//  Created by Yoshiaki Sugimoto on 2022/01/28.
//

import Foundation
import CoreGraphics

protocol SourceEvent {
    func match(event: CGEvent, type: CGEventType) -> Bool
    func convert(event: CGEvent) -> CGEvent
    func getKeyCode() -> Int64
}

class SimpleSourceEvent: NSObject, SourceEvent {
    public var destination: DestinationEvent
    public var source: KeyEvent
    
    init(src: KeyEvent, dest: DestinationEvent) {
        source = src
        destination = dest
    }
    
    public func getKeyCode() -> Int64 {
        return source.getKeyCode()
    }
    
    public func match(event: CGEvent, type: CGEventType) -> Bool {
        if event.getIntegerValueField(.keyboardEventKeycode) != source.getKeyCode() {
            print("keycode mismatch")
            return false
        }
        
        // When single key shortcut, no need to compare flags
        if source.isSingleKey {
            return true
        }
        
        let flag = source.getFlag()
        
        if (event.flags.rawValue & flag) == 0 {
            print("flag mismatch", event.flags, flag)
            return false
        }
        
        // CGEventFlags comparison is a little complecated.
        // If combination meta keys are specified Ctrl key only (e.g Ctrl+a) or CapsLock key,
        // we don't care of left or right and Control/CapsLock meta flag may be different
        // between builtin keyboard and USB keyboard.
        // That's messy but currently we don't know how to distinguish the input source keyboard in CGEvent.
        // So, we gave up to handle it, just compare Control flag of 16-24 bit.
        //
        // On the other hand, Shift, Option, Command keys have left and right keys
        // so we need to compare with lowest 8 bits to distinguish them.
        if ((event.flags.rawValue & 0xFF) & (flag & 0xFF)) == 0 {
            if (flag >> 16) == 0x04 || (flag >> 16) == 0x01 { // Control or CapsLock comparison
                return true
            }
            print("left/right mismatch")
            return false
        }
        
        return true
    }
    
    public func convert(event: CGEvent) -> CGEvent {
        if destination.isSuppressKeUp() && event.type == CGEventType.keyUp {
            return event
        }
      
        let target = destination.target()
        event.setIntegerValueField(.keyboardEventKeycode, value: target.getKeyCode())
        if target.getFlag() != defaultCGEventFlags {
            event.flags = CGEventFlags(rawValue: (target.getFlag() | defaultCGEventFlags))
        }
        print("converted", event.getIntegerValueField(.keyboardEventKeycode), event.flags)
        
        return event
    }
}

class DoubleSourceEvent: SimpleSourceEvent {
    private let interval: UInt64
    private var timestamp: CGEventTimestamp = 0
    private var isMatched = false
    
    override init(src: KeyEvent, dest: DestinationEvent) {
        self.interval = UInt64(300 * 1000000) // nano seconds
        super.init(src: src, dest: dest)
    }
    
    override func match(event: CGEvent, type: CGEventType) -> Bool {
        if !super.match(event: event, type: type) {
            timestamp = 0
            return false
        }
        if type == CGEventType.keyUp {
            if isMatched {
                isMatched = false
                return true
            }
            return false
        }
        
        if timestamp == 0 {
            timestamp = event.timestamp
            return false
        }
        print("compare", event.timestamp, timestamp, event.timestamp - timestamp)
        if event.timestamp - timestamp < interval {
            timestamp = 0
            isMatched = true
            return true
        }
        timestamp = event.timestamp
        return false
    }
}

func createSourceEvent(alias: Alias, dest: DestinationEvent) -> SourceEvent? {
    let src = KeyEvent()
    let keys = alias.from
    
    if keys.count == 1 {
        src.isSingleKey = true
        if let v = keyCodeMap[keys[0]] {  // swiftlint:disable:this identifier_name
            src.setKeyCode(code: v.0, isShift: v.1)
        }
        if alias.double ?? false {
            return DoubleSourceEvent(src: src, dest: dest)
        } else {
            return SimpleSourceEvent(src: src, dest: dest)
        }
    }
    
    for key in keys {
        if let m = metaKeyMap[key] {  // swiftlint:disable:this identifier_name
            src.setMetaKey(flag: m)
        } else if let v = keyCodeMap[key] {  // swiftlint:disable:this identifier_name
            if src.getKeyCode() != unknownKeyCode {
               return nil
            }
            src.setKeyCode(code: v.0, isShift: v.1)
        } else {
            return nil
        }
    }
    
    if alias.double ?? false {
        return DoubleSourceEvent(src: src, dest: dest)
    } else {
        return SimpleSourceEvent(src: src, dest: dest)
    }
}
