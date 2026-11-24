//
//  SquirrelApplicationDelegate.swift
//  Djehuty
//
//  Created by Leo Liu on 5/6/24.
//

import UserNotifications
import Sparkle
import AppKit
import CoreText
import InputMethodKit

final class SquirrelApplicationDelegate: NSObject, NSApplicationDelegate, SPUStandardUserDriverDelegate, UNUserNotificationCenterDelegate {
  static let updateNotificationIdentifier = "DjehutyUpdateNotification"
  static let notificationIdentifier = "DjehutyNotification"

  let rimeAPI: RimeApi_stdbool = rime_get_api_stdbool().pointee
  var config: SquirrelConfig?
  var panel: SquirrelPanel?
  var enableNotifications = false
  var showStatusIcon: Bool = true
  var statusItem: NSStatusItem?
  let updateController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
  var supportsGentleScheduledUpdateReminders: Bool {
    true
  }

  func standardUserDriverWillHandleShowingUpdate(_ handleShowingUpdate: Bool, forUpdate update: SUAppcastItem, state: SPUUserUpdateState) {
    NSApp.setActivationPolicy(.regular)
    if !state.userInitiated {
      NSApp.dockTile.badgeLabel = "1"
      let content = UNMutableNotificationContent()
      content.title = NSLocalizedString("A new update is available", comment: "Update")
      content.body = NSLocalizedString("Version [version] is now available", comment: "Update").replacingOccurrences(of: "[version]", with: update.displayVersionString)
      let request = UNNotificationRequest(identifier: Self.updateNotificationIdentifier, content: content, trigger: nil)
      UNUserNotificationCenter.current().add(request)
    }
  }

