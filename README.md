# FixGrammar

A lightweight macOS menu bar app for system-wide grammar correction and tone rewriting, powered by a local Ollama instance. Select text in any app, hit a keyboard shortcut, and get a popover with the corrected text -- ready to replace or copy.

All processing happens locally. No data leaves your machine.

## Prerequisites

- macOS 13+
- [Ollama](https://ollama.com) installed and running
- A model pulled (default: `gemma3`):
  ```bash
  ollama pull gemma3
  ```

## Build & Install

```bash
chmod +x Scripts/build.sh Scripts/install.sh
./Scripts/build.sh
./Scripts/install.sh
```

The app is installed to `~/Applications/`. You may need to log out and back in for accessibility permissions to take effect.

## Usage

1. Launch **FixGrammar** -- a checkmark icon appears in the menu bar
2. Select text in any app (browser, Slack, Notes, TextEdit, etc.)
3. Press `Ctrl+Shift+G` to fix grammar, or `Ctrl+Shift+T` to rewrite with your tone
4. A popover appears near your selection with the result
5. Click **Replace** to swap the original text, or **Copy** to copy to clipboard

Press `Esc` to dismiss the popover.

## Configuration

Click the menu bar icon to access settings:

- **Ollama URL** -- default: `http://localhost:11434`
- **Model** -- auto-detected from your Ollama instance, default: `gemma3`
- **Tone Description** -- describes the writing style for "Add My Tone" (default: `casual and friendly, like texting a close colleague`)
- **Shortcuts** -- click to rebind the Fix Grammar and Add Tone hotkeys

Settings persist across app restarts.

## How It Works

FixGrammar uses the macOS Accessibility API to read selected text from any app. When you trigger a shortcut:

1. Reads the selected text via accessibility
2. Sends it to your local Ollama instance with a tailored prompt
3. Shows the result in a native popover near your selection
4. On "Replace", writes the corrected text back into the source app via accessibility

## License

MIT
