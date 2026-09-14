import Foundation

// MARK: - Core domain types (spec §3 / NOTES content model)

enum EventType: String, CaseIterable, Codable, Identifiable {
    case sangeet, mehendi, reception, haldi, nikah, engagement
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
}

enum EventStatus: String, Codable { case upcoming, enquiry, completed, cancelled }

/// Payment state shown on the event card chip (spec component 2).
enum PaymentState: String, Codable { case paid, partial, overdue, pending }

/// Event colour is assigned per event at creation, cycling 1→4. Ruby is excluded (NOTES ruling 2).
enum EventHue: Int, Codable, CaseIterable { case one = 1, two, three, four }

struct Venue: Codable, Hashable {
    var name: String      // "The Leela Ambience"
    var area: String      // "Gurugram"
    var hall: String?     // "Grand Ballroom"
    var short: String { "\(name), \(area)" }
    /// Without the leading article, for tight card lines ("Leela Ambience, Gurugram · 17:00").
    var shortName: String { name.hasPrefix("The ") ? String(name.dropFirst(4)) : name }
    var compact: String { "\(shortName), \(area)" }
}

struct Event: Identifiable, Codable, Hashable {
    var id: String
    var name: String              // "Kapoor sangeet"
    var clientId: String
    var type: EventType
    var start: Date
    var end: Date
    var venue: Venue
    var guests: Int
    var quoted: Int               // rupees
    var hue: EventHue
    var status: EventStatus
    var crewAssigned: Int
    var crewNeeded: Int
    /// Role breakdown of the crew plan ("2 coordinators, 6 decorators, 6 helpers"); daily-wage crew are outside the roster.
    var crewPlan: String = ""
    var hasCrewConflict: Bool
    var inventorySummary: String  // "250 chairs · 120 drapes · 24 par cans"
    var runsheetSummary: String   // "8 tasks · setup 09:00 · 2 done"

    var surname: String { name.split(separator: " ").first.map(String.init) ?? name }
    var isCompleted: Bool { status == .completed }
}

struct Client: Identifiable, Codable, Hashable {
    var id: String
    var name: String           // "Vikram Kapoor"
    var phone: String          // "98110 42760"
    var isRepeat: Bool
    var eventCount: Int
    var lifetimeValue: Int
    var nextEventDate: Date?
    var avatar: Int            // 1…8 bundled avatar
    var surname: String { name.split(separator: " ").last.map(String.init) ?? name }
}

enum MilestoneStatus: String, Codable { case paid, pending, overdue }

struct Milestone: Identifiable, Codable, Hashable {
    var id: String
    var eventId: String
    var name: String           // "Second instalment"
    var amount: Int
    var due: Date
    var status: MilestoneStatus
    var paidOn: Date?
    var method: PaymentMethod?
    var reference: String?
    var kind: Kind
    enum Kind: String, Codable { case advance, instalment, balance, settlement }
    var isOpen: Bool { status != .paid }
}

enum PaymentMethod: String, CaseIterable, Codable, Identifiable {
    case upi = "UPI", bank = "Bank transfer", cash = "Cash", cheque = "Cheque"
    var id: String { rawValue }
}

enum ReminderTone: String, CaseIterable, Identifiable {
    case gentle = "Gentle", standard = "Standard", firm = "Firm"
    var id: String { rawValue }
}

enum ReminderChannel: String, CaseIterable, Identifiable {
    case whatsapp = "WhatsApp", sms = "SMS"
    var id: String { rawValue }
}

struct SentReminder: Identifiable, Hashable {
    var id: String
    var tone: ReminderTone
    var sent: Date
    var channel: ReminderChannel
    var outcome: String       // "seen 10:40 · no reply", "delivered"
}

enum CrewRole: String, Codable, CaseIterable {
    case coordinator, decorator, helper
    var label: String { rawValue.capitalized }
    var plural: String { rawValue.capitalized + "s" }
    var dayRate: Int { switch self { case .coordinator: 2500; case .decorator: 1200; case .helper: 800 } }
}

enum AttendanceState: String, Codable, CaseIterable {
    case confirmed, arrived, absent
    var label: String { rawValue.capitalized }
    var next: AttendanceState { switch self { case .confirmed: .arrived; case .arrived: .absent; case .absent: .confirmed } }
}

struct CrewMember: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var role: CrewRole
    var isLead: Bool
    var avatar: Int?                 // nil → initials disc
    /// Event id the member is booked on for Sat 14 Nov (the design's focal day), if any.
    var bookedOn: [String]
    var availabilityNote: String?    // "free from 17:30"
    var firstName: String { name.split(separator: " ").first.map(String.init) ?? name }
}

struct InventoryItem: Identifiable, Codable, Hashable {
    var id: String
    var name: String            // "Drape panels"
    var total: Int
    var detail: String          // "3 m velvet · 12 colours"
    /// Holds on the focal day, event id → quantity.
    var holds: [Hold]
    struct Hold: Codable, Hashable { var eventId: String; var qty: Int; var date: Date }
    func committed(on day: Date) -> Int { holds.filter { Cal.sameDay($0.date, day) }.reduce(0) { $0 + $1.qty } }
    func isOver(on day: Date) -> Bool { committed(on: day) > total }
}

struct RunsheetTask: Identifiable, Codable, Hashable {
    var id: String
    var eventId: String
    var block: String           // "Setup"
    var blockTime: String       // "09:00–14:00"
    var title: String
    var crew: String            // "Suresh's team · 6 crew"
    var duration: String        // "1 h 30"
    var done: Bool
}

struct Expense: Identifiable, Hashable {
    var id: String
    var name: String
    var detail: String
    var amount: Int
}

struct Package: Identifiable, Hashable {
    var id: String
    var name: String
    var detail: String
    var price: Int
}

struct ChangeImpact: Identifiable, Hashable {
    var id: String
    var resource: String        // "Round tables"
    var detail: String          // "All 60 held · hire 20 more"
    var delta: String           // "+20 · ₹8,000"
    var isShort: Bool
    var icon: String            // SF Symbol
}

struct Enquiry: Identifiable, Hashable {
    var id: String
    var name: String
    var source: String
    var budget: String
    var date: Date?
    var guests: Int
    var notes: String
}

/// New-event draft (spec §5: back navigation never loses entered data).
struct EventDraft: Codable, Equatable {
    var clientName = ""
    var phone = ""
    var type: EventType? = nil
    var date: Date? = nil
    var venue = ""
    var guests = 300
    var packageIds: Set<String> = []
    var quoted: Int = 0
    static let empty = EventDraft()
}

enum Appearance: String, CaseIterable, Identifiable, Codable {
    case system, light, dark
    var id: String { rawValue }
    var label: String { switch self { case .system: "Follows system"; case .light: "Light"; case .dark: "Dark" } }
}
