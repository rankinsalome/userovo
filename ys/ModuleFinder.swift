import Foundation

struct ModuleFinder {

    let targetTask: TargetTaskManager

    func moduleBase(named moduleName: String) -> UInt64? {
        guard let target = targetTask.targetApp,
              targetTask.isConnected else {
            return nil
        }

        let normalizedName = moduleName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !normalizedName.isEmpty else {
            return nil
        }

        return target.moduleBase
    }
}
