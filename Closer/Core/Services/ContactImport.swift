import Contacts
import UIKit

/// The parts of a system contact Closer keeps.
struct ImportedContact: Equatable {
    var identifier: String
    var name: String
    var phoneNumber: String?
    var email: String?
    var photoData: Data?
}

/// Maps a `CNContact` from the system contact picker to an `ImportedContact`.
///
/// The picker runs out of process and hands over the selected contact without the app needing
/// full Contacts permission. Every key is still checked with `isKeyAvailable`, because reading a
/// key that was not fetched raises an Objective-C exception.
enum ContactImport {
    static func importedContact(from contact: CNContact) -> ImportedContact {
        ImportedContact(
            identifier: contact.identifier,
            name: name(of: contact),
            phoneNumber: preferredPhoneNumber(of: contact),
            email: preferredEmail(of: contact),
            photoData: photoData(of: contact)
        )
    }

    static func name(of contact: CNContact) -> String {
        let given = available(contact, CNContactGivenNameKey) ? contact.givenName : ""
        let family = available(contact, CNContactFamilyNameKey) ? contact.familyName : ""
        let full = [given, family].filter { !$0.isEmpty }.joined(separator: " ")
        if !full.isEmpty { return full }
        if available(contact, CNContactNicknameKey), !contact.nickname.isEmpty { return contact.nickname }
        if available(contact, CNContactOrganizationNameKey) { return contact.organizationName }
        return ""
    }

    /// Prefers a mobile number (most useful for calls and messages), otherwise the first one.
    static func preferredPhoneNumber(of contact: CNContact) -> String? {
        guard available(contact, CNContactPhoneNumbersKey) else { return nil }
        let numbers = contact.phoneNumbers
        let mobileLabels: Set<String> = [CNLabelPhoneNumberMobile, CNLabelPhoneNumberiPhone]
        let preferred = numbers.first { mobileLabels.contains($0.label ?? "") } ?? numbers.first
        return preferred?.value.stringValue
    }

    static func preferredEmail(of contact: CNContact) -> String? {
        guard available(contact, CNContactEmailAddressesKey) else { return nil }
        return contact.emailAddresses.first.map { $0.value as String }
    }

    static func photoData(of contact: CNContact) -> Data? {
        var data: Data?
        if available(contact, CNContactImageDataKey) { data = contact.imageData }
        if data == nil, available(contact, CNContactThumbnailImageDataKey) { data = contact.thumbnailImageData }
        return data.flatMap { downscaledJPEG($0) }
    }

    /// Shrinks a photo so that the longer side is at most `maxDimension` points (at scale 1).
    static func downscaledJPEG(_ data: Data, maxDimension: CGFloat = 400) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let longest = max(image.size.width, image.size.height)
        guard longest > 0 else { return nil }
        let factor = min(1, maxDimension / longest)
        let size = CGSize(width: image.size.width * factor, height: image.size.height * factor)

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let resized = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        return resized.jpegData(compressionQuality: 0.8)
    }

    private static func available(_ contact: CNContact, _ key: String) -> Bool {
        contact.isKeyAvailable(key)
    }
}
