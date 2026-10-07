import Foundation

struct ProcessInfoItem: Identifiable {
    let id = UUID()
    let name: String
    let pid: Int32
}

final class ProcessManager {
    
    static let shared = ProcessManager()
    
    private init() {}
    
    func currentProcess() -> ProcessInfoItem {
        ProcessInfoItem(
            name: ProcessInfo.processInfo.processName,
            pid: Int32(ProcessInfo.processInfo.processIdentifier)
        )
    }
}