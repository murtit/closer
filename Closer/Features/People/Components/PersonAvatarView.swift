import SwiftUI

/// Round contact photo, or initials on coral, as in the app icon when there is no photo.
struct PersonAvatarView: View {
    let name: String
    let photoData: Data?
    var size: CGFloat = 44

    init(person: Person, size: CGFloat = 44) {
        self.name = person.name
        self.photoData = person.photoData
        self.size = size
    }

    init(name: String, photoData: Data?, size: CGFloat = 44) {
        self.name = name
        self.photoData = photoData
        self.size = size
    }

    var body: some View {
        Group {
            if let photoData, let image = UIImage(data: photoData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Color.closerAvatar
                    Text(Person.initials(for: name))
                        .font(.system(size: size * 0.38, weight: .semibold, design: .rounded))
                        .foregroundStyle(.closerOnAvatar)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .accessibilityHidden(true)
    }
}

#Preview {
    HStack {
        PersonAvatarView(name: "Anna Muster", photoData: nil)
        PersonAvatarView(name: "Opa", photoData: nil, size: 88)
    }
}
