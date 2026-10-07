import SwiftUI

struct ContentView: View {
    
    @State private var processName = ""
    @State private var pid = ""
    
    @State private var address = ""
    @State private var value = ""
    @State private var type = "Int32"
    @State private var result = ""
    
    private let memory = MemoryManager.shared
    
    var body: some View {
        NavigationStack {
            Form {
                
                Section("当前进程") {
                    HStack {
                        Text(processName.isEmpty ? "读取中..." : processName)
                        Spacer()
                        Text("PID \(pid)")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("内存地址") {
                    TextField("例如 0x12345678", text: $address)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    Picker("类型", selection: $type) {
                        Text("Int32").tag("Int32")
                        Text("Float").tag("Float")
                    }
                }
                
                Section("操作") {
                    Button("读取") {
                        readMemory()
                    }
                    
                    HStack {
                        TextField("写入值", text: $value)
                            .keyboardType(.numbersAndPunctuation)
                        
                        Button("写入") {
                            writeMemory()
                        }
                    }
                }
                
                Section("结果") {
                    Text(result.isEmpty ? "暂无结果" : result)
                        .textSelection(.enabled)
                }
            }
            .navigationTitle("ys Memory")
            .onAppear {
                loadProcess()
            }
        }
    }
    
    private func loadProcess() {
        let process = ProcessManager.shared.currentProcess()
        processName = process.name
        pid = String(process.pid)
    }
    
    private func parseAddress() -> UInt64? {
        var text = address
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        if text.lowercased().hasPrefix("0x") {
            text.removeFirst(2)
        }
        
        return UInt64(text, radix: 16)
    }
    
    private func readMemory() {
        guard let addr = parseAddress() else {
            result = "地址格式错误"
            return
        }
        
        switch type {
        case "Int32":
            if let value = memory.readInt32(at: addr) {
                result = "读取成功：\(value)"
            } else {
                result = "读取失败"
            }
            
        case "Float":
            if let value = memory.readFloat(at: addr) {
                result = "读取成功：\(value)"
            } else {
                result = "读取失败"
            }
            
        default:
            result = "未知类型"
        }
    }
    
    private func writeMemory() {
        guard let addr = parseAddress() else {
            result = "地址格式错误"
            return
        }
        
        switch type {
        case "Int32":
            guard let number = Int32(value) else {
                result = "Int32 数值格式错误"
                return
            }
            
            result = memory.writeInt32(at: addr, value: number)
                ? "写入成功"
                : "写入失败"
            
        case "Float":
            guard let number = Float(value) else {
                result = "Float 数值格式错误"
                return
            }
            
            result = memory.writeFloat(at: addr, value: number)
                ? "写入成功"
                : "写入失败"
            
        default:
            result = "未知类型"
        }
    }
}