  func standardUserDriverDidReceiveUserAttention(forUpdate update: SUAppcastItem) {
    NSApp.dockTile.badgeLabel = ""
    UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [Self.updateNotificationIdentifier])
  }

  func standardUserDriverWillFinishUpdateSession() {
    NSApp.setActivationPolicy(.accessory)
  }

  func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
    if response.notification.request.identifier == Self.updateNotificationIdentifier && response.actionIdentifier == UNNotificationDefaultActionIdentifier {
      updateController.updater.checkForUpdates()
    }

    completionHandler()
  }

  func applicationWillFinishLaunching(_ notification: Notification) {
    panel = SquirrelPanel(position: .zero)
    refreshStatusItem()
    addObservers()
  }

  func applicationWillTerminate(_ notification: Notification) {
    // swiftlint:disable:next notification_center_detachment
    NotificationCenter.default.removeObserver(self)
    DistributedNotificationCenter.default().removeObserver(self)
    panel?.hide()
    if let item = statusItem {
      NSStatusBar.system.removeStatusItem(item)
      statusItem = nil
    }
  }

  func updateStatusIcon(asciiMode: Bool, schemaLabel: String?) {
    DispatchQueue.main.async { [weak self] in
      self?.applyStatusIcon(asciiMode: asciiMode, schemaLabel: schemaLabel)
    }
  }

  func deploy() {
    print("Start maintenance...")
    self.shutdownRime()
    self.startRime(fullCheck: true)
    self.loadSettings()
  }

  func syncUserData() {
    print("Sync user data")
    _ = rimeAPI.sync_user_data()
  }

  func openLogFolder() {
    NSWorkspace.shared.open(SquirrelApp.logDir)
  }

  func openRimeFolder() {
    NSWorkspace.shared.open(SquirrelApp.userDir)
  }

  func checkForUpdates() {
    if updateController.updater.canCheckForUpdates {
      print("Checking for updates")
      updateController.updater.checkForUpdates()
    } else {
      print("Cannot check for updates")
    }
  }

  static func showMessage(msgText: String?) {
    let center = UNUserNotificationCenter.current()
    center.requestAuthorization(options: [.alert, .provisional]) { _, error in
      if let error = error {
        print("User notification authorization error: \(error.localizedDescription)")
      }
    }
    center.getNotificationSettings { settings in
      if (settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional) && settings.alertSetting == .enabled {
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("Djehuty", comment: "")
        if let msgText = msgText {
          content.subtitle = msgText
        }
        content.interruptionLevel = .active
        let request = UNNotificationRequest(identifier: Self.notificationIdentifier, content: content, trigger: nil)
        center.add(request) { error in
          if let error = error {
            print("User notification request error: \(error.localizedDescription)")
          }
        }
      }
    }
  }

  func setupRime() {
    createDirIfNotExist(path: SquirrelApp.userDir)
    createDirIfNotExist(path: SquirrelApp.logDir)
    // Expose the log directory to librime plugins.
    setenv("RIME_LOG_DIR", SquirrelApp.logDir.path, 1)
    // swiftlint:disable identifier_name
    let notification_handler: @convention(c) (UnsafeMutableRawPointer?, RimeSessionId, UnsafePointer<CChar>?, UnsafePointer<CChar>?) -> Void = notificationHandler
    let context_object = Unmanaged.passUnretained(self).toOpaque()
    // swiftlint:enable identifier_name
    rimeAPI.set_notification_handler(notification_handler, context_object)

    var squirrelTraits = RimeTraits.rimeStructInit()
    squirrelTraits.setCString(Bundle.main.sharedSupportPath!, to: \.shared_data_dir)
    squirrelTraits.setCString(SquirrelApp.userDir.path, to: \.user_data_dir)
    squirrelTraits.setCString(SquirrelApp.logDir.path, to: \.log_dir)
    squirrelTraits.setCString("Djehuty", to: \.distribution_code_name)
    squirrelTraits.setCString("Djehuty", to: \.distribution_name)
    squirrelTraits.setCString(Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as! String, to: \.distribution_version)
    squirrelTraits.setCString("rime.djehuty", to: \.app_name)
    rimeAPI.setup(&squirrelTraits)
  }

  /// Makes the hieroglyph font bundled with the app available to this process by name.
  /// Right after installation the system may not know the font yet, and the candidate window
  /// then falls back to another font until the next Deploy.
  func registerBundledFont() {
    let url = Bundle.main.bundleURL.appendingPathComponent("Contents/Resources/fonts/EgyptianHiero9_03.ttf")
    var error: Unmanaged<CFError>?
    if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
      print("Could not register the hieroglyph font: \(url.path)")
    }
  }

  func startRime(fullCheck: Bool) {
    print("Initializing la rime...")
    registerBundledFont()
    rimeAPI.initialize(nil)
    // Rime reuses the compiled build/djehuty.yaml unless it detects a change in its source,
    // and that detection did not reliably happen after an update. Removing the compiled copy
    // makes Rime build it again from the installed djehuty.yaml (the "missing build info" path).
    try? FileManager.default.removeItem(at: SquirrelApp.userDir.appendingPathComponent("build/djehuty.yaml"))
    _ = rimeAPI.start_maintenance(fullCheck)
    // Maintenance runs on a background thread. Wait for it, so that the settings are read only
    // after the compiled files are up to date (loadSettings runs right after this).
    rimeAPI.join_maintenance_thread()
    // Copy the bundled djehuty.yaml into the user folder when its config_version is newer.
    // This must happen on every start: when it was only run after maintenance, a stale copy
    // stayed in place until the user chose Deploy.
    _ = rimeAPI.deploy_config_file("djehuty.yaml", "config_version")
  }

  /// Runs Deploy automatically once for each newly installed version, so the new settings and
  /// fonts apply without the user choosing Deploy. The last deployed version is kept in the
  /// user's defaults.
  func deployOnNewVersion() {
    let current = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
    let defaults = UserDefaults.standard
    guard defaults.string(forKey: "deployedVersion") != current else { return }
    DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
      self?.deploy()
      defaults.set(current, forKey: "deployedVersion")
    }
  }

  func loadSettings() {
    config = SquirrelConfig()
    if !config!.openBaseConfig() {
      return
    }

    enableNotifications = config!.getString("show_notifications_when") != "never"
    showStatusIcon = config!.getBool("status_icon/show") ?? true
    refreshStatusItem()
    if let panel = panel, let config = self.config {
      panel.load(config: config, forDarkMode: false)
      panel.load(config: config, forDarkMode: true)
    }
  }

  func loadSettings(for schemaID: String) {
    if schemaID.count == 0 || schemaID.first == "." {
      return
    }
    let schema = SquirrelConfig()
    if let panel = panel, let config = self.config {
      if schema.open(schemaID: schemaID, baseConfig: config) && schema.has(section: "style") {
        panel.load(config: schema, forDarkMode: false)
        panel.load(config: schema, forDarkMode: true)
      } else {
        panel.load(config: config, forDarkMode: false)
        panel.load(config: config, forDarkMode: true)
      }
    }
    schema.close()
  }

  // Detect repeated launches that may indicate a bad configuration loop.
  func problematicLaunchDetected() -> Bool {
    var detected = false
    let logFile = FileManager.default.temporaryDirectory.appendingPathComponent("djehuty_launch.json", conformingTo: .json)
    do {
      let archive = try Data(contentsOf: logFile, options: [.uncached])
      let decoder = JSONDecoder()
      decoder.dateDecodingStrategy = .millisecondsSince1970
      let previousLaunch = try decoder.decode(Date.self, from: archive)
      if previousLaunch.timeIntervalSinceNow >= -2 {
        detected = true
      }
    } catch let error as NSError where error.domain == NSCocoaErrorDomain && error.code == NSFileReadNoSuchFileError {

    } catch {
      print("Error occurred during processing launch time archive: \(error.localizedDescription)")
      return detected
    }
    do {
      let encoder = JSONEncoder()
      encoder.dateEncodingStrategy = .millisecondsSince1970
      let record = try encoder.encode(Date.now)
      try record.write(to: logFile)
    } catch {
      print("Error occurred during saving launch time to archive: \(error.localizedDescription)")
    }
    return detected
  }

  func addObservers() {
    let center = NSWorkspace.shared.notificationCenter
    center.addObserver(forName: NSWorkspace.willPowerOffNotification, object: nil, queue: nil, using: workspaceWillPowerOff)

    let notifCenter = DistributedNotificationCenter.default()
    notifCenter.addObserver(forName: .init("DjehutyReloadNotification"), object: nil, queue: nil, using: rimeNeedsReload)
    notifCenter.addObserver(forName: .init("DjehutySyncNotification"), object: nil, queue: nil, using: rimeNeedsSync)
    notifCenter.addObserver(forName: .init("DjehutyToggleASCIIModeNotification"), object: nil, queue: nil, using: rimeToggleASCIIMode)
    notifCenter.addObserver(forName: .init("DjehutyGetASCIIModeNotification"), object: nil, queue: nil, using: rimeGetASCIIMode)
    // Suspension behavior matters: the default coalescing holds notifications
    // back while the process is inactive, which is exactly the state Djehuty
    // enters when the user switches away — the icon would fail to hide until
    // the next activation. Deliver immediately instead.
    notifCenter.addObserver(self, selector: #selector(inputSourceChanged(_:)),
                            name: .init(kTISNotifySelectedKeyboardInputSourceChanged as String),
                            object: nil, suspensionBehavior: .deliverImmediately)
  }

  func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
    print("Djehuty is quitting.")
    rimeAPI.cleanup_all_sessions()
    return .terminateNow
  }

}

