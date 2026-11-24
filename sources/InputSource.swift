//
//  InputSource.swift
//  Djehuty
//
//  Created by Leo Liu on 5/10/24.
//

import Foundation
import CoreText
import InputMethodKit

final class SquirrelInstaller {
  /// Input modes declared in Info.plist, in manifest order (the first one is primary).
  /// They are generated from input-methods.json by package/generate_input_methods.py,
  /// so this code does not change when input methods are added.
  static let declaredModes: [(id: String, schema: String)] = {
    guard let modes = Bundle.main.object(forInfoDictionaryKey: "ComponentInputModeDict") as? [String: Any],
          let list = modes["tsInputModeListKey"] as? [String: Any],
          let order = modes["tsVisibleInputModeOrderedArrayKey"] as? [String] else { return [] }
    let schemas = Bundle.main.object(forInfoDictionaryKey: "DjehutyInputMethodSchemas") as? [String: String] ?? [:]
    return order.compactMap { id in
      list[id] == nil ? nil : (id: id, schema: schemas[id] ?? "")
    }
  }()

  static var modeIDs: [String] { declaredModes.map { $0.id } }

  static var primaryModeID: String? { modeIDs.first }

  /// The Rime schema an input mode should use, or nil if the mode has none.
  static func schemaID(forMode modeID: String) -> String? {
    guard let schema = declaredModes.first(where: { $0.id == modeID })?.schema, !schema.isEmpty else { return nil }
    return schema
  }

  private lazy var inputSources: [String: TISInputSource] = {
    var inputSources = [String: TISInputSource]()
    let sourceList = TISCreateInputSourceList(nil, true).takeRetainedValue() as! [TISInputSource]
    for inputSource in sourceList {
      let sourceIDRef = TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceID)
      guard let sourceID = unsafeBitCast(sourceIDRef, to: CFString?.self) as String? else { continue }
      inputSources[sourceID] = inputSource
    }
    return inputSources
  }()

  func enabledModes() -> [String] {
    var enabled = Set<String>()
    for (mode, inputSource) in getInputSource(modes: Self.modeIDs) {
      if let isEnabled = getBool(for: inputSource, key: kTISPropertyInputSourceIsEnabled), isEnabled {
        enabled.insert(mode)
      }
    }
    return Self.modeIDs.filter { enabled.contains($0) }
  }

  func register() {
    let enabledInputModes = enabledModes()
    if !enabledInputModes.isEmpty {
      print("User already registered Djehuty method(s): \(enabledInputModes)")
      return
    }
    TISRegisterInputSource(SquirrelApp.appDir as CFURL)
    print("Registered input source from \(SquirrelApp.appDir)")
  }

  /// With no modes given, enables every declared mode, unless some are already enabled
  /// (manually enabled modes are preserved).
  func enable(modes: [String] = []) {
    let enabledInputModes = enabledModes()
    if !enabledInputModes.isEmpty && modes.isEmpty {
      print("User already enabled Djehuty method(s): \(enabledInputModes)")
      return
    }
    let modesToEnable = modes.isEmpty ? Self.modeIDs : modes
    for (mode, inputSource) in getInputSource(modes: modesToEnable) {
      if let enabled = getBool(for: inputSource, key: kTISPropertyInputSourceIsEnabled), !enabled {
        let error = TISEnableInputSource(inputSource)
        print("Enable \(error == noErr ? "succeeds" : "fails") for input source: \(mode)")
      }
    }
  }

  func select(mode: String? = nil) {
    guard let modeToSelect = mode ?? Self.primaryModeID else { return }
    let enabledInputModes = enabledModes()
    if !enabledInputModes.contains(modeToSelect) {
      if mode != nil {
        enable(modes: [modeToSelect])
      } else {
        print("Default method not enabled yet: \(modeToSelect)")
        return
      }
    }
    for (mode, inputSource) in getInputSource(modes: [modeToSelect]) {
      if let enabled = getBool(for: inputSource, key: kTISPropertyInputSourceIsEnabled),
         let selectable = getBool(for: inputSource, key: kTISPropertyInputSourceIsSelectCapable),
         let selected = getBool(for: inputSource, key: kTISPropertyInputSourceIsSelected),
         enabled && selectable && !selected {
        let error = TISSelectInputSource(inputSource)
        print("Selection \(error == noErr ? "succeeds" : "fails") for input source: \(mode)")
      } else {
        print("Failed to select \(mode)")
      }
    }
  }

  static func currentInputSourceID() -> String? {
    let source = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
    let idRef = TISGetInputSourceProperty(source, kTISPropertyInputSourceID)
    return unsafeBitCast(idRef, to: CFString?.self) as String?
  }

  /// With no modes given, disables every declared mode.
  func disable(modes: [String] = []) {
    let modesToDisable = modes.isEmpty ? Self.modeIDs : modes
    for (mode, inputSource) in getInputSource(modes: modesToDisable) {
      if let enabled = getBool(for: inputSource, key: kTISPropertyInputSourceIsEnabled), enabled {
        let error = TISDisableInputSource(inputSource)
        print("Disable \(error == noErr ? "succeeds" : "fails") for input source: \(mode)")
      }
    }
  }

  private func getInputSource(modes: [String]) -> [String: TISInputSource] {
    var matchingSources = [String: TISInputSource]()
    for mode in modes {
      if let inputSource = inputSources[mode] {
        matchingSources[mode] = inputSource
      }
    }
    return matchingSources
  }

  private func getBool(for inputSource: TISInputSource, key: CFString!) -> Bool? {
    let enabledRef = TISGetInputSourceProperty(inputSource, key)
    guard let enabled = unsafeBitCast(enabledRef, to: CFBoolean?.self) else { return nil }
    return CFBooleanGetValue(enabled)
  }
}

