//
//  KeyboardKey.swift
//  BluetoothKitDemo
//
//  Created by hukaiyin on 2025/3/18.
//

import Foundation

@objc public
enum KeyboardKey: UInt8, Sendable {
    case Reserved               = 0x00 // Reserved (no event indicated)
    case errorRollOver          = 0x01 // ErrorRollOver
    case postFail               = 0x02 // POSTFail
    case errorUndefined         = 0x03 // ErrorUndefined
    
    case a                      = 0x04 // a and A
    case b                      = 0x05 // b and B
    case c                      = 0x06 // c and C
    case d                      = 0x07 // d and D
    case e                      = 0x08 // e and E
    case f                      = 0x09 // f and F
    case g                      = 0x0A // g and G
    case h                      = 0x0B // h and H
    case i                      = 0x0C // i and I
    case j                      = 0x0D // j and J
    case k                      = 0x0E // k and K
    case l                      = 0x0F // l and L
    case m                      = 0x10 // m and M
    case n                      = 0x11 // n and N
    case o                      = 0x12 // o and O
    case p                      = 0x13 // p and P
    case q                      = 0x14 // q and Q
    case r                      = 0x15 // r and R
    case s                      = 0x16 // s and S
    case t                      = 0x17 // t and T
    case u                      = 0x18 // u and U
    case v                      = 0x19 // v and V
    case w                      = 0x1A // w and W
    case x                      = 0x1B // x and X
    case y                      = 0x1C // y and Y
    case z                      = 0x1D // z and Z
    
    case number1                = 0x1E // 1 and !
    case number2                = 0x1F // 2 and @
    case number3                = 0x20 // 3 and #
    case number4                = 0x21 // 4 and $
    case number5                = 0x22 // 5 and %
    case number6                = 0x23 // 6 and ^
    case number7                = 0x24 // 7 and &
    case number8                = 0x25 // 8 and *
    case number9                = 0x26 // 9 and (
    case number10               = 0x27 // 0 and )
    
    
    
    case enter                  = 0x28 // Return (ENTER)
    case escape                 = 0x29 // ESCAPE
    case backspace              = 0x2A // DELETE (Backspace)
    case tab                    = 0x2B // Tab
    case spacebar               = 0x2C // Spacebar
    case minus                  = 0x2D // - and _
    case equal                  = 0x2E // = and +
    case bracketLeft            = 0x2F // [ and {
    case bracketRight           = 0x30 // ] and }
    case backslash              = 0x31 // \ and |
    
    case semicolon              = 0x33 // ; and :
    case apostrophe             = 0x34 // ‘ and “
    case graveAccent            = 0x35 // Grave Accent and Tilde
    case comma                  = 0x36 // , and <
    case period                 = 0x37 // . and >
    case slash                  = 0x38 // / and ?
    case capsLock               = 0x39 // Caps Lock
    
    case f1                     = 0x3A // F1
    case f2                     = 0x3B // F2
    case f3                     = 0x3C // F3
    case f4                     = 0x3D // F4
    case f5                     = 0x3E // F5
    case f6                     = 0x3F // F6
    case f7                     = 0x40 // F7
    case f8                     = 0x41 // F8
    case f9                     = 0x42 // F9
    case f10                    = 0x43 // F10
    case f11                    = 0x44 // F11
    case f12                    = 0x45 // F12
    
    case printScreen            = 0x46 // PrintScreen
    case scrollLock             = 0x47 // Scroll Lock
    case pause                  = 0x48 // Pause
    case insert                 = 0x49 // Insert
    case home                   = 0x4A // Home
    case pageUp                 = 0x4B // PageUp
    case deleteForward          = 0x4C // Delete Forward
    case end                    = 0x4D // End
    case pageDown               = 0x4E // PageDown
    
    case rightArrow             = 0x4F // RightArrow
    case leftArrow              = 0x50 // LeftArrow
    case downArrow              = 0x51 // DownArrow
    case upArrow                = 0x52 // UpArrow

