import XCTest
@testable import Rewrite

final class SettingsTests: XCTestCase {
    var suiteName: String!
    var testDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "SettingsTests-\(UUID().uuidString)"
        testDefaults = UserDefaults(suiteName: suiteName)!
    }

    override func tearDown() {
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
        testDefaults = nil
        suiteName = nil
        super.tearDown()
    }

    // MARK: - Default Values

    func testDefaultServerURL() {
        let settings = Settings(defaults: testDefaults)
        XCTAssertEqual(settings.serverURL, "http://localhost:11434")
    }

    func testDefaultModelName() {
        let settings = Settings(defaults: testDefaults)
        XCTAssertEqual(settings.modelName, "gemma3")
    }

    func testDefaultModeIdIsNil() {
        let settings = Settings(defaults: testDefaults)
        XCTAssertNil(settings.defaultModeId)
    }

    func testDefaultRewriteModesCount() {
        let settings = Settings(defaults: testDefaults)
        XCTAssertEqual(settings.rewriteModes.count, Settings.defaultRewriteModes.count)
    }

    // MARK: - Persistence Round Trips

    func testServerURLPersistence() {
        let settings = Settings(defaults: testDefaults)
        settings.serverURL = "http://example.com:5000"

        let settings2 = Settings(defaults: testDefaults)
        XCTAssertEqual(settings2.serverURL, "http://example.com:5000")
    }

    func testModelNamePersistence() {
        let settings = Settings(defaults: testDefaults)
        settings.modelName = "llama3"

        let settings2 = Settings(defaults: testDefaults)
        XCTAssertEqual(settings2.modelName, "llama3")
    }

    func testDefaultModeIdPersistence() {
        let id = UUID()
        let settings = Settings(defaults: testDefaults)
        settings.defaultModeId = id

        let settings2 = Settings(defaults: testDefaults)
        XCTAssertEqual(settings2.defaultModeId, id)
    }

    func testDefaultModeIdClearPersistence() {
        let settings = Settings(defaults: testDefaults)
        settings.defaultModeId = UUID()
        settings.defaultModeId = nil

        let settings2 = Settings(defaults: testDefaults)
        XCTAssertNil(settings2.defaultModeId)
    }

    // MARK: - Pre-populated Defaults

    func testPrePopulatedServerURL() {
        testDefaults.set("http://custom:9999", forKey: "ollamaURL")
        let settings = Settings(defaults: testDefaults)
        XCTAssertEqual(settings.serverURL, "http://custom:9999")
    }

    func testPrePopulatedModelName() {
        testDefaults.set("custom-model", forKey: "modelName")
        let settings = Settings(defaults: testDefaults)
        XCTAssertEqual(settings.modelName, "custom-model")
    }

    // MARK: - RewriteMode Codable

    func testRewriteModeCodableRoundTrip() {
        let mode = RewriteMode(id: UUID(), name: "Test", prompt: "Test prompt")
        let data = try! JSONEncoder().encode(mode)
        let decoded = try! JSONDecoder().decode(RewriteMode.self, from: data)
        XCTAssertEqual(mode, decoded)
    }

    func testRewriteModesPersistence() {
        let modes = [
            RewriteMode(id: UUID(), name: "Mode1", prompt: "Prompt1"),
            RewriteMode(id: UUID(), name: "Mode2", prompt: "Prompt2")
        ]
        let settings = Settings(defaults: testDefaults)
        settings.rewriteModes = modes

        let settings2 = Settings(defaults: testDefaults)
        XCTAssertEqual(settings2.rewriteModes, modes)
    }
}
