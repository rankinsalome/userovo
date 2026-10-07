import Darwin
import Foundation

enum TargetTaskError: Error {
    case invalidBundleID
    case invalidPID
    case connectionFailed(String)

    var message: String {
        switch self {
        case .invalidBundleID:
            return "请输入 Bundle ID"
        case .invalidPID:
            return "请输入有效 PID"
        case .connectionFailed(let message):
            return "无法连接目标进程：\(message)"
        }
    }
}

final class TargetTaskManager {

    static let shared = TargetTaskManager()

    private init() {}

    private(set) var targetApp: TargetApp?
    private(set) var task: mach_port_t = mach_port_t(MACH_PORT_NULL)
    private(set) var errorMessage: String?

    var isConnected: Bool {
        task != mach_port_t(MACH_PORT_NULL)
    }

    func connect(bundleID: String, pid: Int32) -> Result<TargetApp, TargetTaskError> {
        let normalizedBundleID = bundleID.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !normalizedBundleID.isEmpty else {
            return .failure(.invalidBundleID)
        }

        guard pid > 0 else {
            return .failure(.invalidPID)
        }

        var connectedTask: mach_port_t = mach_port_t(MACH_PORT_NULL)
        let status = task_for_pid(
            mach_task_self_,
            pid,
            &connectedTask
        )

        guard status == KERN_SUCCESS else {
            let message = String(cString: mach_error_string(status))
            errorMessage = message
            return .failure(.connectionFailed(message))
        }

        task = connectedTask
        targetApp = TargetApp(
            bundleID: normalizedBundleID,
            processName: ProcessManager.shared.processName(
                for: normalizedBundleID
            ) ?? "Unknown",
            pid: pid,
            moduleName: "UnityFramework"
        )
        errorMessage = nil

        return .success(targetApp!)
    }

    func disconnect() {
        task = mach_port_t(MACH_PORT_NULL)
        targetApp = nil
        errorMessage = nil
    }
}