    case numLock                = 0x53 // Keypad Num Lock and Clear
    case keypadDivide           = 0x54 // Keypad /
    case keypadMultiply         = 0x55 // Keypad *
    case keypadMinus            = 0x56 // Keypad -
    case keypadPlus             = 0x57 // Keypad +
    case keypadEnter            = 0x58 // Keypad ENTER
    
    
    case keypad1                = 0x59 // Keypad 1 and End
    case keypad2                = 0x5A // Keypad 2 and Down Arrow
    case keypad3                = 0x5B // Keypad 3 and PageDn
    case keypad4                = 0x5C // Keypad 4 and Left Arrow
    case keypad5                = 0x5D // Keypad 5
    case keypad6                = 0x5E // Keypad 6 and Right Arrow
    case keypad7                = 0x5F // Keypad 7 and Home
    case keypad8                = 0x60 // Keypad 8 and Up Arrow
    case keypad9                = 0x61 // Keypad 9 and PageUp
    case keypad0                = 0x62 // Keypad 0 and Insert
    
    
    case keypadPeriod           = 0x63 // Keypad . and Delete
    case nonUSBackslash         = 0x64 // Non-US \ and |
    case application            = 0x65 // Application
    case power                  = 0x66 // Power
    case keypadEqual            = 0x67 // Keypad =
    
    case f13                    = 0x68 // F13
    case f14                    = 0x69 // F14
    case f15                    = 0x6A // F15
    case f16                    = 0x6B // F16
    case f17                    = 0x6C // F17
    case f18                    = 0x6D // F18
    case f19                    = 0x6E // F19
    case f20                    = 0x6F // F20
    case f21                    = 0x70 // F21
    case f22                    = 0x71 // F22
    case f23                    = 0x72 // F23
    case f24                    = 0x73 // F24
    
    case execute                = 0x74 // Execute
    case help                   = 0x75 // Help
    case menu                   = 0x76 // Menu
    case select                 = 0x77 // Select
    case stop                   = 0x78 // Stop
    case again                  = 0x79 // Again
    case undo                   = 0x7A // Undo
    case cut                    = 0x7B // Cut
    case copy                   = 0x7C // Copy
    case paste                  = 0x7D // Paste
    case find                   = 0x7E // Find
    case mute                   = 0x7F // Mute
    
    case volumeUp               = 0x80 // Volume Up
    case volumeDown             = 0x81 // Volume Down
    
    case lockingCapsLock        = 0x82 // Locking Caps Lock
    case lockingNumLock         = 0x83 // Locking Num Lock
    case lockingScrollLock      = 0x84 // Locking Scroll Lock
    case keypadComma            = 0x85 // Keypad Comma
    case keypadEqualSign        = 0x86 // Keypad Equal Sign
    
    case international1         = 0x87 // International1
    case international2         = 0x88 // International2
    case international3         = 0x89 // International3
    case international4         = 0x8A // International4
    case international5         = 0x8B // International5
    case international6         = 0x8C // International6
    case international7         = 0x8D // International7
    case international8         = 0x8E // International8
    case international9         = 0x8F // International9
    
    case lang1                  = 0x90 // LANG1
    case lang2                  = 0x91 // LANG2
    case lang3                  = 0x92 // LANG3
    case lang4                  = 0x93 // LANG4
    case lang5                  = 0x94 // LANG5
    case lang6                  = 0x95 // LANG6
    case lang7                  = 0x96 // LANG7
    case lang8                  = 0x97 // LANG8
    case lang9                  = 0x98 // LANG9
    
    case alternateErase         = 0x99 // Alternate Erase
    case sysReqAttention        = 0x9A // SysReq/Attention
    
    
    case cancel                 = 0x9B // Cancel
    case clear                  = 0x9C // Clear
    case prior                  = 0x9D // Prior
    case returnKey              = 0x9E // Return
    case separator              = 0x9F // Separator
    case out                    = 0xA0 // Out
    case oper                   = 0xA1 // Oper
    case clearAgain             = 0xA2 // Clear/Again
    case crSelProps             = 0xA3 // CrSel/Props
    case exSel                  = 0xA4 // ExSel

    // 0xA5 - 0xCF Reserved (跳过)

