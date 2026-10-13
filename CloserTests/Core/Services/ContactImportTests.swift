import Contacts
import Testing
import UIKit
@testable import Closer

@MainActor
struct ContactImportTests {
    @Test func importsNamePhoneAndEmail() {
        let contact = CNMutableContact()
        contact.givenName = "Hans"
        contact.familyName = "Muster"
        contact.phoneNumbers = [
            CNLabeledValue(label: CNLabelHome, value: CNPhoneNumber(stringValue: "044 123 45 67")),
            CNLabeledValue(label: CNLabelPhoneNumberMobile, value: CNPhoneNumber(stringValue: "+41 79 123 45 67")),
        ]
        contact.emailAddresses = [CNLabeledValue(label: CNLabelHome, value: "hans@example.ch" as NSString)]

        let imported = ContactImport.importedContact(from: contact)
        #expect(imported.name == "Hans Muster")
        #expect(imported.phoneNumber == "+41 79 123 45 67")
        #expect(imported.email == "hans@example.ch")
        #expect(imported.photoData == nil)
        #expect(imported.identifier == contact.identifier)
    }

    @Test func fallsBackToFirstPhoneNumberWithoutMobile() {
        let contact = CNMutableContact()
        contact.givenName = "Opa"
        contact.phoneNumbers = [CNLabeledValue(label: CNLabelHome, value: CNPhoneNumber(stringValue: "044 123 45 67"))]
        #expect(ContactImport.preferredPhoneNumber(of: contact) == "044 123 45 67")
    }

    @Test func usesOrganizationWhenThereIsNoName() {
        let contact = CNMutableContact()
        contact.organizationName = "Kletterclub"
        #expect(ContactImport.name(of: contact) == "Kletterclub")
    }

    @Test func photoIsDownscaled() throws {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1200, height: 600), format: {
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            return format
        }())
        let big = renderer.image { context in
            UIColor.systemPink.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1200, height: 600))
        }
        let contact = CNMutableContact()
        contact.givenName = "Sara"
        contact.imageData = big.pngData()

        let data = try #require(ContactImport.importedContact(from: contact).photoData)
        let image = try #require(UIImage(data: data))
        #expect(image.size.width == 400)
        #expect(image.size.height == 200)
    }

    @Test func invalidImageDataIsDropped() {
        #expect(ContactImport.downscaledJPEG(Data([0x00, 0x01])) == nil)
    }
}