/// Installs the bundled Egyptian hieroglyph font into /Library/Fonts during installation.
/// A copy that is as new as the bundled one, or newer, is never replaced. Older copies of
/// the same font are removed only when the bundled version is newer than all of them.
enum FontInstaller {
  static let postScriptName = "EgyptianHiero"
  static let fileName = "EgyptianHiero9_03.ttf"
  static let installDirectory = "/Library/Fonts"
  static let searchDirectories = ["/Library/Fonts", "/Library/Fonts/Supplemental"]

  static func bundledFontURL() -> URL {
    Bundle.main.bundleURL.appendingPathComponent("Contents/Resources/fonts/\(fileName)")
  }

  /// The version of the font in `url` (e.g. [8, 1] for "Version 8.01"), or nil if the file
  /// is not a readable font with the expected PostScript name.
  static func version(of url: URL) -> [Int]? {
    guard let descriptors = CTFontManagerCreateFontDescriptorsFromURL(url as CFURL) as? [CTFontDescriptor] else {
      return nil
    }
    for descriptor in descriptors {
      guard let name = CTFontDescriptorCopyAttribute(descriptor, kCTFontNameAttribute) as? String,
            name == postScriptName else { continue }
      let font = CTFontCreateWithFontDescriptor(descriptor, 0, nil)
      guard let versionName = CTFontCopyName(font, kCTFontVersionNameKey) as String?,
            let range = versionName.range(of: #"Version [0-9]+(\.[0-9]+)*"#, options: .regularExpression) else { continue }
      let numbers = versionName[range].split(separator: " ").last.map { $0.split(separator: ".") } ?? []
      let parsed = numbers.compactMap { Int($0) }
      if !parsed.isEmpty { return parsed }
    }
    return nil
  }

  /// True if version `a` is strictly newer than `b`. Missing components count as zero.
  static func isNewer(_ a: [Int], than b: [Int]) -> Bool {
    for i in 0..<max(a.count, b.count) {
      let x = i < a.count ? a[i] : 0
      let y = i < b.count ? b[i] : 0
      if x != y { return x > y }
    }
    return false
  }

  /// Installed copies of this font, with their versions.
  static func installedCopies() -> [(url: URL, version: [Int])] {
    var copies: [(url: URL, version: [Int])] = []
    for directory in searchDirectories {
      let files = (try? FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: directory), includingPropertiesForKeys: nil)) ?? []
      for file in files where ["ttf", "otf", "ttc"].contains(file.pathExtension.lowercased()) {
        if let version = version(of: file) {
          copies.append((url: file, version: version))
        }
      }
    }
    return copies
  }

  static func installIfNewer() {
    let bundled = bundledFontURL()
    guard let bundledVersion = version(of: bundled) else {
      print("Bundled font is missing or unreadable: \(bundled.path)")
      return
    }
    let copies = installedCopies()
    if let newest = copies.map({ $0.version }).max(by: { isNewer($1, than: $0) }),
       !isNewer(bundledVersion, than: newest) {
      print("Keeping installed \(postScriptName) \(newest.map(String.init).joined(separator: ".")); bundled copy is not newer")
      return
    }
    do {
      // remove only the older copies (all of them are older, or we would not be here)
      for copy in copies where isNewer(bundledVersion, than: copy.version) {
        try FileManager.default.removeItem(at: copy.url)
      }
      let destination = URL(fileURLWithPath: installDirectory).appendingPathComponent(fileName)
      if FileManager.default.fileExists(atPath: destination.path) {
        try FileManager.default.removeItem(at: destination)
      }
      try FileManager.default.copyItem(at: bundled, to: destination)
      print("Installed \(postScriptName) \(bundledVersion.map(String.init).joined(separator: ".")) to \(destination.path)")
    } catch {
      print("Font installation failed: \(error.localizedDescription)")
    }
  }
}
