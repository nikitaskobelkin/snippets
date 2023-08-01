// The Remote Configuration Service is an iOS implementation that utilizes Firebase Remote Config and Swift-basedFirebaseRemoteConfigSwift to enable dynamic app behavior
// configuration without requiring updates. Firebase Remote Config provides a cloud-based solution for remotely adjusting app behavior, making it ideal for A/B testing, feature
// flagging, and personalization. Swift's native integration and async/await support enhance asynchronous code handling, resulting in concise and expressive code for fetching
// configurations. The use of a centralized ConfigKey enum ensures type safety and simplifies configuration key management. The service employs dependency injection to facilitate
// flexibility and testability. By setting minimum fetch intervals and timeout, it optimizes fetch operations, and error handling has been improved for robustness. Overall, this
// implementation enhances app flexibility and adaptability, while proper testing and error handling ensure a reliable user experience.

import FirebaseRemoteConfig
import FirebaseRemoteConfigSwift

final class RemoteConfigService: RemoteConfigServiceProtocol {
    private let config: RemoteConfig

    init(config: RemoteConfig = RemoteConfig.remoteConfig()) {
        self.config = config
        setUpConfig()
    }

    func getConfig(by key: ConfigKey) async throws -> Data {
        try await fetchConfig()
        return config.configValue(forKey: key.rawValue).dataValue
    }

    func getConfig(by key: ConfigKey) async throws -> Bool {
        try await fetchConfig()
        return config.configValue(forKey: key.rawValue).boolValue
    }

    func getConfig(by key: ConfigKey) async throws -> String {
        try await fetchConfig()
        return config.configValue(forKey: key.rawValue).stringValue ?? ""
    }

    private func fetchConfig() async throws {
        do {
            try await config.fetchAndActivate()
        } catch {
            throw error
        }
    }

    private func setUpConfig() {
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0
        settings.fetchTimeout = 4
        config.configSettings = settings
    }
}
