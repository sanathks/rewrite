import XCTest
@testable import Rewrite

final class PromptsTests: XCTestCase {

    // MARK: - Grammar Prompt

    func testGrammarPromptContainsInputText() {
        let prompt = Prompts.grammar(text: "hello world")
        XCTAssertTrue(prompt.contains("hello world"))
    }

    func testGrammarPromptContainsFixInstruction() {
        let prompt = Prompts.grammar(text: "test")
        XCTAssertTrue(prompt.contains("Fix any grammar, spelling, and punctuation errors"))
    }

    func testGrammarPromptContainsPreserveMeaning() {
        let prompt = Prompts.grammar(text: "test")
        XCTAssertTrue(prompt.contains("Preserve the original meaning"))
    }

    func testGrammarPromptContainsReturnOnlyInstruction() {
        let prompt = Prompts.grammar(text: "test")
        XCTAssertTrue(prompt.contains("Return ONLY the corrected text"))
    }

    func testGrammarPromptHandlesEmptyString() {
        let prompt = Prompts.grammar(text: "")
        XCTAssertTrue(prompt.contains("Fix any grammar"))
    }

    func testGrammarPromptHandlesMultilineText() {
        let prompt = Prompts.grammar(text: "line one\nline two\nline three")
        XCTAssertTrue(prompt.contains("line one\nline two\nline three"))
    }

    func testGrammarPromptHandlesSpecialCharacters() {
        let prompt = Prompts.grammar(text: "Hello! @#$% \"quotes\" & <tags>")
        XCTAssertTrue(prompt.contains("Hello! @#$% \"quotes\" & <tags>"))
    }

    // MARK: - Rewrite Prompt

    func testRewritePromptUsesModePrompt() {
        let mode = RewriteMode(id: UUID(), name: "Clarity", prompt: "Make it clear")
        let prompt = Prompts.rewrite(mode: mode, text: "test input")
        XCTAssertTrue(prompt.contains("Make it clear"))
    }

    func testRewritePromptContainsInputText() {
        let mode = RewriteMode(id: UUID(), name: "Clarity", prompt: "Make it clear")
        let prompt = Prompts.rewrite(mode: mode, text: "test input")
        XCTAssertTrue(prompt.contains("test input"))
    }

    func testRewriteMyToneUsesSpecialHandling() {
        let mode = RewriteMode(id: UUID(), name: "My Tone", prompt: "casual and friendly")
        let prompt = Prompts.rewrite(mode: mode, text: "test")
        XCTAssertTrue(prompt.contains("match this tone"))
        XCTAssertTrue(prompt.contains("casual and friendly"))
    }

    func testRewriteMyToneContainsGrammarFix() {
        let mode = RewriteMode(id: UUID(), name: "My Tone", prompt: "casual")
        let prompt = Prompts.rewrite(mode: mode, text: "test")
        XCTAssertTrue(prompt.contains("Fix any grammar, spelling, and punctuation errors"))
    }

    func testRewriteNonMyToneDoesNotContainMatchTone() {
        let mode = RewriteMode(id: UUID(), name: "Professional", prompt: "Be professional")
        let prompt = Prompts.rewrite(mode: mode, text: "test")
        XCTAssertFalse(prompt.contains("match this tone"))
    }

    func testRewritePromptContainsNoDashesInstruction() {
        let mode = RewriteMode(id: UUID(), name: "Clarity", prompt: "Make it clear")
        let prompt = Prompts.rewrite(mode: mode, text: "test")
        XCTAssertTrue(prompt.contains("Never use em dashes or semicolons"))
    }

    func testRewritePromptContainsReturnOnlyInstruction() {
        let mode = RewriteMode(id: UUID(), name: "Clarity", prompt: "Make it clear")
        let prompt = Prompts.rewrite(mode: mode, text: "test")
        XCTAssertTrue(prompt.contains("Return ONLY the rewritten text"))
    }
}
