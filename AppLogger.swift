import Foundation
import Combine

class AppLogger: ObservableObject {
    static let shared = AppLogger()
    @Published var logs: [String] = []
    
    func log(_ message: String) {
        DispatchQueue.main.async {
            self.logs.append("[\(Date().formatted(date: .omitted, time: .standard))] \(message)")
            if self.logs.count > 50 { self.logs.removeFirst() }
        }
    }
}
