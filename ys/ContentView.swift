import SwiftUI

struct ContentView: View {

    @State private var bundleID = ""
    @State private var moduleName = "UnityFramework"

    @State private var offset1 = "0x1355AC68"
    @State private var offset2 = "0xB8"
    @State private var offset3 = "0x1AC"

    @State private var status = "等待识别"
    @State private var moduleBase = "未获取"

    @State private var slotAddress = "未计算"
    @State private var staticDataAddress = "未计算"
    @State private var gearAddress = "未计算"

    @State private var gearValue: Int32?

    var body: some View {
        NavigationStack {
            Form {

                Section("目标 App") {
                    TextField(
                        "com.example.app",
                        text: $bundleID
                    )
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                    TextField(
                        "模块",
                        text: $moduleName
                    )
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                    Button("识别目标") {
                        identifyTarget()
                    }
                }

                Section("目标状态") {
                    HStack {
                        Text("状态")

                        Spacer()

                        Text(status)
                            .foregroundStyle(
                                status == "已找到"
                                ? .green
                                : .secondary
                            )
                    }

                    HStack {
                        Text("UnityFramework 基址")

                        Spacer()

                        Text(moduleBase)
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }

                Section("地址链") {

                    AddressRow(
                        title: "slot",
                        expression: "\(moduleName) + \(offset1)",
                        result: slotAddress
                    )

                    AddressRow(
                        title: "staticData",
                        expression: "[slot] + \(offset2)",
                        result: staticDataAddress
                    )

                    AddressRow(
                        title: "档位",
                        expression: "[staticData] + \(offset3)",
                        result: gearAddress
                    )
                }

                Section("偏移配置") {

                    OffsetField(
                        title: "第一层",
                        text: $offset1
                    )

                    OffsetField(
                        title: "第二层",
                        text: $offset2
                    )

                    OffsetField(
                        title: "第三层",
                        text: $offset3
                    )
                }

                Section("结果") {

                    HStack {
                        Text("Int32")

                        Spacer()

                        Text(
                            gearValue.map(String.init) ?? "未读取"
                        )
                        .font(.system(.body, design: .monospaced))
                    }

                    HStack {
                        Text("档位")

                        Spacer()

                        Text(
                            gearValue == 0
                            ? "近景"
                            : gearValue == 1
                            ? "标准"
                            : "未读取"
                        )
                        .fontWeight(.semibold)
                    }
                }
            }
            .navigationTitle("ys Memory")
        }
    }

    private func identifyTarget() {
        guard !bundleID.trimmingCharacters(in: .whitespaces).isEmpty else {
            status = "请输入 Bundle ID"
            return
        }

        status = "等待目标 App 调试接口"

        moduleBase = "未获取"
        slotAddress = "未计算"
        staticDataAddress = "未计算"
        gearAddress = "未计算"
        gearValue = nil
    }
}

struct AddressRow: View {

    let title: String
    let expression: String
    let result: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {

            HStack {
                Text(title)
                    .fontWeight(.medium)

                Spacer()

                Text(result)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            Text(expression)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
        }
    }
}

struct OffsetField: View {

    let title: String
    @Binding var text: String

    var body: some View {
        HStack {
            Text(title)

            Spacer()

            TextField("0x0", text: $text)
                .multilineTextAlignment(.trailing)
                .font(.system(.body, design: .monospaced))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
    }
}