extension RimeStringSlice {
  /// Bridge the slice's pointer + length to a Swift String, honoring `.length`.
  /// librime clips `.length` to the first Unicode character for abbreviated labels
  /// when no explicit `abbrev:` field is defined, so reading past `.length` (e.g. with
  /// `String(cString:)`) would incorrectly return the full `states:` value.
  var asString: String? {
    guard let ptr = str else { return nil }
    let data = Data(bytes: UnsafeRawPointer(ptr), count: Int(length))
    return String(data: data, encoding: .utf8)
  }
}

// swiftlint:disable:next cyclomatic_complexity
private func notificationHandler(contextObject: UnsafeMutableRawPointer?, sessionId: RimeSessionId, messageTypeC: UnsafePointer<CChar>?, messageValueC: UnsafePointer<CChar>?) {
  let delegate: SquirrelApplicationDelegate = Unmanaged<SquirrelApplicationDelegate>.fromOpaque(contextObject!).takeUnretainedValue()

  let messageType = messageTypeC.map { String(cString: $0) }
  let messageValue = messageValueC.map { String(cString: $0) }

  if messageType == "deploy" {
    switch messageValue {
    case "start":
      SquirrelApplicationDelegate.showMessage(msgText: NSLocalizedString("deploy_start", comment: ""))
    case "success":
      SquirrelApplicationDelegate.showMessage(msgText: NSLocalizedString("deploy_success", comment: ""))
    case "failure":
      SquirrelApplicationDelegate.showMessage(msgText: NSLocalizedString("deploy_failure", comment: ""))
    default:
      break
    }
    return
  } else if messageType == "option" {
    let state = messageValue?.first != "!"
    let optionName: String?
    if state {
      optionName = messageValue
    } else if let value = messageValue {
      optionName = String(value[value.index(after: value.startIndex)...])
    } else {
      optionName = nil
    }
    if let optionName = optionName {
      optionName.withCString { name in
        func shortLabel() -> String? {
          let stateLabelShort = delegate.rimeAPI.get_state_label_abbreviated(sessionId, name, state, true)
          return stateLabelShort.asString
        }
        func longLabel() -> String? {
          let stateLabelLong = delegate.rimeAPI.get_state_label_abbreviated(sessionId, name, state, false)
          return stateLabelLong.asString
        }
        if optionName == "ascii_mode" {
          delegate.updateStatusIcon(asciiMode: state, schemaLabel: shortLabel())
        }
        if delegate.enableNotifications {
          delegate.showStatusMessage(msgTextLong: longLabel(), msgTextShort: shortLabel())
        }
      }
    }
    return
  } else if messageType == "property", let messageValue = messageValue,
            let eqIndex = messageValue.firstIndex(of: "="), messageValue.first == "_" {
    let key = String(messageValue[..<eqIndex])
    let value = String(messageValue[messageValue.index(after: eqIndex)...])
    Task.detached { @MainActor in
      do {
        try delegate.panel?.inputController?.handleReservedProperty(key: key, value: value, for: sessionId)
      } catch {
        print("Error processing handleReservedProperty: \(error)")
      }
    }
    return
  }

  if delegate.enableNotifications {
    if messageType == "schema", let messageValue = messageValue, let schemaName = NSRegularExpression.captures(#"^[^/]*/(.*)$"#, in: messageValue)?[1] {
      delegate.showStatusMessage(msgTextLong: String(schemaName), msgTextShort: String(schemaName))
      return
    }
  }
}

