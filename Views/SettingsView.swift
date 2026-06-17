import SwiftUI

enum SettingsTab: String, CaseIterable, Identifiable {
    case general, downloads, workshop, about
    var id: String { rawValue }
    var title: String {
        switch self {
        case .general: return "通用"
        case .downloads: return "下载"
        case .workshop: return "壁纸引擎"
        case .about: return "关于"
        }
    }
    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .downloads: return "arrow.down.circle"
        case .workshop: return "gearshape.2"
        case .about: return "info.circle"
        }
    }
}

struct SettingsView: View {
    @StateObject var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: SettingsTab = .general
    @ObservedObject private var sourceManager = WorkshopSourceManager.shared
    @ObservedObject private var workshopService = WorkshopService.shared

    // Steam 登录状态
    @State private var steamUsername = ""
    @State private var steamPassword = ""
    @State private var steamGuardCode = ""
    @State private var isSteamPasswordVisible = false
    @State private var showLoginForm = false
    @State private var isVerifyingSteamLogin = false
    @State private var steamLoginStatusText: String?

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider()
            content
        }
        .frame(width: 720, height: 500)
        .onAppear {
            sourceManager.refreshStoredSteamCredentials()
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("设置").font(.system(size: 15, weight: .bold))
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill").font(.system(size: 16)).foregroundStyle(.secondary)
                }.buttonStyle(.plain)
            }
            .padding(.horizontal, 16).padding(.top, 20).padding(.bottom, 12)

            ForEach(SettingsTab.allCases) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: tab.icon).frame(width: 16)
                        Text(tab.title).font(.system(size: 13))
                        Spacer()
                    }
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(selectedTab == tab ? Color.accentColor.opacity(0.15) : Color.clear)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .frame(width: 150)
        .padding(.top, 8)
    }

    @ViewBuilder
    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                switch selectedTab {
                case .general: generalView
                case .downloads: downloadsView
                case .workshop: workshopView
                case .about: aboutView
                }
            }
            .padding(24)
        }
    }

    private var generalView: some View {
        VStack(spacing: 16) {
            GroupBox("通用") {
                Toggle("开机启动", isOn: $viewModel.launchAtLogin).padding(8)
            }
            GroupBox("代理") {
                VStack(spacing: 8) {
                    Toggle("启用 HTTP 代理", isOn: $viewModel.proxyEnabled)
                    if viewModel.proxyEnabled {
                        HStack { Text("地址").frame(width: 50, alignment: .trailing); TextField("127.0.0.1", text: $viewModel.proxyHost).textFieldStyle(.roundedBorder) }
                        HStack { Text("端口").frame(width: 50, alignment: .trailing); TextField("7890", text: $viewModel.proxyPort).textFieldStyle(.roundedBorder) }
                    }
                }.padding(8)
            }
        }
    }

    private var downloadsView: some View {
        GroupBox("下载") {
            Toggle("保存下载到应用库", isOn: $viewModel.saveToDownloads).padding(8)
        }
    }

    private var workshopView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("壁纸引擎设置").font(.system(size: 17, weight: .bold))
            Text("配置 SteamCMD 账号以浏览和下载创意工坊内容").font(.system(size: 11)).foregroundStyle(.secondary)

            Divider()

            // SteamCMD 登录
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "person.badge.key.fill").font(.system(size: 14)).foregroundStyle(.cyan)
                    Text("SteamCMD 账号").font(.system(size: 14, weight: .semibold))
                    Spacer()
                    if case .available = sourceManager.steamCredentialState {
                        Label("已保存", systemImage: "checkmark.circle.fill").font(.system(size: 12)).foregroundStyle(.green)
                    }
                }

                if case .available(let username) = sourceManager.steamCredentialState, !showLoginForm {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("已保存账号：\(username)").font(.system(size: 13)).foregroundStyle(.secondary)
                            Text("下载 Workshop 内容时会自动使用这组凭据").font(.system(size: 11)).foregroundStyle(.secondary.opacity(0.8))
                        }
                        Spacer()
                        Button("重新登录") { steamUsername = username; steamPassword = ""; steamGuardCode = ""; steamLoginStatusText = nil; showLoginForm = true }.controlSize(.small)
                        Button("注销") {
                            sourceManager.clearSteamCredentials()
                            steamUsername = ""; steamPassword = ""; steamGuardCode = ""
                            steamLoginStatusText = "已清除已保存账号。"
                            showLoginForm = true
                        }.controlSize(.small)
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.03))
                    .cornerRadius(8)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("请输入 Steam 账号密码来登录 SteamCMD，用于下载创意工坊壁纸。").font(.system(size: 11)).foregroundStyle(.secondary)
                        TextField("Steam 用户名", text: $steamUsername).textFieldStyle(.roundedBorder)
                        HStack {
                            if isSteamPasswordVisible {
                                TextField("密码", text: $steamPassword).textFieldStyle(.roundedBorder)
                            } else {
                                SecureField("密码", text: $steamPassword).textFieldStyle(.roundedBorder)
                            }
                            Button(action: { isSteamPasswordVisible.toggle() }) {
                                Image(systemName: isSteamPasswordVisible ? "eye.fill" : "eye.slash.fill").foregroundStyle(.secondary)
                            }.buttonStyle(.plain)
                        }
                        TextField("Steam 令牌验证码（可选）", text: $steamGuardCode).textFieldStyle(.roundedBorder)
                        Text("如已开启手机令牌，在 Steam App 中确认即可，此项可留空").font(.system(size: 10)).foregroundStyle(.secondary)

                        HStack {
                            if isVerifyingSteamLogin {
                                ProgressView().scaleEffect(0.8)
                                Text("正在验证…").font(.system(size: 11)).foregroundStyle(.secondary)
                            } else if let status = steamLoginStatusText {
                                Text(status).font(.system(size: 11)).foregroundStyle(status.contains("成功") ? .green : .orange)
                            }
                            Spacer()
                            if case .available = sourceManager.steamCredentialState {
                                Button("取消") { showLoginForm = false; steamPassword = ""; steamGuardCode = ""; steamLoginStatusText = nil }.controlSize(.small)
                            }
                            Button("验证并保存") {
                                guard !steamUsername.isEmpty, !steamPassword.isEmpty else { steamLoginStatusText = "请输入用户名和密码"; return }
                                isVerifyingSteamLogin = true; steamLoginStatusText = nil
                                Task {
                                    do {
                                        try await workshopService.verifySteamLogin(username: steamUsername, password: steamPassword, guardCode: steamGuardCode)
                                        sourceManager.setSteamCredentials(username: steamUsername, password: steamPassword, guardCode: steamGuardCode)
                                        await MainActor.run {
                                            steamPassword = ""; steamGuardCode = ""
                                            if case .available = sourceManager.steamCredentialState {
                                                steamLoginStatusText = "✓ 验证成功，已保存到本机。"
                                                showLoginForm = false
                                            }
                                            isVerifyingSteamLogin = false
                                        }
                                    } catch {
                                        await MainActor.run {
                                            steamLoginStatusText = "验证失败：\(error.localizedDescription)"
                                            isVerifyingSteamLogin = false
                                        }
                                    }
                                }
                            }.buttonStyle(.borderedProminent).controlSize(.small).disabled(isVerifyingSteamLogin)
                        }
                    }
                }
            }

            if sourceManager.isSteamAuthenticated {
                Divider()
                Toggle("显示全部 Workshop 内容（含未分类）", isOn: $viewModel.showAllWorkshopContent)
            }
        }
    }

    private var aboutView: some View {
        GroupBox("关于 Hpaper") {
            VStack(alignment: .leading, spacing: 6) {
                Text("Hpaper v1.0.0").font(.system(size: 13))
                Text("基于 Swallpaper-Mac-v3 精简，仅保留壁纸引擎浏览与下载").font(.system(size: 11)).foregroundStyle(.secondary)
            }.padding(8)
        }
    }
}
