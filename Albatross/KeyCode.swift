//
//  KeyCode.swift
//  Albatross
//
//  Created by Yoshiaki Sugimoto on 2022/01/25.
//

import Foundation

let unknownKeyCode: Int64 = -1
let defaultCGEventFlags: UInt64 = 256
let controlKeyCGEventFlags: UInt64 = 262401

let keyCodeMap: [String: (Int64, Bool)] = [
    // Input keys, typically can trap on keyDown/keyUp event
    "a": (0, false), "A": (0, true),
    "b": (11, false), "B": (11, true),
    "c": (8, false), "C": (8, true),
    "d": (2, false), "D": (2, true),
    "e": (14, false), "E": (14, true),
    "f": (3, false), "F": (3, true),
    "g": (5, false), "G": (5, true),
    "h": (4, false), "H": (4, true),
    "i": (34, false), "I": (34, true),
    "j": (38, false), "J": (38, true),
    "k": (40, false), "K": (40, true),
    "l": (37, false), "L": (37, true),
    "m": (46, false), "M": (46, true),
    "n": (45, false), "N": (45, true),
    "o": (31, false), "O": (31, true),
    "p": (35, false), "P": (35, true),
    "q": (12, false), "Q": (12, true),
    "r": (15, false), "R": (15, true),
    "s": (1, false), "S": (1, true),
    "t": (17, false), "T": (17, true),
    "u": (32, false), "U": (32, true),
    "v": (9, false), "V": (9, true),
    "w": (13, false), "W": (13, true),
    "x": (7, false), "X": (7, true),
    "y": (16, false), "Y": (16, true),
    "z": (6, false), "Z": (6, true),
    "1": (18, false), "!": (18, true),
    "2": (19, false), "@": (19, true),
    "3": (20, false), "#": (20, true),
    "4": (21, false), "$": (21, true),
    "5": (23, false), "%": (23, true),
    "6": (22, false), "^": (22, true),
    "7": (26, false), "&": (26, true),
    "8": (28, false), "*": (28, true),
    "9": (25, false), "(": (25, true),
    "0": (29, false), ")": (29, true),
    "-": (27, false), "_": (27, true),
    "=": (24, false), "+": (24, true),
    "\\": (42, false), "|": (42, true),
    "`": (50, false), "~": (50, true),
    "[": (33, false), "{": (33, true),
    "]": (30, false), "}": (30, true),
    ";": (41, false), ":": (41, true),
    "'": (39, false), "\"": (39, true),
    ",": (43, false), "<": (43, true),
    ".": (47, false), ">": (47, true),
    "/": (44, false), "?": (44, true),
    "Esc": (53, false),
    "Tab": (48, false),
    "Delete": (51, false),
    "Return": (36, false),
    "Up": (126, false),
    "Right": (124, false),
    "Down": (125, false),
    "Left": (123, false),
    "Alphabet": (102, false),
    "Kana": (104, false),
    "F1": (122, false),
    "F2": (120, false),
    "F3": (99, false),
    "F4": (118, false),
    "F5": (96, false),
    "F6": (97, false),
    "F7": (98, false),
    "F8": (100, false),
    "F9": (101, false),
    "F10": (109, false),
    "F11": (103, false),
    "F12": (111, false),
    "Ins": (114, false),
    "Del": (117, false),
    "Space": (49, false),
    
    // Meta Keys, could not trap on keyDown event, need trap in flagsChanged event instead
    "Command_L": (54, false),
    "Command_R": (55, false),
    "Option_L": (61, false),
    "Option_R": (58, false),
    "Shift_L": (56, false),
    "Shift_R": (60, false),
    "CapsLock": (57, false),
    "Control": (59, false),
]

/*
Map for CGEventFlags, following value is ignored of default CGEventFlag (256)
 
Implemantation Note:
 Each flag value reporesents:
   - Kind of key in 16-24 bit
   - Fixed value in 8-16 bit
   - Postion related value in 0-8 bit

| Key       | 0-24 bits of value         |
|----------------------------------------|
| Command_L | 00010000|00000001|00010000 |
| Command_R | 00010000|00000001|00001000 |
| Option_L  | 00001000|00000001|01000000 |
| Option_R  | 00001000|00000001|10000100 |
| Shift_L   | 00000010|00000001|00000010 |
| Shift_R   | 00000010|00000001|00000100 |
| CapsLock  | 00000001|00000001|00000000 |
| Control   | 00000100|00000001|00000001 |
 
On the above table, we can detect what kind of meta key is pressed by bitwise operator.
For example:
  - To detect Command key is pressed, compare 16-24 bit e.g ((event.flags.rawValue >> 16) & 0x10) > 0
  - To detect Left Command key is pressed, compare lowest 8 bit e.g ((event.flags.rawValue) & 0x10) > 0

Note that following values are removed 8-16 bits in order to be simplified,
so need to add DEFAULT_CGEVENT_FLAGS for actual use.
See getFlagsForKeyCode() function.
 
```
if let v = metaKeyMap["Command_L"] {
 return v | DEFAULT_CGEVENT_FLAGS
}
```
*/
let metaKeyMap: [String: UInt64] = [
    "Command_L": 0x100010,
    "Command_R": 0x100008,
    "Option_L": 0x080040,
    "Option_R": 0x080120,
    "Shift_L": 0x020002,
    "Shift_R": 0x020004,
    "CapsLock": 0x010000,
    "Control": 0x040000,
]

// Map CGEventFlags for key code
let metaKeyFlgas: [Int64: UInt64] = [
    54: 0x100010,
    55: 0x100008,
    61: 0x080040,
    58: 0x080120,
    56: 0x020002,
    60: 0x020004,
    57: 0x010000,
    59: 0x040000,
    102: 0x000100,
    104: 0x000100,
]

// In source event comparison of upper case character like "A",
// we don't care which shift key is pressed
let bothShiftKeyFlags: UInt64 = 0x020006

func getFlagsForKeyCode(keyCode: Int64) -> UInt64 {
    if let v = metaKeyFlgas[keyCode] {  // swiftlint:disable:this identifier_name
        return v | defaultCGEventFlags
    }
    return defaultCGEventFlags
}

func isMetaKey(_ keyCode: Int64) -> Bool {
    return metaKeyFlgas.keys.contains(keyCode)
}
