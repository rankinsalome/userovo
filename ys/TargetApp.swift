import Foundation

struct TargetApp {
    var bundleID: String = ""
    var moduleName: String = "UnityFramework"
    var moduleBase: UInt64 = 0

    var offsets: [UInt64] = [
        0x1355AC68,
        0xB8,
        0x1AC
    ]

    var value: Int32?

    var gearName: String {
        switch value {
        case 0:
            return "近景"
        case 1:
            return "标准"
        default:
            return value.map(String.init) ?? "未读取"
        }
    }
}