import Contacts
import Foundation

@Observable
final class ContactsService {

    enum AuthStatus {
        case notDetermined
        case authorized
        case denied
        case restricted
    }

    struct ContactEntry: Identifiable {
        let id: String
        let fullName: String
        let phoneNumbers: [String] // normalized E.164
        let thumbnailData: Data?
    }

    var authStatus: AuthStatus = .notDetermined
    var contacts: [ContactEntry] = []
    var isLoading = false

    private let store = CNContactStore()

    init() {
        checkCurrentStatus()
    }

    // MARK: - Authorization

    private func checkCurrentStatus() {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        switch status {
        case .authorized, .limited:
            authStatus = .authorized
        case .denied:
            authStatus = .denied
        case .restricted:
            authStatus = .restricted
        case .notDetermined:
            authStatus = .notDetermined
        @unknown default:
            authStatus = .notDetermined
        }
    }

    func requestAccess() async -> Bool {
        do {
            let granted = try await store.requestAccess(for: .contacts)
            await MainActor.run {
                self.authStatus = granted ? .authorized : .denied
            }
            return granted
        } catch {
            await MainActor.run {
                self.authStatus = .denied
            }
            return false
        }
    }

    // MARK: - Fetch

    func fetchContacts() async {
        guard authStatus == .authorized else { return }
        await MainActor.run { isLoading = true }

        let keysToFetch: [CNKeyDescriptor] = [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactThumbnailImageDataKey as CNKeyDescriptor,
            CNContactIdentifierKey as CNKeyDescriptor,
        ]

        let request = CNContactFetchRequest(keysToFetch: keysToFetch)
        request.sortOrder = .givenName

        var results: [ContactEntry] = []

        do {
            try store.enumerateContacts(with: request) { contact, _ in
                let phones = contact.phoneNumbers.compactMap {
                    Self.normalizePhoneNumber($0.value.stringValue)
                }
                guard !phones.isEmpty else { return }

                let name = [contact.givenName, contact.familyName]
                    .filter { !$0.isEmpty }
                    .joined(separator: " ")

                results.append(ContactEntry(
                    id: contact.identifier,
                    fullName: name.isEmpty ? "Unknown" : name,
                    phoneNumbers: phones,
                    thumbnailData: contact.thumbnailImageData
                ))
            }
        } catch {
            print("Error fetching contacts: \(error)")
        }

        await MainActor.run {
            self.contacts = results
            self.isLoading = false
        }
    }

    /// All unique phone numbers from fetched contacts
    var allPhoneNumbers: [String] {
        Array(Set(contacts.flatMap(\.phoneNumbers)))
    }

    // MARK: - Phone Normalization

    /// Normalize to E.164 format (simplified, US-focused for MVP)
    static func normalizePhoneNumber(_ raw: String) -> String? {
        let digits = raw.filter { $0.isNumber }
        guard digits.count >= 10 else { return nil }

        if raw.hasPrefix("+") {
            return "+" + digits
        }
        if digits.count == 10 {
            return "+1\(digits)" // US default
        }
        if digits.count == 11, digits.hasPrefix("1") {
            return "+\(digits)"
        }
        return "+\(digits)"
    }
}
