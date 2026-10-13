import ContactsUI
import SwiftUI

extension View {
    /// Presents the system contact picker. It runs out of process, so the app needs no Contacts
    /// permission and no `NSContactsUsageDescription`.
    func contactPicker(isPresented: Binding<Bool>, onSelect: @escaping (ImportedContact) -> Void) -> some View {
        background(ContactPickerPresenter(isPresented: isPresented, onSelect: onSelect))
    }
}

/// `CNContactPickerViewController` misbehaves when wrapped directly in a SwiftUI sheet, so an
/// invisible host controller presents it modally instead.
struct ContactPickerPresenter: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let onSelect: (ImportedContact) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ host: UIViewController, context: Context) {
        context.coordinator.parent = self
        let coordinator = context.coordinator
        guard isPresented, !coordinator.isPresenting else { return }

        coordinator.isPresenting = true
        let picker = CNContactPickerViewController()
        picker.delegate = coordinator
        // Defer until the current view update is finished and the host is in the window.
        Task {
            host.present(picker, animated: true)
        }
    }

    final class Coordinator: NSObject, CNContactPickerDelegate {
        var parent: ContactPickerPresenter
        var isPresenting = false

        init(_ parent: ContactPickerPresenter) {
            self.parent = parent
        }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            isPresenting = false
            parent.onSelect(ContactImport.importedContact(from: contact))
            parent.isPresented = false
        }

        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            isPresenting = false
            parent.isPresented = false
        }
    }
}
