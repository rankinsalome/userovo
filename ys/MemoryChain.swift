import Foundation

struct MemoryChain {

    var moduleName: String
    var offsets: [UInt64]
    var valueType: ValueType

    enum ValueType: String, CaseIterable, Identifiable {
        case int32 = "Int32"
        case float = "Float"

        var id: String {
            rawValue
        }
    }

    init(
        moduleName: String = "UnityFramework",
        offsets: [UInt64] = [
            0x1355AC68,
            0xB8,
            0x1AC
        ],
        valueType: ValueType = .int32
    ) {
        self.moduleName = moduleName
        self.offsets = offsets
        self.valueType = valueType
    }

    static let `default` = MemoryChain()

    func expression(base: UInt64) -> String {
        guard !offsets.isEmpty else {
            return String(format: "0x%llX", base)
        }

        var result = String(format: "0x%llX", base)

        for (index, offset) in offsets.enumerated() {
            if index == 0 {
                result += String(format: " + 0x%llX", offset)
            } else {
                result += String(format: " → [previous] + 0x%llX", offset)
            }
        }

        return result
    }
}