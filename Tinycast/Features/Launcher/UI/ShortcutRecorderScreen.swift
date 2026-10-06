import SwiftUI

/// The row ⌘K's Set Shortcut… records for, and the binding it held going in.
struct ShortcutRecording {
    let entry: AppEntry
    let action: HotKeyAction
    let previous: HotKeyBinding?
}

extension AppEntry {
    /// Every bindable entry's action; an extension command's is keyed by entry ID instead.
    var shortcutAction: HotKeyAction? {
        kind == .extensionCommand ? .extensionCommand(entryID: id) : hotKeyAction
    }
}

/// Settings' own recorder, seated in the palette: one capture session, one set of rules.
struct ShortcutRecorderScreen: PaletteScreen {
    let coordinator: LauncherCoordinator

    var rows: [AppEntry] { [] }
    var primaryActionTitle: String { "Set Shortcut" }
    /// The capture swallows every key while it listens, so the field would only show a dead caret.
    var hidesSearchField: Bool { true }

    func hasActions(at selection: Int) -> Bool { false }
    func activate(at selection: Int) {}
    func secondary(at selection: Int) -> Bool { false }

    func body(selection: Int, scroll: ScrollIntent) -> AnyView {
        guard let recording = coordinator.shortcutRecording else { return AnyView(EmptyView()) }
        return AnyView(
            ShortcutRecordingView(recording: recording, onEnd: coordinator.finishRecordingShortcut))
    }
}

private struct ShortcutRecordingView: View {
    let recording: ShortcutRecording
    let onEnd: () -> Void

    @Environment(HotKeyManager.self) private var hotKeys
    @Environment(\.metrics) private var metrics

    private var prompt: String {
        hotKeys.binding(for: recording.action) == nil
            ? "Press a shortcut" : "Press a new shortcut, or ⌫ to remove it"
    }

    var body: some View {
        VStack(spacing: metrics.spacing.sm) {
            AppIconView(app: recording.entry, pointSize: metrics.size.dialogIcon)
                .frame(width: metrics.size.dialogIcon, height: metrics.size.dialogIcon)
            Text(recording.entry.name)
                .font(metrics.typography.panelTitle)
                .foregroundStyle(Theme.Colors.textPrimary)
                .lineLimit(1)
            Text(prompt)
                .font(metrics.typography.rowTrailing)
                .foregroundStyle(Theme.Colors.textSecondary)
            ShortcutRecorder(action: recording.action)
                // The callout narrates held keys and conflicts above the field, so leave it room.
                .padding(.top, Theme.Size.shortcutPopover.height + Theme.Spacing.sm * 2)
        }
        .padding(.horizontal, metrics.spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .shortcutRecorderPopoverHost()
        // Initial too: a screen restored after its capture ended elsewhere must not linger.
        .onChange(of: hotKeys.recordingAction, initial: true) { _, action in
            if action != recording.action { onEnd() }
        }
        // ⌘⎋ leaves for the root without this screen popping, so the record is dropped here too.
        .onDisappear(perform: onEnd)
    }
}
