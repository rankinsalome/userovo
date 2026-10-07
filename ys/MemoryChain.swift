import Foundation

struct MemoryChain {
    var moduleName: String
    var offsets: [UInt64]
    var valueType: ValueType

    enum ValueType: String, CaseIterable, Identifiable {
        case int32 = "Int32"
        case float = "Float"

        var id: String { rawValue }
    }

    static let defaultChain = MemoryChain(
        moduleName: "UnityFramework",
        offsets: [
            0x1355AC68,
            0xB8,
            0x1AC
        ],
        valueType: .int32
    )
}