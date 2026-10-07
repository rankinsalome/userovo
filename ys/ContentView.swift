import SwiftUI

struct ContentView: View {

    @State private var bundleID = ""

    @State private var moduleName = "UnityFramework"

    @State private var offset1 = "0x1355AC68"
    @State private var offset2 = "0xB8"
    @State private var offset3 = "0x1AC"

    @State private var pidText = ""
    @State private var moduleBaseText = ""
    @State private var selectedProcessID: String?
    @State private var runningProcesses: [ProcessInfoItem] = []

    @State private var status = "未连接"

    @State private var slotAddress = "—"
    @State private var staticDataAddress = "—"
    @State private var gearAddress = "—"

    @State private var gearValue: Int32?

    private var memory: MemoryManager {
        MemoryManager(task: TargetTaskManager.shared.task)
    }

    private var selectedProcess: ProcessInfoItem? {
        runningProcesses.first { $0.id == selectedProcessID }
    }

    var body: some View {
        NavigationStack {
            Form {

                // MARK: Target

                Section("目标 App") {

                    TextField(
                        "Bundle ID",
                        text: $bundleID
                    )
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(.system(.body, design: .monospaced))

                    TextField(
                        "PID",
                        text: $pidText
                    )
                    .keyboardType(.numberPad)
                    .font(.system(.body, design: .monospaced))

                    Button("刷新运行中的应用") {
                        refreshProcesses()
                    }

                    if runningProcesses.isEmpty {
                        Text("正在查找运行中的应用…")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(runningProcesses) { process in
                            Button {
                                selectedProcessID = process.id
                                pidText = String(process.pid)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(process.name)
                                        Text("PID \(process.pid)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    if selectedProcessID == process.id {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.blue)
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    TextField(
                        "模块",
                        text: $moduleName
                    )
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(.system(.body, design: .monospaced))

                    Button("连接目标") {
                        connectTarget()
                    }
                }

                // MARK: Module

                Section("模块") {

                    HStack {
                        Text("状态")

                        Spacer()

                        Text(status)
                            .foregroundStyle(
                                status == "已连接"
                                ? .green
                                : .secondary
                            )
                    }

                    HStack {
                        Text("UnityFramework")

                        Spacer()

                        Text(
                            moduleBaseText.isEmpty
                            ? "—"
                            : moduleBaseText
                        )
                        .font(
                            .system(
                                .body,
                                design: .monospaced
                            )
                        )
                        .foregroundStyle(.secondary)
                    }

                    TextField(
                        "模块基址",
                        text: $moduleBaseText
                    )
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(.system(.body, design: .monospaced))
                    .keyboardType(.numbersAndPunctuation)
                }

                // MARK: Chain

                Section("指针链") {

                    ChainRow(
                        name: "slot",
                        expression:
                            "\(moduleName) + \(offset1)",
                        address: slotAddress
                    )

                    ChainRow(
                        name: "staticData",
                        expression:
                            "[slot] + \(offset2)",
                        address: staticDataAddress
                    )

                    ChainRow(
                        name: "档位",
                        expression:
                            "[staticData] + \(offset3)",
                        address: gearAddress
                    )
                }

                // MARK: Offsets

                Section("偏移") {

                    OffsetRow(
                        title: "Offset 1",
                        text: $offset1
                    )

                    OffsetRow(
                        title: "Offset 2",
                        text: $offset2
                    )

                    OffsetRow(
                        title: "Offset 3",
                        text: $offset3
                    )

                    Button("计算地址链") {
                        calculateChain()
                    }
                }

                // MARK: Value

                Section("Int32") {

                    HStack {
                        Text("当前值")

                        Spacer()

                        Text(
                            gearValue.map(String.init)
                            ?? "—"
                        )
                        .font(
                            .system(
                                .body,
                                design: .monospaced
                            )
                        )
                    }

                    HStack {
                        Text("档位")

                        Spacer()

                        Text(gearName)
                            .fontWeight(.semibold)
                    }
                }

                // MARK: Actions

                Section("操作") {

                    Button("读取") {
                        readValue()
                    }

                    Button("写入 0（近景）") {
                        writeValue(0)
                    }

                    Button("写入 1（标准）") {
                        writeValue(1)
                    }
                }
            }
            .navigationTitle("ys Memory")
        }
    }

    // MARK: - Connection

    private func refreshProcesses() {
        runningProcesses = ProcessManager.shared.runningProcesses()

        if let selected = selectedProcess,
           !runningProcesses.contains(where: { $0.id == selected.id }) {
            selectedProcessID = nil
        }
    }

    private func connectTarget() {
        let selectedBundleID = selectedProcess?.bundleID ?? bundleID

        guard !selectedBundleID.isEmpty else {
            status = "请选择运行中的应用"
            return
        }

        guard let pid = Int32(pidText) else {
            status = "请选择有效 PID"
            return
        }

        let result = TargetTaskManager.shared.connect(
            bundleID: selectedBundleID,
            pid: pid
        )

        switch result {
        case .success:
            status = "已连接"
            calculateChain()
        case .failure(let error):
            status = error.message
        }
    }

    // MARK: - Chain

    private func calculateChain() {
        guard TargetTaskManager.shared.isConnected else {
            status = "请先连接目标"
            return
        }

        guard let base = ModuleFinder(
            targetTask: TargetTaskManager.shared
        ).moduleBase(named: moduleName) ?? PointerChainResolver.parseHex(moduleBaseText),
              let o1 = PointerChainResolver.parseHex(offset1),
              let o2 = PointerChainResolver.parseHex(offset2),
              let o3 = PointerChainResolver.parseHex(offset3)
        else {
            slotAddress = "参数错误"
            staticDataAddress = "—"
            gearAddress = "—"
            return
        }

        let resolver = PointerChainResolver(
            moduleBase: base,
            offsets: [o1, o2, o3]
        )
        let addresses = resolver.addresses

        slotAddress = PointerChainResolver.hex(addresses[1])
        staticDataAddress = "[\(slotAddress)] + \(PointerChainResolver.hex(o2))"
        gearAddress = PointerChainResolver.hex(addresses[3])
    }

    // MARK: - Read

    private func readValue() {

        guard let address = parseHex(gearAddress) else {
            status = "档位地址无效"
            return
        }

        guard let value = memory.readInt32(
            at: address
        ) else {
            status = "读取失败"
            return
        }

        gearValue = value
        status = "读取成功"
    }

    // MARK: - Write

    private func writeValue(_ value: Int32) {

        guard let address = parseHex(gearAddress) else {
            status = "档位地址无效"
            return
        }

        if memory.writeInt32(
            at: address,
            value: value
        ) {
            gearValue = value
            status = "写入成功"
        } else {
            status = "写入失败"
        }
    }

    // MARK: - Helpers

    private var gearName: String {

        switch gearValue {

        case 0:
            return "近景"

        case 1:
            return "标准"

        default:
            return "未知"
        }
    }

    private func parseHex(
        _ string: String
    ) -> UInt64? {

        let value = string
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        if value.lowercased().hasPrefix("0x") {
            return UInt64(
                value.dropFirst(2),
                radix: 16
            )
        }

        return UInt64(value, radix: 16)
    }

    private func hex(
        _ value: UInt64
    ) -> String {

        String(
            format: "0x%llX",
            value
        )
    }
}


// MARK: - Chain Row

struct ChainRow: View {

    let name: String
    let expression: String
    let address: String

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 5
        ) {

            HStack {

                Text(name)
                    .fontWeight(.medium)

                Spacer()

                Text(address)
                    .font(
                        .system(
                            .caption,
                            design: .monospaced
                        )
                    )
                    .foregroundStyle(.secondary)
            }

            Text(expression)
                .font(
                    .system(
                        .caption,
                        design: .monospaced
                    )
                )
                .foregroundStyle(.secondary)
        }
    }
}


// MARK: - Offset Row

struct OffsetRow: View {

    let title: String
    @Binding var text: String

    var body: some View {

        HStack {

            Text(title)

            Spacer()

            TextField(
                "0x0",
                text: $text
            )
            .multilineTextAlignment(.trailing)
            .font(
                .system(
                    .body,
                    design: .monospaced
                )
            )
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
        }
    }
}