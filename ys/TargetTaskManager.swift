import Darwin
import Foundation

final class TargetTaskManager {

    static let shared = TargetTaskManager()

    private init() {}

    private(set) var targetApp: TargetApp?
    private(set) var task: mach_port_t = MACH_PORT_NULL
    private(set) var errorMessage: String?

    var isConnected: Bool {
        task != MACH_PORT_NULL
    }

    func connect(bundleID: String, pid: Int32) -> Result<TargetApp, String> {
        let normalizedBundleID = bundleID.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !normalizedBundleID.isEmpty else {
            return .failure("请输入 Bundle ID")
        }

        guard pid > 0 else {
            return .failure("请输入有效 PID")
        }

        var connectedTask: mach_port_t = MACH_PORT_NULL
        let status = task_for_pid(
            mach_task_self_,
            pid,
            &connectedTask
        )

        guard status == KERN_SUCCESS else {
            errorMessage = String(cString: mach_error_string(status))
            return .failure("无法连接目标进程：\(errorMessage ?? "未知错误")")
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
        task = MACH_PORT_NULL
        targetApp = nil
        errorMessage = nil
    }
}
