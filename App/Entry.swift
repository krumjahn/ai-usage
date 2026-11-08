import AppKit
import Combine
import SwiftUI

@main struct LedgerApp: App {
    @NSApplicationDelegateAdaptor(LedgerDelegate.self) var delegate
    var body: some Scene { Settings { EmptyView() } }
}

@MainActor final class LedgerDelegate: NSObject, NSApplicationDelegate {
    private var item: NSStatusItem?
    private let popover = NSPopover()
    private let model = LedgerModel()
    private let menuNavigation = DashboardNavigation()
    private let windowNavigation = DashboardNavigation()
    private var dashboard: NSWindow?
    private var statusSubscription: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard NSClassFromString("XCTestCase") == nil,
              ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else { return }
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.item = item
        item.button?.font = .monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .medium)
        item.button?.imagePosition = .imageLeading
        statusSubscription = Publishers.CombineLatest4(model.$today, model.collector.$paused,
                                                        model.collector.$status, model.$problem)
            .sink { [weak self] today, paused, status, problem in
                let presentation = AttentionMenuBarPresentation(seconds: today.ai, paused: paused,
                                                                 status: status, problem: problem)
                guard let button = self?.item?.button else { return }
                button.title = presentation.title
                button.image = presentation.symbolName.flatMap {
                    NSImage(systemSymbolName: $0, accessibilityDescription: nil)
                }
                button.toolTip = presentation.detail
                button.setAccessibilityLabel(presentation.detail)
            }
        item.button?.target = self
        item.button?.action = #selector(toggle)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: MenuBarUI(model: model, collector: model.collector, nav: menuNavigation))
        model.start()
        if CommandLine.arguments.contains("--dashboard") { showDashboard() }
    }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showDashboard()
        return true
    }
    private func showDashboard() {
        windowNavigation.openDashboard()
        if dashboard == nil {
            let view = MenuBarUI(model: model, collector: model.collector, nav: windowNavigation)
            let window = NSWindow(contentViewController: NSHostingController(rootView: view))
            window.title = "AI Usage"
            window.styleMask = [.titled, .closable]
            window.isReleasedWhenClosed = false
            window.center()
            dashboard = window
        }
        model.refresh()
        NSApp.activate(ignoringOtherApps: true)
        dashboard?.makeKeyAndOrderFront(nil)
    }
    @objc func toggle() {
        guard let button = item?.button else { return }
        if popover.isShown { popover.performClose(nil); return }
        menuNavigation.openDashboard()
        model.refresh()
        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
    }
    func applicationWillTerminate(_ notification: Notification) { model.flush() }
}
