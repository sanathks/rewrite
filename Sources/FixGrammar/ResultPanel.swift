import AppKit
import SwiftUI

final class ResultPanel: NSObject, NSPopoverDelegate {
    private var popover: NSPopover?
    private var anchorWindow: NSWindow?
    private var keyMonitor: Any?
    private var clickMonitor: Any?
    private var deactivationObserver: Any?
    private let state: PopupState

    // Cached position for reopening after loading.
    private var cachedSelectionRect: NSRect = .zero

    // Temporary strong refs so AppKit animations can finish before dealloc.
    private var retainedPopover: NSPopover?
    private var retainedAnchor: NSWindow?

    init(title: String) {
        self.state = PopupState(title: title)
        super.init()
    }

    func show(near selectionRect: NSRect, onReplace: @escaping (String) -> Void, onCopy: @escaping (String) -> Void) {
        state.onReplace = { [weak self] text in
            self?.close()
            onReplace(text)
        }
        state.onCopy = { [weak self] text in
            self?.close()
            onCopy(text)
        }
        state.onCancel = { [weak self] in
            self?.close()
        }

        cachedSelectionRect = selectionRect
        showPopover(at: selectionRect)
    }

    func updateResult(_ text: String) {
        DispatchQueue.main.async {
            self.state.isLoading = false
            self.state.resultText = text
            self.reopenWithContent()
        }
    }

    func updateError(_ message: String) {
        DispatchQueue.main.async {
            self.state.isLoading = false
            self.state.errorMessage = message
            self.reopenWithContent()
        }
    }

    private func reopenWithContent() {
        dismissPopover()
        showPopover(at: cachedSelectionRect)
    }

    private func showPopover(at selectionRect: NSRect) {
        let view = PopupView(state: state)
        let hosting = NSHostingController(rootView: view)

        let pop = NSPopover()
        pop.contentViewController = hosting
        pop.behavior = .applicationDefined
        pop.animates = false
        pop.appearance = NSAppearance(named: .darkAqua)
        pop.delegate = self
        popover = pop

        let anchorFrame: NSRect
        if selectionRect.width > 0 && selectionRect.height > 0 {
            anchorFrame = selectionRect
        } else {
            anchorFrame = NSRect(
                x: selectionRect.origin.x - 1,
                y: selectionRect.origin.y - 1,
                width: 2, height: 2
            )
        }

        let anchor = NSWindow(
            contentRect: anchorFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        anchor.isOpaque = false
        anchor.backgroundColor = .clear
        anchor.level = .floating
        anchor.hasShadow = false
        anchor.ignoresMouseEvents = true
        anchor.collectionBehavior = [.canJoinAllSpaces, .stationary]
        anchor.orderFront(nil)
        anchorWindow = anchor

        pop.show(
            relativeTo: anchor.contentView!.bounds,
            of: anchor.contentView!,
            preferredEdge: .minY
        )

        NSApp.activate(ignoringOtherApps: true)
        installMonitors()
    }

    /// Close popover and anchor without removing event monitors.
    private func dismissPopover() {
        let pop = popover
        let anchor = anchorWindow
        popover = nil
        anchorWindow = nil

        retainedPopover = pop
        retainedAnchor = anchor

        pop?.close()
        anchor?.orderOut(nil)

        DispatchQueue.main.async { [weak self] in
            self?.retainedPopover = nil
            self?.retainedAnchor = nil
        }
    }

    private func installMonitors() {
        removeMonitors()

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            if event.keyCode == 53 {
                self.close()
                return nil
            }
            if event.keyCode == 36 {
                if !self.state.isLoading && self.state.errorMessage == nil {
                    self.state.onReplace?(self.state.resultText)
                }
                return nil
            }
            return event
        }

        clickMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] _ in
            self?.close()
        }

        deactivationObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.close()
        }
    }

    func close() {
        removeMonitors()
        dismissPopover()
    }

    private func removeMonitors() {
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
        if let monitor = clickMonitor {
            NSEvent.removeMonitor(monitor)
            clickMonitor = nil
        }
        if let observer = deactivationObserver {
            NotificationCenter.default.removeObserver(observer)
            deactivationObserver = nil
        }
    }

    func popoverDidClose(_ notification: Notification) {
        // Only clean up if this wasn't a reopen cycle.
        guard popover == nil else { return }
        removeMonitors()
        if let anchor = anchorWindow {
            anchorWindow = nil
            retainedAnchor = anchor
            anchor.orderOut(nil)
            DispatchQueue.main.async { [weak self] in
                self?.retainedAnchor = nil
            }
        }
    }
}
