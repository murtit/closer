import Foundation

/// Everything the model needs to know to suggest ideas for one person.
struct IdeaRequest: Equatable {
    var name: String
    var relationship: Relationship
    var category: IdeaCategory
    var budget: IdeaBudget
    /// What the user typed about the person, e.g. "mag Sushi und wandert gern".
    var note: String = ""
    /// Full years together, only for the partner.
    var yearsTogether: Int?
    /// Days until the next anniversary, only for the partner.
    var daysUntilAnniversary: Int?
    /// Titles of ideas already shown, so "Neue Ideen" brings different ones.
    var excludedTitles: [String] = []
    var count: Int = 5

    init(
        name: String,
        relationship: Relationship,
        category: IdeaCategory,
        budget: IdeaBudget,
        note: String = "",
        yearsTogether: Int? = nil,
        daysUntilAnniversary: Int? = nil,
        excludedTitles: [String] = [],
        count: Int = 5
    ) {
        self.name = name
        self.relationship = relationship
        self.category = category
        self.budget = budget
        self.note = note
        self.yearsTogether = yearsTogether
        self.daysUntilAnniversary = daysUntilAnniversary
        self.excludedTitles = excludedTitles
        self.count = count
    }

    /// Takes the first name and, for the partner, the anniversary from the person.
    init(
        person: Person,
        category: IdeaCategory,
        budget: IdeaBudget,
        note: String = "",
        excludedTitles: [String] = [],
        now: Date = Date(),
        calendar: Calendar = .current
    ) {
        let anniversary = person.partnerAnniversary
        self.init(
            name: Self.firstName(of: person.name),
            relationship: person.relationship,
            category: category,
            budget: budget,
            note: note,
            yearsTogether: anniversary.flatMap { calendar.dateComponents([.year], from: $0.date, to: now).year },
            daysUntilAnniversary: anniversary?.daysUntilNext(from: now, calendar: calendar),
            excludedTitles: excludedTitles
        )
    }

    /// "Lea Brunner" → "Lea". Falls back to the whole name if it has no spaces.
    static func firstName(of name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.split(whereSeparator: \.isWhitespace).first.map(String.init) ?? trimmed
    }
}
