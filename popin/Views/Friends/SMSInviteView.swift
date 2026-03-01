import MessageUI
import SwiftUI

struct SMSInviteView: UIViewControllerRepresentable {
    let recipientPhone: String
    let userId: String
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let controller = MFMessageComposeViewController()
        controller.recipients = [recipientPhone]
        controller.body = "Join me on PopIn! We can find spots and plan hangouts together 🎉\n\npopin://invite?from=\(userId)"
        controller.messageComposeDelegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss)
    }

    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        let dismiss: DismissAction

        init(dismiss: DismissAction) {
            self.dismiss = dismiss
        }

        func messageComposeViewController(
            _ controller: MFMessageComposeViewController,
            didFinishWith result: MessageComposeResult
        ) {
            dismiss()
        }
    }
}

/// Wrapper that checks if SMS is available before showing the compose view
struct SMSInviteWrapper: View {
    let recipientPhone: String
    let userId: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        if MFMessageComposeViewController.canSendText() {
            SMSInviteView(recipientPhone: recipientPhone, userId: userId)
        } else {
            VStack(spacing: 16) {
                Image(systemName: "message.badge.waveform")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)

                Text("SMS Not Available")
                    .font(.title3.bold())

                Text("This device can't send text messages.\nShare the invite link manually:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Text("popin://invite?from=\(userId)")
                    .font(.caption.monospaced())
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Button("Copy Link") {
                    UIPasteboard.general.string = "popin://invite?from=\(userId)"
                }
                .buttonStyle(.bordered)

                Button("Done") { dismiss() }
                    .padding(.top)
            }
            .padding()
        }
    }
}
