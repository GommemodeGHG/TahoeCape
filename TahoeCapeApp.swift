import SwiftUI
import AppKit

@main
struct TahoeCapeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        
        // Tahoe Special: Try to force global cursor hiding via presentation options
        NSApp.presentationOptions = [.autoHideMenuBar, .autoHideDock]
        // This is a bit extreme, let's try something else first.
        
        // Re-apply the hidden state periodically
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if CursorService.shared.activeCursor != nil {
                NSCursor.hide()
            }
        }
    }
    
    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "cursorarrow.rays", accessibilityDescription: "TahoeCape")
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show TahoeCape", action: #selector(showApp), keyEquivalent: "s"))
        menu.addItem(NSMenuItem(title: "Reset Cursor", action: #selector(resetCursor), keyEquivalent: "r"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem?.menu = menu
    }
    
    @objc func resetCursor() {
        CursorService.shared.reset()
    }
    
    @objc func quitApp() {
        CursorService.shared.reset()
        NSApplication.shared.terminate(nil)
    }
    
    @objc func showApp() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.windows.first?.makeKeyAndOrderFront(nil)
    }
}
