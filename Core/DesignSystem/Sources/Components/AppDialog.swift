import SwiftUI

extension View {
    /// A confirm/dismiss dialog with already-resolved, localised strings.
    ///
    /// A thin wrapper over `.alert` so every product's dialogs read the same; reach for `.alert`
    /// directly when you need more than two buttons.
    ///
    /// - Parameter isDestructive: styles the confirm button as destructive (delete, sign out).
    public func appDialog(
        isPresented: Binding<Bool>,
        title: String,
        message: String? = nil,
        confirmTitle: String,
        dismissTitle: String? = nil,
        isDestructive: Bool = false,
        onConfirm: @escaping () -> Void,
        onDismiss: @escaping () -> Void = {}
    ) -> some View {
        alert(title, isPresented: isPresented) {
            Button(confirmTitle, role: isDestructive ? .destructive : nil, action: onConfirm)
            if let dismissTitle {
                Button(dismissTitle, role: .cancel, action: onDismiss)
            }
        } message: {
            if let message {
                Text(message)
            }
        }
    }
}
