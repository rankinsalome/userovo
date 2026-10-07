import Foundation
import Darwin

final class MemoryManager {

    static let shared = MemoryManager()

    private init() {}

    private var task: mach_port_t {
        mach_task_self_
    }

    // MARK: - Int32

    func readInt32(at address: UInt64) -> Int32? {
        var value: Int32 = 0
        var dataSize: mach_msg_type_number_t = 0

        let result = withUnsafeMutableBytes(of: &value) { buffer -> kern_return_t in
            guard let pointer = buffer.baseAddress else {
                return KERN_INVALID_ADDRESS
            }

            return vm_read_overwrite(
                task,
                vm_address_t(address),
                vm_size_t(MemoryLayout<Int32>.size),
                vm_address_t(UInt(bitPattern: pointer)),
                &dataSize
            )
        }

        guard result == KERN_SUCCESS,
              dataSize == mach_msg_type_number_t(MemoryLayout<Int32>.size) else {
            return nil
        }

        return value
    }

    func writeInt32(at address: UInt64, value: Int32) -> Bool {
        var value = value

        return withUnsafeBytes(of: &value) { buffer in
            guard let pointer = buffer.baseAddress else {
                return false
            }

            let result = vm_write(
                task,
                vm_address_t(address),
                vm_offset_t(UInt(bitPattern: pointer)),
                mach_msg_type_number_t(MemoryLayout<Int32>.size)
            )

            return result == KERN_SUCCESS
        }
    }

    // MARK: - Float

    func readFloat(at address: UInt64) -> Float? {
        var value: Float = 0
        var dataSize: mach_msg_type_number_t = 0

        let result = withUnsafeMutableBytes(of: &value) { buffer -> kern_return_t in
            guard let pointer = buffer.baseAddress else {
                return KERN_INVALID_ADDRESS
            }

            return vm_read_overwrite(
                task,
                vm_address_t(address),
                vm_size_t(MemoryLayout<Float>.size),
                vm_address_t(UInt(bitPattern: pointer)),
                &dataSize
            )
        }

        guard result == KERN_SUCCESS,
              dataSize == mach_msg_type_number_t(MemoryLayout<Float>.size) else {
            return nil
        }

        return value
    }

    func writeFloat(at address: UInt64, value: Float) -> Bool {
        var value = value

        return withUnsafeBytes(of: &value) { buffer in
            guard let pointer = buffer.baseAddress else {
                return false
            }

            let result = vm_write(
                task,
                vm_address_t(address),
                vm_offset_t(UInt(bitPattern: pointer)),
                mach_msg_type_number_t(MemoryLayout<Float>.size)
            )

            return result == KERN_SUCCESS
        }
    }
}