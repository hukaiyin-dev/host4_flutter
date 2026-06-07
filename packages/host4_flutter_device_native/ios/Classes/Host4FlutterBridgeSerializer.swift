import Foundation
import GMacroProtocolSDK

enum Host4FlutterBridgeSerializer {
  static func payload(_ payload: [String: Any]) -> [String: Any] {
    var result: [String: Any] = [:]
    for (key, value) in payload {
      result[key] = serializableValue(value)
    }
    return result
  }

  static func serializableValue(_ value: Any) -> Any {
    switch value {
    case let bool as Bool:
      return bool

    case let int as Int:
      return int

    case let double as Double:
      return double

    case let float as Float:
      return Double(float)

    case let string as String:
      return string

    case let number as NSNumber:
      return number

    case let key as GamepadKey:
      return key.rawValue

    case let keys as [GamepadKey]:
      return keys.map { $0.rawValue }

    case let type as MappingType:
      return Int(type.rawValue)

    case let types as [MappingType]:
      return types.map { Int($0.rawValue) }

    case let mode as MotionMappingMode:
      return Int(mode.rawValue)

    case let modes as [MotionMappingMode]:
      return modes.map { Int($0.rawValue) }

    case let mode as MotionTriggerMode:
      return Int(mode.rawValue)

    case let mode as GyroMappingType:
      return Int(mode.rawValue)

    case let axis as GyroAxis:
      return Int(axis.rawValue)

    case let graphics as OutputGraphics:
      return Int(graphics.rawValue)

    case let triggerMode as CurveTriggerMode:
      return Int(triggerMode.rawValue)

    case let position as VibrationPosition:
      return Int(position.rawValue)

    case let cycle as CycleMode:
      return Int(cycle.rawValue)

    case let mode as TurboMode:
      return Int(mode.rawValue)

    case let mouseKey as MouseKey:
      return Int(mouseKey.rawValue)

    case let keyboardKey as KeyboardKey:
      return Int(keyboardKey.rawValue)

    case let mediaKey as MediaKey:
      return Int(mediaKey.rawValue)

    case let modifierKey as ModifierKey:
      return Int(modifierKey.rawValue)

    case let mapping as GamepadKeyMapping:
      return gamepadKeyMappingMap(mapping)

    case let mappings as [GamepadKeyMapping]:
      return mappings.map(gamepadKeyMappingMap)

    case let mapping as MouseKeyMapping:
      return mouseKeyMappingMap(mapping)

    case let mappings as [MouseKeyMapping]:
      return mappings.map(mouseKeyMappingMap)

    case let mapping as KeyboardKeyMapping:
      return keyboardKeyMappingMap(mapping)

    case let mappings as [KeyboardKeyMapping]:
      return mappings.map(keyboardKeyMappingMap)

    case let mappedKey as MappedKey:
      return mappedKeyMap(mappedKey)

    case let mappedKeys as [MappedKey]:
      return mappedKeys.map(mappedKeyMap)

    case let mapping as GamepadKeyMappingBridge:
      return [
        "original": mapping.original,
        "mapped": mapping.mapped,
      ]

    case let mapping as MouseKeyMappingBridge:
      return [
        "original": mapping.original,
        "mapped": mapping.mapped,
      ]

    case let mapping as KeyboardKeyMappingBridge:
      return [
        "original": mapping.original,
        "mapped": mapping.mapped,
      ]

    case let mappedKey as MappedKeyBridge:
      return [
        "type": mappedKey.type,
        "values": mappedKey.values,
      ]

    case let mappedKeys as [MappedKeyBridge]:
      return mappedKeys.map {
        [
          "type": $0.type,
          "values": $0.values,
        ]
      }

    case let macroComKey as MacroComkeyBridge:
      return [
        "keys": macroComKey.keys.map { $0.intValue },
        "keepTime": macroComKey.keepTime,
        "intervalTime": macroComKey.intervalTime,
      ]

    case let macroComKeys as [MacroComkeyBridge]:
      return macroComKeys.map {
        [
          "keys": $0.keys.map { $0.intValue },
          "keepTime": $0.keepTime,
          "intervalTime": $0.intervalTime,
        ]
      }

    case let macroComkeys as [MacroComkey]:
      return macroComkeys.map {
        [
          "keys": $0.keys.map { $0.rawValue },
          "keepTime": $0.keepTime,
          "intervalTime": $0.intervalTime,
        ]
      }

    case let macroKey as MacroKeyBridge:
      return [
        "value": macroKey.value?.intValue as Any,
        "cycle": Int(macroKey.cycle.rawValue),
        "intervalTime": macroKey.intervalTime,
        "comKeys": serializableValue(macroKey.comKeys as Any),
      ]

    case let macroKeys as [MacroKey]:
      return macroKeys.map {
        [
          "value": $0.value.rawValue,
          "cycle": Int($0.cycle.rawValue),
          "intervalTime": $0.intervalTime,
          "comKeys": serializableValue($0.comKeys),
        ]
      }

    case let position as LightPosition:
      return Int(position.rawValue)

    case let positions as [LightPosition]:
      return positions.map { Int($0.rawValue) }

    case let mode as LightMajorMode:
      return Int(mode.rawValue)

    case let modes as [LightMajorMode]:
      return modes.map { Int($0.rawValue) }

    case let subMode as LightSubMode:
      return subMode.rawValue

    case let subModes as [LightSubMode]:
      return subModes.map(\.rawValue)

    case let dict as [String: Any]:
      return payload(dict)

    case let array as [Any]:
      return array.map(serializableValue)

    default:
      return String(describing: value)
    }
  }

  private static func gamepadKeyMappingMap(_ mapping: GamepadKeyMapping) -> [String: Any] {
    [
      "original": mapping.original.rawValue,
      "mapped": mapping.mapped.rawValue,
    ]
  }

  private static func mouseKeyMappingMap(_ mapping: MouseKeyMapping) -> [String: Any] {
    [
      "original": mapping.original.rawValue,
      "mapped": Int(mapping.mapped.rawValue),
    ]
  }

  private static func keyboardKeyMappingMap(_ mapping: KeyboardKeyMapping) -> [String: Any] {
    [
      "original": mapping.original.rawValue,
      "mapped": Int(mapping.mapped.rawValue),
    ]
  }

  private static func mappedKeyMap(_ mappedKey: MappedKey) -> [String: Any] {
    [
      "type": mappedKey.type.rawValue,
      "values": mappedKey.values,
    ]
  }
}