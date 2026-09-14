import Foundation
import SwiftUI
import Observation

enum AppTab: String, CaseIterable, Identifiable, Hashable {
    case home, events, money, team, profile
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var symbol: String {
        switch self {
        case .home: "house"
        case .events: "calendar"
        case .money: "creditcard"
        case .team: "person.2"
        case .profile: "person"
        }
    }
}

/// Every pushed destination in the app (spec §2: never more than three levels from a tab root).
enum Route: Hashable {
    case calendarMonth
    case dayDetail(Date)
    case seasonSummary
    case eventDetail(String)
    case createEvent
    case runsheet(String)
    case changeRequest(String)
    case paymentSchedule(String)
    case expenses(String)
    case assignCrew(String)
    case attendance(String)
    case inventory
    case itemDetail(String)
    case clients
    case sharedPage(String)
    case enquiry
    case crewList
}

struct Toast: Identifiable, Equatable {
    enum Kind { case success, error, info }
    let id = UUID()
    var kind: Kind
    var message: String
}

@Observable
final class AppStore {
    // Data
    var events: [Event] = Seed.events
    var clients: [Client] = Seed.clients
    var milestones: [Milestone] = Seed.milestones
    var crew: [CrewMember] = Seed.crew
    var inventory: [InventoryItem] = Seed.inventory
    var tasks: [RunsheetTask] = Seed.runsheet
    var sentReminders: [String: [SentReminder]] = Seed.sentReminders
    /// eventId → crewId → state
    var attendance: [String: [String: AttendanceState]] = [
        "kapoor-sangeet": Dictionary(uniqueKeysWithValues: Seed.kapoorAttendance),
        "sharma-mehendi": Dictionary(uniqueKeysWithValues: Seed.sharmaAttendance),
        "gill-engagement": Dictionary(uniqueKeysWithValues: Seed.gillAttendance),
    ]
    var pendingChangeRequest: Bool = true

    // Navigation
    var selectedTab: AppTab = .home
    var paths: [AppTab: [Route]] = Dictionary(uniqueKeysWithValues: AppTab.allCases.map { ($0, []) })
    var toast: Toast?

    // Settings (E4)
    var appearance: Appearance {
        didSet { UserDefaults.standard.set(appearance.rawValue, forKey: "appearance") }
    }
    var draft: EventDraft {
        didSet { if let d = try? JSONEncoder().encode(draft) { UserDefaults.standard.set(d, forKey: "eventDraft") } }
    }

    init() {
        appearance = Appearance(rawValue: UserDefaults.standard.string(forKey: "appearance") ?? "") ?? .system
        if let d = UserDefaults.standard.data(forKey: "eventDraft"), let dr = try? JSONDecoder().decode(EventDraft.self, from: d) {
            draft = dr
        } else { draft = .empty }
    }

    // MARK: Navigation

    func push(_ route: Route, in tab: AppTab? = nil) {
        let t = tab ?? selectedTab
        if t != selectedTab { selectedTab = t }
        paths[t, default: []].append(route)
    }
    func pop(_ tab: AppTab? = nil) { _ = paths[tab ?? selectedTab, default: []].popLast() }
    func popToRoot(_ tab: AppTab? = nil) { paths[tab ?? selectedTab] = [] }
    func binding(for tab: AppTab) -> Binding<[Route]> {
        Binding(get: { self.paths[tab, default: []] }, set: { self.paths[tab] = $0 })
    }