    // Keypad 数字 & 符号键
    case keypad00               = 0xB0 // Keypad 00
    case keypad000              = 0xB1 // Keypad 000
    case thousandsSeparator     = 0xB2 // Thousands Separator
    case decimalSeparator       = 0xB3 // Decimal Separator
    case currencyUnit           = 0xB4 // Currency Unit
    case currencySubUnit        = 0xB5 // Currency Sub-unit
    case keypadLeftParen        = 0xB6 // Keypad (
    case keypadRightParen       = 0xB7 // Keypad )
    case keypadLeftBrace        = 0xB8 // Keypad {
    case keypadRightBrace       = 0xB9 // Keypad }
    case keypadTab              = 0xBA // Keypad Tab
    case keypadBackspace        = 0xBB // Keypad Backspace
    
    case keypadA                = 0xBC // Keypad A
    case keypadB                = 0xBD // Keypad B
    case keypadC                = 0xBE // Keypad C
    case keypadD                = 0xBF // Keypad D
    case keypadE                = 0xC0 // Keypad E
    case keypadF                = 0xC1 // Keypad F
    
    case keypadXOR              = 0xC2 // Keypad XOR
    case keypadCaret            = 0xC3 // Keypad ^ (Caret)
    case keypadPercent          = 0xC4 // Keypad %
    case keypadLessThan         = 0xC5 // Keypad <
    case keypadGreaterThan      = 0xC6 // Keypad >
    case keypadAmpersand        = 0xC7 // Keypad &
    case keypadDoubleAnd        = 0xC8 // Keypad &&
    case keypadPipe             = 0xC9 // Keypad |
    case keypadDoublePipe       = 0xCA // Keypad ||
    case keypadColon            = 0xCB // Keypad :
    case keypadHash             = 0xCC // Keypad #
    case keypadSpace            = 0xCD // Keypad Space
    case keypadAt               = 0xCE // Keypad @
    case keypadExclamation      = 0xCF // Keypad !

    case keypadMemoryStore      = 0xD0 // Keypad Memory Store
    case keypadMemoryRecall     = 0xD1 // Keypad Memory Recall
    case keypadMemoryClear      = 0xD2 // Keypad Memory Clear
    case keypadMemoryAdd        = 0xD3 // Keypad Memory Add
    case keypadMemorySubtract   = 0xD4 // Keypad Memory Subtract
    case keypadMemoryMultiply   = 0xD5 // Keypad Memory Multiply
    case keypadMemoryDivide     = 0xD6 // Keypad Memory Divide
    case keypadPlusMinus        = 0xD7 // Keypad +/-
    case keypadClear            = 0xD8 // Keypad Clear
    case keypadClearEntry       = 0xD9 // Keypad Clear Entry
    case keypadBinary           = 0xDA // Keypad Binary
    case keypadOctal            = 0xDB // Keypad Octal
    case keypadDecimal          = 0xDC // Keypad Decimal
    case keypadHexadecimal      = 0xDD // Keypad Hexadecimal

    // 0xDE - 0xDF Reserved (跳过)

