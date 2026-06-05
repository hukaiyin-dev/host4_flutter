import Foundation

/// 字节缓冲区 — Little Endian 序列化/反序列化
class ByteBuf {
  private var buffer = Data(capacity: 1024)
  private var writePos = 0
  private var readPos = 0

  /// 空缓冲区初始化
  init() {}

  /// 从已有数据初始化（用于解析）
  init(data: Data) {
    buffer = data
    writePos = data.count
    readPos = 0
  }

  /// 获取已写入的数据
  var bytes: Data { buffer.prefix(writePos) }

  // MARK: - 写入

  @discardableResult
  func putShort(_ value: Int16) -> Self {
    var le = value.littleEndian
    withUnsafeBytes(of: &le) { buffer.append(contentsOf: $0) }
    writePos += 2
    return self
  }

  @discardableResult
  func putInt(_ value: Int32) -> Self {
    var le = value.littleEndian
    withUnsafeBytes(of: &le) { buffer.append(contentsOf: $0) }
    writePos += 4
    return self
  }

  @discardableResult
  func putLong(_ value: Int64) -> Self {
    var le = value.littleEndian
    withUnsafeBytes(of: &le) { buffer.append(contentsOf: $0) }
    writePos += 8
    return self
  }

  @discardableResult
  func putBytes(_ data: Data) -> Self {
    putShort(Int16(data.count))
    buffer.append(data)
    writePos += data.count
    return self
  }

  @discardableResult
  func putString(_ value: String) -> Self {
    putBytes(Data(value.utf8))
  }

  @discardableResult
  func putIntMap(_ map: [Int: Int]) -> Self {
    putShort(Int16(map.count))
    for key in map.keys.sorted() {
      putShort(Int16(key))
      putInt(Int32(map[key] ?? 0))
    }
    return self
  }

  // MARK: - 读取

  func readShort() -> Int16 {
    guard readPos + 2 <= buffer.count else { return 0 }
    let value = buffer.withUnsafeBytes { ptr in
      ptr.load(fromByteOffset: readPos, as: Int16.self).littleEndian
    }
    readPos += 2
    return value
  }

  func readInt() -> Int32 {
    guard readPos + 4 <= buffer.count else { return 0 }
    let value = buffer.withUnsafeBytes { ptr in
      ptr.load(fromByteOffset: readPos, as: Int32.self).littleEndian
    }
    readPos += 4
    return value
  }

  func readBytes() -> Data {
    let length = Int(readShort())
    guard length > 0, readPos + length <= buffer.count else { return Data() }
    let data = buffer.subdata(in: readPos..<readPos + length)
    readPos += length
    return data
  }

  func readString() -> String {
    String(data: readBytes(), encoding: .utf8) ?? ""
  }

  func readIntMap() -> [Int: Int] {
    let count = Int(readShort())
    var map: [Int: Int] = [:]
    for _ in 0..<count {
      let key = Int(readShort())
      let value = Int(readInt())
      map[key] = value
    }
    return map
  }
}
