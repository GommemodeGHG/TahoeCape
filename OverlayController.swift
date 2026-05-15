import SwiftUI
import AppKit

class OverlayController: ObservableObject {
    static let shared = OverlayController()
    
    private var window: NSWindow?
    
    @Published var cursorImage: NSImage?
    @Published var hotspot: CGPoint = .zero
    @Published var mouseLocation: CGPoint = .zero
    
    init() {
        setupWindow()
        startTracking()
    }
    
    private func setupWindow() {
        let screenRect = NSScreen.main?.frame ?? .zero
        let window = NSWindow(
            contentRect: screenRect,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .statusBar
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        
        let rootView = CursorOverlayView(controller: self)
        let hostingView = NSHostingView(rootView: rootView)
        window.contentView = hostingView
        
        self.window = window
    }
    
    func show() {
        DispatchQueue.main.async {
            self.window?.orderFrontRegardless()
            self.hideSystemCursor()
        }
    }
    
    func hide() {
        DispatchQueue.main.async {
            self.window?.orderOut(nil)
            self.restoreSystemCursor()
        }
    }
    
    private func hideSystemCursor() {
        // Create a 1x1 transparent image
        let transparentImage = NSImage(size: NSSize(width: 1, height: 1))
        transparentImage.lockFocus()
        NSColor.clear.set()
        NSRect(x: 0, y: 0, width: 1, height: 1).fill()
        transparentImage.unlockFocus()
        
        let transparentCursor = NSCursor(image: transparentImage, hotSpot: NSPoint(x: 0, y: 0))
        transparentCursor.set()
        
        // Force it globally if possible
        if transparentCursor.responds(to: Selector(("_setGlobal:"))) {
            transparentCursor.perform(Selector(("_setGlobal:")), with: true)
        }
        
        // Lower level CoreGraphics hide
        CGDisplayHideCursor(CGMainDisplayID())
    }
    
    private func restoreSystemCursor() {
        CGDisplayShowCursor(CGMainDisplayID())
        NSCursor.unhide()
    }
    
    private func startTracking() {
        NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged]) { [weak self] event in
            self?.mouseLocation = NSEvent.mouseLocation
        }
        
        NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged]) { [weak self] event in
            self?.mouseLocation = NSEvent.mouseLocation
            return event
        }
        
        Timer.scheduledTimer(withTimeInterval: 0.008, repeats: true) { [weak self] _ in
            let loc = NSEvent.mouseLocation
            if self?.mouseLocation != loc {
                self?.mouseLocation = loc
            }
        }
    }
}

struct CursorOverlayView: View {
    @ObservedObject var controller: OverlayController
    
    var body: some View {
        GeometryReader { geo in
            if let image = controller.cursorImage {
                Image(nsImage: image)
                    .resizable()
                    .frame(width: image.size.width, height: image.size.height)
                    .position(
                        x: controller.mouseLocation.x,
                        y: geo.size.height - controller.mouseLocation.y
                    )
                    .offset(x: controller.hotspot.x, y: controller.hotspot.y)
            }
        }
    }
}
