import Foundation

struct PointerChainResolver {

    let moduleBase: UInt64
    let offsets: [UInt64]

    var addresses: [UInt64] {
        var current = moduleBase
        var addresses = [current]

        for offset in offsets {
            current = current &+ offset
            addresses.append(current)
        }

        return addresses
    }

    var finalAddress: UInt64 {
        addresses.last ?? moduleBase
    }

    var expression: String {
        guard !offsets.isEmpty else {
            return Self.hex(moduleBase)
        }

        let first = Self.hex(moduleBase)
        let chain = addresses.dropFirst().enumerated().map { index, _ in
            let previous = addresses[index]
            let offset = offsets[index]
            return "[\(Self.hex(previous))] + \(Self.hex(offset))"
        }

        return ([first] + chain).joined(separator: " → ")
    }

    static func parseHex(_ string: String) -> UInt64? {
        let value = string
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !value.isEmpty else {
            return nil
        }

        let normalized = value.lowercased().hasPrefix("0x")
            ? String(value.dropFirst(2))
            : value

        return UInt64(normalized, radix: 16)
    }

    static func hex(_ value: UInt64) -> String {
        String(format: "0x%llX", value)
    }
}