    // 修饰键
    case leftControl            = 0xE0 // LeftControl
    case leftShift              = 0xE1 // LeftShift
    case leftAlt                = 0xE2 // LeftAlt
    case leftGUI                = 0xE3 // Left GUI
    case rightControl           = 0xE4 // RightControl
    case rightShift             = 0xE5 // RightShift
    case rightAlt               = 0xE6 // RightAlt
    case rightGUI               = 0xE7 // Right GUI
    
    
   public var description: String {
        switch self {

        case .Reserved: return "Reserved (no event indicated)"
        case .errorRollOver: return "ErrorRollOver"
        case .postFail: return "POSTFail"
        case .errorUndefined: return "ErrorUndefined"
        
        case .a: return "A"
        case .b: return "B"
        case .c: return "C"
        case .d: return "D"
        case .e: return "E"
        case .f: return "F"
        case .g: return "G"
        case .h: return "H"
        case .i: return "I"
        case .j: return "J"
        case .k: return "K"
        case .l: return "L"
        case .m: return "M"
        case .n: return "N"
        case .o: return "O"
        case .p: return "P"
        case .q: return "Q"
        case .r: return "R"
        case .s: return "S"
        case .t: return "T"
        case .u: return "U"
        case .v: return "V"
        case .w: return "W"
        case .x: return "X"
        case .y: return "Y"
        case .z: return "Z"

        case .number1: return "1 and !"
        case .number2: return "2 and @"
        case .number3: return "3 and #"
        case .number4: return "4 and $"
        case .number5: return "5 and %"
        case .number6: return "6 and ^"
        case .number7: return "7 and &"
        case .number8: return "8 and *"
        case .number9: return "9 and ("
        case .number10: return "0 and )"
            
        case .enter: return "Return (ENTER)"
        case .escape: return "ESCAPE"
        case .backspace: return "DELETE (Backspace)"
        case .tab: return "Tab"
        case .spacebar: return "Spacebar"
        case .minus: return "- and _"
        case .equal: return "= and +"
        case .bracketLeft: return "[ and {"
        case .bracketRight: return "] and }"
        case .backslash: return "\\ and |"

        case .semicolon: return "; and :"
        case .apostrophe: return "‘ and “"
        case .graveAccent: return "Grave Accent and Tilde"
        case .comma: return ", and <"
        case .period: return ". and >"
        case .slash: return "/ and ?"
        case .capsLock: return "Caps Lock"

        case .f1: return "F1"
        case .f2: return "F2"
        case .f3: return "F3"
        case .f4: return "F4"
        case .f5: return "F5"
        case .f6: return "F6"
        case .f7: return "F7"
        case .f8: return "F8"
        case .f9: return "F9"
        case .f10: return "F10"
        case .f11: return "F11"
        case .f12: return "F12"

        case .printScreen: return "PrintScreen"
        case .scrollLock: return "Scroll Lock"
        case .pause: return "Pause"
        case .insert: return "Insert"
        case .home: return "Home"
        case .pageUp: return "PageUp"
        case .deleteForward: return "Delete Forward"
        case .end: return "End"
        case .pageDown: return "PageDown"

        case .rightArrow: return "RightArrow"
        case .leftArrow: return "LeftArrow"
        case .downArrow: return "DownArrow"
        case .upArrow: return "UpArrow"

        case .numLock: return "Keypad Num Lock and Clear"
        case .keypadDivide: return "Keypad /"
        case .keypadMultiply: return "Keypad *"
        case .keypadMinus: return "Keypad -"
        case .keypadPlus: return "Keypad +"
        case .keypadEnter: return "Keypad ENTER"

        case .keypad1: return "Keypad 1 and End"
        case .keypad2: return "Keypad 2 and Down Arrow"
        case .keypad3: return "Keypad 3 and PageDn"
        case .keypad4: return "Keypad 4 and Left Arrow"
        case .keypad5: return "Keypad 5"
        case .keypad6: return "Keypad 6 and Right Arrow"
        case .keypad7: return "Keypad 7 and Home"
        case .keypad8: return "Keypad 8 and Up Arrow"
        case .keypad9: return "Keypad 9 and PageUp"
        case .keypad0: return "Keypad 0 and Insert"
            
        case .keypadPeriod: return "Keypad . and Delete"
        case .nonUSBackslash: return "Non-US \\ and |"
        case .application: return "Application"
        case .power: return "Power"
        case .keypadEqual: return "Keypad ="

        case .f13: return "F13"
        case .f14: return "F14"
        case .f15: return "F15"
        case .f16: return "F16"
        case .f17: return "F17"
        case .f18: return "F18"
        case .f19: return "F19"
        case .f20: return "F20"
        case .f21: return "F21"
        case .f22: return "F22"
        case .f23: return "F23"
        case .f24: return "F24"

        case .execute: return "Execute"
        case .help: return "Help"
        case .menu: return "Menu"
        case .select: return "Select"
        case .stop: return "Stop"
        case .again: return "Again"
        case .undo: return "Undo"
        case .cut: return "Cut"
        case .copy: return "Copy"
        case .paste: return "Paste"
        case .find: return "Find"
        case .mute: return "Mute"

        case .volumeUp: return "Volume Up"
        case .volumeDown: return "Volume Down"

        case .lockingCapsLock: return "Locking Caps Lock"
        case .lockingNumLock: return "Locking Num Lock"
        case .lockingScrollLock: return "Locking Scroll Lock"
        case .keypadComma: return "Keypad Comma"
        case .keypadEqualSign: return "Keypad Equal Sign"

        case .international1: return "International1"
        case .international2: return "International2"
        case .international3: return "International3"
        case .international4: return "International4"
        case .international5: return "International5"
        case .international6: return "International6"
        case .international7: return "International7"
        case .international8: return "International8"
        case .international9: return "International9"
            
            
        case .lang1: return "LANG1"
        case .lang2: return "LANG2"
        case .lang3: return "LANG3"
        case .lang4: return "LANG4"
        case .lang5: return "LANG5"
        case .lang6: return "LANG6"
        case .lang7: return "LANG7"
        case .lang8: return "LANG8"
        case .lang9: return "LANG9"

        case .alternateErase: return "Alternate Erase"
        case .sysReqAttention: return "SysReq/Attention"

        case .cancel: return "Cancel"
        case .clear: return "Clear"
        case .prior: return "Prior"
        case .returnKey: return "Return"
        case .separator: return "Separator"
        case .out: return "Out"
        case .oper: return "Oper"
        case .clearAgain: return "Clear/Again"
        case .crSelProps: return "CrSel/Props"
        case .exSel: return "ExSel"

        case .keypad00: return "Keypad 00"
        case .keypad000: return "Keypad 000"
        case .thousandsSeparator: return "Thousands Separator"
        case .decimalSeparator: return "Decimal Separator"
        case .currencyUnit: return "Currency Unit"
        case .currencySubUnit: return "Currency Sub-unit"
        case .keypadLeftParen: return "Keypad ("
        case .keypadRightParen: return "Keypad )"
        case .keypadLeftBrace: return "Keypad {"
        case .keypadRightBrace: return "Keypad }"
        case .keypadTab: return "Keypad Tab"
        case .keypadBackspace: return "Keypad Backspace"

        case .keypadA: return "Keypad A"
        case .keypadB: return "Keypad B"
        case .keypadC: return "Keypad C"
        case .keypadD: return "Keypad D"
        case .keypadE: return "Keypad E"
        case .keypadF: return "Keypad F"

        case .keypadXOR: return "Keypad XOR"
        case .keypadCaret: return "Keypad ^"
        case .keypadPercent: return "Keypad %"
        case .keypadLessThan: return "Keypad <"
        case .keypadGreaterThan: return "Keypad >"
        case .keypadAmpersand: return "Keypad &"
        case .keypadDoubleAnd: return "Keypad &&"
        case .keypadPipe: return "Keypad |"
        case .keypadDoublePipe: return "Keypad ||"
        case .keypadColon: return "Keypad :"
        case .keypadHash: return "Keypad #"
        case .keypadSpace: return "Keypad Space"
        case .keypadAt: return "Keypad @"
        case .keypadExclamation: return "Keypad !"
            
        case .keypadMemoryStore: return "Keypad Memory Store"
        case .keypadMemoryRecall: return "Keypad Memory Recall"
        case .keypadMemoryClear: return "Keypad Memory Clear"
        case .keypadMemoryAdd: return "Keypad Memory Add"
        case .keypadMemorySubtract: return "Keypad Memory Subtract"
        case .keypadMemoryMultiply: return "Keypad Memory Multiply"
        case .keypadMemoryDivide: return "Keypad Memory Divide"
        case .keypadPlusMinus: return "Keypad +/-"
        case .keypadClear: return "Keypad Clear"
        case .keypadClearEntry: return "Keypad Clear Entry"
        case .keypadBinary: return "Keypad Binary"
        case .keypadOctal: return "Keypad Octal"
        case .keypadDecimal: return "Keypad Decimal"
        case .keypadHexadecimal: return "Keypad Hexadecimal"

        case .leftControl: return "LeftControl"
        case .leftShift: return "LeftShift"
        case .leftAlt: return "LeftAlt"
        case .leftGUI: return "Left GUI"
        case .rightControl: return "RightControl"
        case .rightShift: return "RightShift"
        case .rightAlt: return "RightAlt"
        case .rightGUI: return "Right GUI"
        }
    }
}
