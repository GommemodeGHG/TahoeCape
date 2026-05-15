import SwiftUI
import ApplicationServices

class PermissionManager: ObservableObject {
    @Published var isAccessibilityAllowed: Bool = false
    
    init() {
        checkAccessibility()
    }
    
    func checkAccessibility() {
        isAccessibilityAllowed = AXIsProcessTrusted()
    }
    
    func requestAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        // Polling for change (simulated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.checkAccessibility()
        }
    }
}
