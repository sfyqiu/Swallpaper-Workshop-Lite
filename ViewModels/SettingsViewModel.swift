import SwiftUI
import ServiceManagement

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var saveToDownloads = true {
        didSet { UserDefaults.standard.set(saveToDownloads, forKey: DownloadPathManager.persistDownloadsToAppLibraryDefaultsKey) }
    }
    @Published var launchAtLogin = false { didSet { UserDefaults.standard.set(launchAtLogin, forKey: "launch_at_login") } }
    @Published var steamProfileID: String = "" {
        didSet { UserDefaults.standard.set(steamProfileID, forKey: "workshop_steam_profile_id") }
    }
    @Published var showAllWorkshopContent = true { didSet { UserDefaults.standard.set(showAllWorkshopContent, forKey: "show_all_workshop_content") } }
    @Published var proxyEnabled = false { didSet { UserDefaults.standard.set(proxyEnabled, forKey: "proxy_enabled"); syncProxy() } }
    @Published var proxyHost: String = "" { didSet { UserDefaults.standard.set(proxyHost, forKey: "proxy_host"); syncProxy() } }
    @Published var proxyPort: String = "" { didSet { UserDefaults.standard.set(proxyPort, forKey: "proxy_port"); syncProxy() } }

    private func syncProxy() {
        let config = URLSessionConfiguration.default
        if proxyEnabled, !proxyHost.isEmpty, let port = Int(proxyPort) {
            config.connectionProxyDictionary = [
                kCFNetworkProxiesHTTPEnable: true,
                kCFNetworkProxiesHTTPProxy: proxyHost,
                kCFNetworkProxiesHTTPPort: port,
                kCFNetworkProxiesHTTPSEnable: true,
                kCFNetworkProxiesHTTPSProxy: proxyHost,
                kCFNetworkProxiesHTTPSPort: port
            ]
        } else {
            config.connectionProxyDictionary = nil
        }
    }

    init() {
        let d = UserDefaults.standard
        saveToDownloads = d.object(forKey: DownloadPathManager.persistDownloadsToAppLibraryDefaultsKey) as? Bool ?? true
        launchAtLogin = d.bool(forKey: "launch_at_login")
        steamProfileID = d.string(forKey: "workshop_steam_profile_id") ?? ""
        showAllWorkshopContent = d.bool(forKey: "show_all_workshop_content")
        proxyEnabled = d.bool(forKey: "proxy_enabled")
        proxyHost = d.string(forKey: "proxy_host") ?? ""
        proxyPort = d.string(forKey: "proxy_port") ?? ""
    }

    func restoreSavedSettings() {}
}
