import SwiftUI

private let popupWidth: CGFloat = 340
private let maxContentHeight: CGFloat = 300

struct PopupView: View {
    @ObservedObject var state: PopupState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(state.title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
                .padding(.bottom, 10)

            if state.isLoading {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                        .colorScheme(.dark)
                    Text("Processing...")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))
                }
            } else if let error = state.errorMessage {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundColor(.red.opacity(0.9))
            } else {
                Text(state.resultText)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.9))
                    .textSelection(.enabled)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, maxHeight: maxContentHeight, alignment: .leading)
            }

            if !state.isLoading {
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 1)
                    .padding(.vertical, 8)

                HStack(spacing: 0) {
                    if state.errorMessage != nil {
                        PopupButton(label: "Dismiss") { state.onCancel?() }
                    } else {
                        PopupButton(label: "Replace") { state.onReplace?(state.resultText) }
                        PopupButton(label: "Copy") { state.onCopy?(state.resultText) }
                    }

                    Spacer()

                    Button {
                        state.onCopy?(state.resultText)
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                    .opacity(state.errorMessage == nil ? 1 : 0)
                }
            }
        }
        .padding(14)
        .frame(width: popupWidth)
        .preferredColorScheme(.dark)
    }
}

struct PopupButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.85))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.trailing, 6)
    }
}
