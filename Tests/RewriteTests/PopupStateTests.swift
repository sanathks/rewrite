import XCTest
@testable import Rewrite

final class PopupStateTests: XCTestCase {

    func testInitWithModes() {
        let modes = [
            RewriteMode(id: UUID(), name: "Mode1", prompt: "P1"),
            RewriteMode(id: UUID(), name: "Mode2", prompt: "P2")
        ]
        let state = PopupState(modes: modes)
        XCTAssertEqual(state.modes.count, 2)
    }

    func testInitSelectedModeIdIsNil() {
        let state = PopupState(modes: [])
        XCTAssertNil(state.selectedModeId)
    }

    func testInitModePhasesIsEmpty() {
        let state = PopupState(modes: [])
        XCTAssertTrue(state.modePhases.isEmpty)
    }

    func testCurrentPhaseReturnsLoadingWhenNoSelection() {
        let state = PopupState(modes: [])
        if case .loading = state.currentPhase {
            // pass
        } else {
            XCTFail("Expected .loading phase")
        }
    }

    func testCurrentPhaseReturnsLoadingWhenSelectedButNoPhaseSet() {
        let id = UUID()
        let state = PopupState(modes: [RewriteMode(id: id, name: "Test", prompt: "P")])
        state.selectedModeId = id
        if case .loading = state.currentPhase {
            // pass
        } else {
            XCTFail("Expected .loading phase when no phase set for selected mode")
        }
    }

    func testCurrentPhaseReturnsResultWhenSet() {
        let id = UUID()
        let state = PopupState(modes: [RewriteMode(id: id, name: "Test", prompt: "P")])
        state.selectedModeId = id
        state.modePhases[id] = .result("Done")
        if case .result(let text) = state.currentPhase {
            XCTAssertEqual(text, "Done")
        } else {
            XCTFail("Expected .result phase")
        }
    }

    func testCurrentPhaseReturnsErrorWhenSet() {
        let id = UUID()
        let state = PopupState(modes: [RewriteMode(id: id, name: "Test", prompt: "P")])
        state.selectedModeId = id
        state.modePhases[id] = .error("Failed")
        if case .error(let msg) = state.currentPhase {
            XCTAssertEqual(msg, "Failed")
        } else {
            XCTFail("Expected .error phase")
        }
    }

    func testModeSwitchingTracksPhasesPerMode() {
        let id1 = UUID()
        let id2 = UUID()
        let state = PopupState(modes: [
            RewriteMode(id: id1, name: "M1", prompt: "P1"),
            RewriteMode(id: id2, name: "M2", prompt: "P2")
        ])

        state.selectedModeId = id1
        state.modePhases[id1] = .result("Result1")

        state.selectedModeId = id2
        state.modePhases[id2] = .error("Error2")

        // Switch back to mode 1 - should retain its phase
        state.selectedModeId = id1
        if case .result(let text) = state.currentPhase {
            XCTAssertEqual(text, "Result1")
        } else {
            XCTFail("Expected mode 1 to still have .result phase")
        }

        // Switch to mode 2 - should retain its phase
        state.selectedModeId = id2
        if case .error(let msg) = state.currentPhase {
            XCTAssertEqual(msg, "Error2")
        } else {
            XCTFail("Expected mode 2 to still have .error phase")
        }
    }

    func testUnknownModeIdReturnsLoading() {
        let state = PopupState(modes: [])
        state.selectedModeId = UUID()
        if case .loading = state.currentPhase {
            // pass
        } else {
            XCTFail("Expected .loading for unknown mode ID")
        }
    }

    func testCallbacksDefaultToNil() {
        let state = PopupState(modes: [])
        XCTAssertTrue(state.onModeSelected == nil)
        XCTAssertTrue(state.onReplace == nil)
        XCTAssertTrue(state.onCopy == nil)
        XCTAssertTrue(state.onCancel == nil)
    }
}
