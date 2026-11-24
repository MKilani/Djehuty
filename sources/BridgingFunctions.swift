//
//  BridgingFunctions.swift
//  Djehuty
//
//  Created by Leo Liu on 5/11/24.
//

import Foundation

protocol DataSizeable {
  // swiftlint:disable:next identifier_name
  var data_size: Int32 { get set }
}

extension RimeContext_stdbool: DataSizeable {}
extension RimeTraits: DataSizeable {}
extension RimeCommit: DataSizeable {}
extension RimeStatus_stdbool: DataSizeable {}
extension RimeModule: DataSizeable {}

extension DataSizeable {
  static func rimeStructInit() -> Self {
    let valuePointer = UnsafeMutablePointer<Self>.allocate(capacity: 1)
    memset(valuePointer, 0, MemoryLayout<Self>.size)
    var value = valuePointer.move()
    valuePointer.deallocate()
    let offset = MemoryLayout.size(ofValue: \Self.data_size)
    value.data_size = Int32(MemoryLayout<Self>.size - offset)
    return value
  }

  mutating func setCString(_ swiftString: String, to keypath: WritableKeyPath<Self, UnsafePointer<CChar>?>) {
    swiftString.withCString { cStr in
      // Rime traits keep C string pointers after this closure returns.
      let mutableCStr = strdup(cStr)
      if let existing = self[keyPath: keypath] {
        free(UnsafeMutableRawPointer(mutating: existing))
      }
      self[keyPath: keypath] = UnsafePointer(mutableCStr)
    }
  }
}

infix operator ?= : AssignmentPrecedence
// swiftlint:disable:next operator_whitespace
func ?=<T>(left: inout T, right: T?) {
  if let right = right {
    left = right
  }
}
// swiftlint:disable:next operator_whitespace
func ?=<T>(left: inout T?, right: T?) {
  if let right = right {
    left = right
  }
}

extension NSRange {
  static let empty = NSRange(location: NSNotFound, length: 0)
}

extension NSPoint {
  static func += (lhs: inout Self, rhs: Self) {
    lhs.x += rhs.x
    lhs.y += rhs.y
  }
  static func - (lhs: Self, rhs: Self) -> Self {
    Self.init(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
  }
  static func -= (lhs: inout Self, rhs: Self) {
    lhs.x -= rhs.x
    lhs.y -= rhs.y
  }
  static func * (lhs: Self, rhs: CGFloat) -> Self {
    Self.init(x: lhs.x * rhs, y: lhs.y * rhs)
  }
  static func / (lhs: Self, rhs: CGFloat) -> Self {
    Self.init(x: lhs.x / rhs, y: lhs.y / rhs)
  }
  var length: CGFloat {
    sqrt(pow(self.x, 2) + pow(self.y, 2))
  }
}

// MARK: - macOS 12 compatible text helpers (Swift Regex and String.ranges(of:) need macOS 13)

extension NSRegularExpression {
  /// Capture groups of the first match (index 0 is the whole match), or nil.
  /// With `wholeString`, the pattern must match the entire string.
  static func captures(_ pattern: String, in text: String, wholeString: Bool = false) -> [String]? {
    let source = wholeString ? "^(?:" + pattern + ")$" : pattern
    guard let regex = try? NSRegularExpression(pattern: source),
          let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else { return nil }
    return (0..<match.numberOfRanges).map { index in
      let range = match.range(at: index)
      guard range.location != NSNotFound, let swiftRange = Range(range, in: text) else { return "" }
      return String(text[swiftRange])
    }
  }

  /// UTF-16 range of the first match of `pattern` in `text`, or nil.
  static func firstRange(of pattern: String, in text: String) -> NSRange? {
    guard let regex = try? NSRegularExpression(pattern: pattern),
          let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else { return nil }
    return match.range
  }
}

extension String {
  /// All non-overlapping ranges of `target`, in order.
  func allRanges(of target: String) -> [Range<String.Index>] {
    guard !target.isEmpty else { return [] }
    var result: [Range<String.Index>] = []
    var start = startIndex
    while start < endIndex, let found = range(of: target, range: start..<endIndex) {
      result.append(found)
      start = found.upperBound
    }
    return result
  }
}