    func show(_ kind: Toast.Kind, _ message: String) {
        withAnimation(.spring(duration: 0.35)) { toast = Toast(kind: kind, message: message) }
        let current = toast
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) { [weak self] in
            if self?.toast == current { withAnimation(.easeOut(duration: 0.25)) { self?.toast = nil } }
        }
    }

    // MARK: Lookups

    func event(_ id: String) -> Event? { events.first { $0.id == id } }
    func client(_ id: String) -> Client? { clients.first { $0.id == id } }
    func client(for event: Event) -> Client? { client(event.clientId) }
    func member(_ id: String) -> CrewMember? { crew.first { $0.id == id } }
    func item(_ id: String) -> InventoryItem? { inventory.first { $0.id == id } }
    func milestones(for eventId: String) -> [Milestone] { milestones.filter { $0.eventId == eventId }.sorted { $0.due < $1.due } }
    func milestone(_ id: String) -> Milestone? { milestones.first { $0.id == id } }

    var upcomingEvents: [Event] { events.filter { $0.status == .upcoming }.sorted { $0.start < $1.start } }
    var completedEvents: [Event] { events.filter { $0.status == .completed }.sorted { $0.start > $1.start } }
    func events(on day: Date) -> [Event] { events.filter { Cal.sameDay($0.start, day) && $0.status != .cancelled }.sorted { $0.start < $1.start } }
    func events(inMonth month: Int, year: Int) -> [Event] {
        upcomingEvents.filter { Cal.month($0.start) == month && Cal.year($0.start) == year }
    }
    /// Events on the same day with overlapping hours (A3, B3, E3 conflict checks).
    func conflicts(on day: Date) -> [Event] {
        let list = events(on: day)
        return list.filter { e in list.contains { $0.id != e.id && $0.start < e.end && e.start < $0.end } }
    }
    var seasonConflict: (Event, Event)? {
        guard let a = event("kapoor-sangeet"), let b = event("gill-engagement"), a.hasCrewConflict, b.hasCrewConflict else { return nil }
        return (a, b)
    }

    // MARK: Money

    func paymentState(for event: Event) -> PaymentState {
        let ms = milestones(for: event.id)
        if ms.contains(where: { $0.status == .overdue }) { return .overdue }
        if ms.allSatisfy({ $0.status == .paid }) && !ms.isEmpty { return .paid }
        if ms.contains(where: { $0.status == .paid }) { return .partial }
        return .pending
    }
    func collected(for eventId: String) -> Int { milestones(for: eventId).filter { $0.status == .paid }.reduce(0) { $0 + $1.amount } }
    func balanceDue(for eventId: String) -> Int { milestones(for: eventId).filter { $0.isOpen }.reduce(0) { $0 + $1.amount } }
    func overdueAmount(for eventId: String) -> Int { milestones(for: eventId).filter { $0.status == .overdue }.reduce(0) { $0 + $1.amount } }

    var openMilestones: [Milestone] { milestones.filter { $0.isOpen }.sorted { $0.due < $1.due } }
    var overdue: [Milestone] {
        openMilestones.filter { $0.status == .overdue || $0.due < Cal.startOfDay(Cal.today) }
            .sorted { (event($0.eventId)?.start ?? $0.due) < (event($1.eventId)?.start ?? $1.due) }
    }
    var dueThisWeek: [Milestone] {
        let w = Cal.thisWeek
        return openMilestones.filter { !overdue.contains($0) && w.contains($0.due) }
    }
    var upcomingMilestones: [Milestone] { openMilestones.filter { !overdue.contains($0) && !dueThisWeek.contains($0) } }
    var totalOutstanding: Int { openMilestones.reduce(0) { $0 + $1.amount } }
    var overdueTotal: Int { overdue.reduce(0) { $0 + $1.amount } }
    var eventsWithOpenMoney: Int { Set(openMilestones.map(\.eventId)).count }
    var overdueSurnames: String {
        var seen: [String] = []
        for m in overdue.sorted(by: { $0.amount > $1.amount }) { if let e = event(m.eventId), !seen.contains(e.surname) { seen.append(e.surname) } }
        return seen.joined(separator: ", ")
    }

    func recordPayment(milestoneId: String, amount: Int, method: PaymentMethod, date: Date, reference: String?) {
        guard let i = milestones.firstIndex(where: { $0.id == milestoneId }) else { return }
        milestones[i].status = .paid
        milestones[i].paidOn = date
        milestones[i].method = method
        milestones[i].reference = reference
        if amount < milestones[i].amount {
            // Partial payment: split the remainder into a new pending milestone.
            let rest = milestones[i].amount - amount
            milestones[i].amount = amount
            var remainder = milestones[i]
            remainder.id = milestoneId + "-rest"; remainder.amount = rest; remainder.status = .pending; remainder.paidOn = nil; remainder.method = nil; remainder.reference = nil
            milestones.insert(remainder, at: i + 1)
        }
        show(.success, "Recorded \(Fmt.inr(amount))")
    }

    func sendReminder(milestoneId: String, tone: ReminderTone, channel: ReminderChannel) {
        sentReminders[milestoneId, default: []].append(SentReminder(id: UUID().uuidString, tone: tone, sent: Cal.today, channel: channel, outcome: channel == .whatsapp ? "sent" : "delivered"))
        show(.success, "Sent on \(channel.rawValue)")
    }

    /// Composed reminder copy — real text for each tone (spec C4, NOTES Phase 4).
    func reminderMessage(for m: Milestone, tone: ReminderTone) -> String {
        guard let e = event(m.eventId), let c = client(for: e) else { return "" }
        let first = c.name.split(separator: " ").first.map(String.init) ?? c.name
        let amount = Fmt.inr(m.amount)
        let due = Fmt.dayMonthLong.string(from: m.due)
        let eventDate = Fmt.dayMonthLong.string(from: e.start)
        let name = m.name.lowercased()
        switch tone {
        case .gentle:
            return "Hi \(first), hope the preparations are going well! Just a gentle nudge — the \(name) of \(amount) for the \(e.type.rawValue) was due on \(due). Whenever convenient this week works. Thanks so much — \(Seed.vendorFirstName), \(Seed.businessName)"
        case .standard:
            return "Hi \(first), a reminder that the \(name) of \(amount) for the \(e.type.rawValue) on \(eventDate) was due on \(due). You can pay by UPI to \(Seed.upi) or by bank transfer. Thank you — \(Seed.vendorFirstName), \(Seed.businessName)"
        case .firm:
            return "\(first), the \(name) of \(amount) for the \(e.type.rawValue) on \(eventDate) is \(Fmt.daysLate(m.due)) days overdue. We need it cleared by tomorrow to hold the crew and inventory for your date. Please pay by UPI to \(Seed.upi) today. — \(Seed.vendorFirstName), \(Seed.businessName)"
        }
    }

    // MARK: Events

    func toggleTask(_ id: String) {
        guard let i = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[i].done.toggle()
        syncRunsheetSummary(eventId: tasks[i].eventId)
    }
    func moveTask(from: IndexSet, to: Int, in block: String, eventId: String) {
        var blockTasks = tasks.filter { $0.eventId == eventId && $0.block == block }
        blockTasks.move(fromOffsets: from, toOffset: to)
        let others = tasks.filter { !($0.eventId == eventId && $0.block == block) }
        tasks = others + blockTasks
        tasks.sort { a, b in
            let order = ["Setup": 0, "Dressing": 1, "Event": 2]
            return (order[a.block] ?? 9) < (order[b.block] ?? 9)
        }
    }
    func addTask(eventId: String, block: String, title: String, crew: String) {
        let blockTime = tasks.first { $0.eventId == eventId && $0.block == block }?.blockTime ?? ""
        tasks.append(RunsheetTask(id: UUID().uuidString, eventId: eventId, block: block, blockTime: blockTime, title: title, crew: crew, duration: "—", done: false))
        syncRunsheetSummary(eventId: eventId)
        show(.success, "Task added")
    }
    private func syncRunsheetSummary(eventId: String) {
        guard let i = events.firstIndex(where: { $0.id == eventId }) else { return }
        let ts = tasks.filter { $0.eventId == eventId }
        events[i].runsheetSummary = "\(ts.count) tasks · setup 09:00 · \(ts.filter(\.done).count) done"
    }

    func approveChangeRequest(eventId: String) {
        guard let i = events.firstIndex(where: { $0.id == eventId }) else { return }
        events[i].guests = 650
        events[i].quoted = 710_000
        events[i].inventorySummary = "500 chairs · 120 drapes · 24 par cans"
        pendingChangeRequest = false
        show(.success, "Revised quote sent to Vikram")
    }
    func declineChangeRequest() { pendingChangeRequest = false; show(.info, "Change declined") }

    func cancelEvent(_ id: String) {
        guard let i = events.firstIndex(where: { $0.id == id }) else { return }
        events[i].status = .cancelled
        show(.info, "\(events[i].name) cancelled")
    }

    func createEvent(from d: EventDraft) -> Event? {
        guard let type = d.type, let date = d.date, !d.clientName.isEmpty else { return nil }
        let surname = d.clientName.split(separator: " ").last.map(String.init) ?? d.clientName
        let hue = EventHue(rawValue: (events.count % 4) + 1) ?? .one
        let clientId: String
        if let existing = clients.first(where: { $0.surname.lowercased() == surname.lowercased() }) { clientId = existing.id }
        else {
            clientId = surname.lowercased() + "-\(clients.count)"
            clients.append(Client(id: clientId, name: d.clientName, phone: d.phone, isRepeat: false, eventCount: 1, lifetimeValue: d.quoted, nextEventDate: date, avatar: (clients.count % 8) + 1))
        }
        let start = Cal.calendar.date(bySettingHour: 18, minute: 0, second: 0, of: date) ?? date
        let end = Cal.adding(5, .hour, to: start)
        let venueParts = d.venue.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        let venue = Venue(name: venueParts.first ?? d.venue, area: venueParts.dropFirst().first ?? "", hall: nil)
        let e = Event(id: "\(surname.lowercased())-\(type.rawValue)-\(Int(date.timeIntervalSince1970))", name: "\(surname) \(type.rawValue)", clientId: clientId, type: type,
                      start: start, end: end, venue: venue, guests: d.guests, quoted: d.quoted, hue: hue, status: .upcoming,
                      crewAssigned: 0, crewNeeded: max(6, d.guests / 40), hasCrewConflict: !conflicts(on: date).isEmpty,
                      inventorySummary: "Not planned yet", runsheetSummary: "No tasks yet")
        events.append(e)
        milestones.append(Milestone(id: e.id + "-adv", eventId: e.id, name: "Booking advance", amount: d.quoted / 4, due: Cal.today, status: .pending, paidOn: nil, method: nil, reference: nil, kind: .advance))
        milestones.append(Milestone(id: e.id + "-bal", eventId: e.id, name: "Balance", amount: d.quoted - d.quoted / 4, due: date, status: .pending, paidOn: nil, method: nil, reference: nil, kind: .balance))
        draft = .empty
        show(.success, "\(e.name) created")
        return e
    }

    // MARK: Crew

    func attendance(for eventId: String) -> [String: AttendanceState] { attendance[eventId] ?? [:] }
    func cycleAttendance(eventId: String, crewId: String) {
        let current = attendance[eventId]?[crewId] ?? .confirmed
        attendance[eventId, default: [:]][crewId] = current.next
    }
    func assignedCrew(for eventId: String) -> [CrewMember] { crew.filter { $0.bookedOn.contains(eventId) } }
    func toggleAssignment(crewId: String, eventId: String) {
        guard let i = crew.firstIndex(where: { $0.id == crewId }) else { return }
        if crew[i].bookedOn.contains(eventId) { crew[i].bookedOn.removeAll { $0 == eventId } } else { crew[i].bookedOn.append(eventId) }
        if let ei = events.firstIndex(where: { $0.id == eventId }) { events[ei].crewAssigned += crew[i].bookedOn.contains(eventId) ? 1 : -1 }
    }
    /// D2 comparison outcome: move Suresh's team off the other event.
    func moveTeam(crewId: String, to eventId: String, from otherId: String) {
        guard let i = crew.firstIndex(where: { $0.id == crewId }) else { return }
        crew[i].bookedOn.removeAll { $0 == otherId }
        if !crew[i].bookedOn.contains(eventId) { crew[i].bookedOn.append(eventId) }
        for idx in events.indices where events[idx].id == eventId || events[idx].id == otherId { events[idx].hasCrewConflict = false }
        show(.success, "\(crew[i].firstName)'s team moved to \(event(eventId)?.surname ?? "")")
    }
    /// "Suresh's team conflicted" when a roster member is booked on this and another event that day; otherwise the
    /// same-day events by surname; nil when there is nothing to flag.
    func crewConflictNote(for e: Event) -> String? {
        let others = events(on: e.start).filter { $0.id != e.id }
        guard !others.isEmpty else { return nil }
        if let m = crew.first(where: { m in m.bookedOn.contains(e.id) && m.bookedOn.contains { others.map(\.id).contains($0) } }) {
            return "\(m.firstName)'s team conflicted"
        }
        return e.hasCrewConflict ? "same day as \(others.map(\.surname).joined(separator: " · "))" : nil
    }
    func crewOnDuty(_ day: Date) -> Int {
        let ids = events(on: day).map(\.id)
        return crew.filter { m in m.bookedOn.contains { ids.contains($0) } }.count
    }
}