private extension SquirrelApplicationDelegate {
  func showStatusMessage(msgTextLong: String?, msgTextShort: String?) {
    if !(msgTextLong ?? "").isEmpty || !(msgTextShort ?? "").isEmpty {
      panel?.updateStatus(long: msgTextLong ?? "", short: msgTextShort ?? "")
    }
  }

  func refreshStatusItem() {
    if showStatusIcon {
      if statusItem == nil {
        setupStatusItem()
      }
    } else if let item = statusItem {
      NSStatusBar.system.removeStatusItem(item)
      statusItem = nil
    }
  }

  func setupStatusItem() {
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    if let button = item.button {
      button.font = NSFont.systemFont(ofSize: NSFont.systemFontSize, weight: .semibold)
      button.toolTip = NSLocalizedString("Djehuty", comment: "")
    }
    statusItem = item
    applyStatusIcon(asciiMode: false, schemaLabel: nil)
    updateStatusItemVisibility()
  }

  @objc func inputSourceChanged(_: Notification) {
    DispatchQueue.main.async { [weak self] in
      self?.updateStatusItemVisibility()
      self?.finalizeStrandedComposition()
    }
  }

  func updateStatusItemVisibility() {
    guard let statusItem = statusItem else { return }
    let currentInputSourceID = SquirrelInstaller.currentInputSourceID() ?? ""
    statusItem.isVisible = currentInputSourceID.hasPrefix("io.github.mkilani.inputmethod.Djehuty")
  }

  // macOS 26 does not call deactivateServer when the input source is switched
  // away by another process via TISSelectInputSource() (e.g. macism, Input
  // Source Pro): the pending composition is stranded and the candidate panel
  // is left orphaned on screen (#1140). The input-source-changed notification
  // is still delivered, so finalize the composition here as a fallback.
  // Switching via the menu bar calls deactivateServer first, making this a
  // no-op.
  func finalizeStrandedComposition() {
    let currentInputSourceID = SquirrelInstaller.currentInputSourceID() ?? ""
    guard !currentInputSourceID.hasPrefix("io.github.mkilani.inputmethod.Djehuty") else { return }
    if let inputController = panel?.inputController {
      inputController.deactivateServer(inputController.client())
    }
  }

  func applyStatusIcon(asciiMode: Bool, schemaLabel: String?) {
    guard let button = statusItem?.button else { return }
    if let schemaLabel = schemaLabel, !schemaLabel.isEmpty {
      button.title = schemaLabel
    } else {
      button.title = asciiMode ? "A" : "𓄿"
      button.font = NSFont(name: "EgyptianHiero", size: NSFont.systemFontSize) ?? button.font
    }
  }

  func shutdownRime() {
    config?.close()
    rimeAPI.finalize()
  }

  func workspaceWillPowerOff(_: Notification) {
    print("Finalizing before logging out.")
    self.shutdownRime()
  }

  func rimeNeedsReload(_: Notification) {
    print("Reloading rime on demand.")
    self.deploy()
  }

  func rimeNeedsSync(_: Notification) {
    print("Sync rime on demand.")
    self.syncUserData()
  }

  func rimeToggleASCIIMode(_ notification: Notification) {
    guard let mode = notification.object as? String else { return }
    let enableASCII = mode == "ascii"

    if enableASCII {
      NotificationCenter.default.post(name: .init("DjehutySetASCIIModeNotification"), object: true)
    } else {
      NotificationCenter.default.post(name: .init("DjehutySetASCIIModeNotification"), object: false)
    }
  }

  func rimeGetASCIIMode(_: Notification) {
    NotificationCenter.default.post(name: .init("DjehutyReportASCIIModeNotification"), object: nil)
  }

  func createDirIfNotExist(path: URL) {
    let fileManager = FileManager.default
    if !fileManager.fileExists(atPath: path.path) {
      do {
        try fileManager.createDirectory(at: path, withIntermediateDirectories: true)
      } catch {
        print("Error creating user data directory: \(path.path)")
      }
    }
  }
}

extension NSApplication {
  var squirrelAppDelegate: SquirrelApplicationDelegate {
    self.delegate as! SquirrelApplicationDelegate
  }
}
