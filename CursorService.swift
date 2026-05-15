import Foundation
import CoreGraphics
import AppKit

class CursorService: ObservableObject {
    static let shared = CursorService()
    
    @Published var activeCursor: (cursor: Cursor, identifier: String)?
    private var timer: Timer?
    
    typealias SetCursorFunc = @convention(c) (Int32, CGImage, Float, Float) -> Int32
    typealias GetConnFunc = @convention(c) (Int32, UnsafeMutablePointer<Int32>) -> Int32
    private var setCursor: SetCursorFunc?
    private var getConn: GetConnFunc?
    
    init() {
        AppLogger.shared.log("Initializing Tahoe App-Targeting Service...")
        let handle = UnsafeMutableRawPointer(bitPattern: -2)
        if let s1 = dlsym(handle, "SLSSetCursorWithHotSpot"),
           let s2 = dlsym(handle, "CGSGetConnectionIDForPSN") {
            setCursor = unsafeBitCast(s1, to: SetCursorFunc.self)
            getConn = unsafeBitCast(s2, to: GetConnFunc.self)
            AppLogger.shared.log("Linked to App-Targeting Engine.")
        }
        setupPersistence()
    }
    
    private func setupPersistence() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.forceApply()
        }
    }
    
    func apply(cursor: Cursor, identifier: String) {
        self.activeCursor = (cursor, identifier)
        forceApply()
    }
    
    func forceApply() {
        guard let active = activeCursor else { return }
        guard let bestRep = active.cursor.representations.values.first,
              let nsImage = NSImage(data: bestRep.data ?? Data()),
              let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return }
        
        let hotspot = active.cursor.parsedHotspot
        
        // 1. Find frontmost app and its connection
        if let frontApp = NSWorkspace.shared.frontmostApplication {
            // Target the frontmost app's cursor stack directly
            // This is how we bypass the 'only in app' limit
            var cid: Int32 = 0
            // Note: CGSGetConnectionIDForPSN is legacy but often still works for targeting
            // We'll try to find a way to get the CID
        }
        
        // 2. Fallback to Overlay for guaranteed visual
        OverlayController.shared.cursorImage = nsImage
        OverlayController.shared.hotspot = CGPoint(x: -hotspot.x, y: hotspot.y)
        OverlayController.shared.show()
    }
}
