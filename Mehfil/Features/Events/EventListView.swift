import SwiftUI

enum EventSegment: String, CaseIterable, Identifiable {
    case upcoming = "Upcoming", enquiry = "Enquiry", completed = "Completed"
    var id: String { rawValue }
}

/// B1 · Event list — segmented, grouped under month headers, floating create action.
struct EventListView: View {
    @Environment(AppStore.self) private var store
    @State private var segment: EventSegment = .upcoming
    @State private var searching = false
    @State private var query = ""

    private var upcoming: [Event] { store.upcomingEvents.filter { query.isEmpty || $0.name.localizedCaseInsensitiveContains(query) || $0.venue.short.localizedCaseInsensitiveContains(query) } }
    private var completed: [Event] { store.completedEvents.filter { query.isEmpty || $0.name.localizedCaseInsensitiveContains(query) } }
    private var groups: [(String, [Event])] {
        let list = segment == .completed ? completed : upcoming
        var order: [String] = []; var dict: [String: [Event]] = [:]
        for e in list {
            let k = Fmt.monthYear.string(from: e.start).components(separatedBy: " ").first ?? ""
            if dict[k] == nil { order.append(k) }
            dict[k, default: []].append(e)
        }
        return order.map { ($0, dict[$0] ?? []) }
    }

    var body: some View {
        ScreenScaffold(title: "Events", subtitle: upcoming.isEmpty ? "Nothing booked yet" : "\(upcoming.count) upcoming · \(Fmt.inr(upcoming.reduce(0) { $0 + $1.quoted })) booked", isRoot: true, spacing: Space.lg, bottomPadding: 96,
                       headerTrailing: AnyView(GlassIconButton(symbol: searching ? "xmark" : "magnifyingglass") { withAnimation(.snappy(duration: 0.25)) { searching.toggle(); if !searching { query = "" } } })) {
            if searching {
                InputField(label: "Search", text: $query, placeholder: "Event, client or venue", trailing: "magnifyingglass")
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            SegmentedControl(items: EventSegment.allCases, label: \.rawValue, selection: $segment)

            switch segment {
            case .upcoming, .completed:
                if groups.isEmpty {
                    EmptyState(headline: segment == .upcoming ? "No events yet" : "Nothing completed yet",
                               line: segment == .upcoming ? "Bookings you create will appear here with their date, venue and balance." : "Events move here after their date passes.",
                               actionTitle: segment == .upcoming ? "Create event" : nil, actionIcon: "plus", primary: true) { store.push(.createEvent) }
                        .padding(.top, 160)
                } else {
                    ForEach(groups, id: \.0) { name, evs in
                        VStack(spacing: Space.md) {
                            SectionHeading(title: name, trailing: "\(evs.count) events · \(Fmt.inr(evs.reduce(0) { $0 + $1.quoted }))")
                            ForEach(evs) { e in
                                EventCard(event: e, client: store.client(for: e), paymentState: store.paymentState(for: e)) { store.push(.eventDetail(e.id)) }
                            }
                        }
                    }
                }
            case .enquiry:
                enquiries
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if segment != .completed {
                FloatingAction(title: segment == .enquiry ? "New enquiry" : "New event") { store.push(segment == .enquiry ? .enquiry : .createEvent) }
                    .padding(.trailing, Dim.gutter).padding(.bottom, Space.lg)
            }
        }
    }

    private var enquiries: some View {
        VStack(spacing: Space.md) {
            SectionHeading(title: "Open", trailing: "\(Seed.openEnquiries) enquiries")
            RowGroup {
                enquiryRow(name: Seed.enquiry.name, detail: "\(Seed.enquiry.source) · \(Fmt.weekdayDayMonth.string(from: Seed.enquiry.date!))", value: Seed.enquiry.budget)
                Hairline()
                enquiryRow(name: "Neha Bhatia", detail: "Instagram · Sat 16 Jan", value: "₹1,50,000 – ₹3,00,000")
                Hairline()
                enquiryRow(name: "Rohan Kapadia", detail: "Wedding planner · Sat 30 Jan", value: "Over ₹10,00,000")
            }
        }
    }
    private func enquiryRow(name: String, detail: String, value: String) -> some View {
        Button { store.push(.enquiry) } label: {
            ListRow(title: name, subtitle: detail) {
                IconTile(symbol: "envelope")
            } trailing: {
                HStack(spacing: Space.sm) { Text(value).type(.caption).foregroundStyle(MColor.textMute); Chevron() }
            }
        }
        .buttonStyle(.plain)
    }
}

/// B2 · Event detail — the hub for one event. Densest screen in the app.
struct EventDetailView: View {
    @Environment(AppStore.self) private var store
    var eventId: String
    @State private var paymentsExpanded = false
    @State private var recordSheet: Milestone?
    @State private var cancelConfirm = false

    var body: some View {
        if let e = store.event(eventId) {
            let client = store.client(for: e)
            let balance = store.balanceDue(for: e.id)
            let overdue = store.overdueAmount(for: e.id)
            ScreenScaffold(title: e.name, heroHeader: true, spacing: Space.lg) {
                // Hero
                VStack(alignment: .leading, spacing: Space.xs) {
                    HStack(alignment: .top, spacing: Space.md) {
                        RoundedRectangle(cornerRadius: 2).fill(MColor.event(e.hue)).frame(width: Dim.edge)
                        VStack(alignment: .leading, spacing: Space.xs) {
                            Text(e.name).type(.displayMd).foregroundStyle(MColor.text)
                            Text("\(Fmt.weekdayLong.string(from: e.start)) · \(Fmt.timeRange(e.start, e.end))").type(.bodyMd).foregroundStyle(MColor.textSecondary)
                            Text([e.venue.short, e.venue.hall].compactMap { $0 }.joined(separator: " · ")).type(.caption).foregroundStyle(MColor.textMute)
                            HStack(spacing: Space.sm) {
                                if !e.isCompleted {
                                    HStack(spacing: Space.xs) {
                                        Image(systemName: "clock").font(.system(size: 11))
                                        Text(Fmt.relativeDays(e.start).prefix(1).uppercased() + Fmt.relativeDays(e.start).dropFirst()).type(.caption)
                                    }
                                    .foregroundStyle(MColor.text).padding(.horizontal, 10).frame(height: 28)
                                    .overlay(Capsule().strokeBorder(MColor.line, lineWidth: 1))
                                }
                                if e.hasCrewConflict { StatusChip(kind: .conflict) }
                                if e.status == .cancelled { StatusChip(kind: .cancelled) }
                            }
                            .padding(.top, Space.xs)
                        }
                    }
                }

                if store.pendingChangeRequest && e.id == "kapoor-sangeet" {
                    Button { store.push(.changeRequest(e.id)) } label: {
                        HStack(spacing: Space.md) {
                            Image(systemName: "arrow.triangle.2.circlepath").font(.system(size: 18, weight: .light)).foregroundStyle(MColor.accentText).frame(width: Dim.icon)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Change request from \(client?.name ?? "the client")").type(.bodyMdStrong).foregroundStyle(MColor.text)
                                Text("Add 200 guests · today 08:12 · see what it moves").type(.caption).foregroundStyle(MColor.textMute)
                            }
                            Spacer(); Chevron()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading).card(fill: MColor.accentTint)
                    }
                    .buttonStyle(PressableCardStyle())
                }

                // Summary tiles
                LazyVGrid(columns: [GridItem(.flexible(), spacing: Space.md), GridItem(.flexible(), spacing: Space.md)], spacing: Space.md) {
                    StatTile(figure: "\(e.guests)", label: "Guests")
                    StatTile(figure: Fmt.inr(e.quoted), label: "Quoted")
                    StatTile(figure: "\(e.crewAssigned) of \(e.crewNeeded)", label: "Crew assigned")
                    StatTile(figure: Fmt.inr(balance), label: overdue > 0 ? "Balance due · \(Fmt.inr(overdue)) overdue" : "Balance due", figureColor: overdue > 0 ? MColor.danger : MColor.text)
                }

                // Sections
                RowGroup {
                    sectionRow(symbol: "creditcard", title: "Payments", summary: "\(Fmt.inr(store.collected(for: e.id))) of \(Fmt.inr(e.quoted))" + (overdue > 0 ? " · 1 overdue" : ""), expanded: paymentsExpanded) {
                        withAnimation(.snappy(duration: 0.3)) { paymentsExpanded.toggle() }
                    }
                    if paymentsExpanded { paymentsBlock(e) }
                    Hairline()
                    sectionRow(symbol: "person.2", title: "Crew", summary: "\(e.crewAssigned) of \(e.crewNeeded) · \(store.crewConflictNote(for: e) ?? "assigned")") { store.push(.assignCrew(e.id)) }
                    Hairline()
                    sectionRow(symbol: "shippingbox", title: "Inventory", summary: e.inventorySummary) { store.push(.inventory) }
                    Hairline()
                    sectionRow(symbol: "list.bullet.rectangle", title: "Runsheet", summary: e.runsheetSummary) { store.push(.runsheet(e.id)) }
                }

                if let client {
                    ContactRow(client: client, note: "\(client.phone) · \(client.isRepeat ? "repeat client" : "first event")")
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { store.push(.sharedPage(e.id)) } label: { Image(systemName: "square.and.arrow.up") }
                    Menu {
                        Button("Edit event", systemImage: "pencil") { store.push(.createEvent) }
                        Button("Duplicate", systemImage: "plus.square.on.square") { store.show(.info, "Duplicated as a draft") }
                        Button("Expenses", systemImage: "indianrupeesign") { store.push(.expenses(e.id)) }
                        if store.pendingChangeRequest && e.id == "kapoor-sangeet" { Button("Change request", systemImage: "arrow.triangle.2.circlepath") { store.push(.changeRequest(e.id)) } }
                        Divider()
                        Button("Cancel event", systemImage: "xmark.circle", role: .destructive) { cancelConfirm = true }
                    } label: { Image(systemName: "ellipsis") }
                }
            }
            .sheet(item: $recordSheet) { m in
                RecordPaymentSheet(milestone: m).presentationDetents([.large])
            }
            .sheet(isPresented: $cancelConfirm) {
                // Destructive confirmation names the specific thing being destroyed (spec §5).
                SheetScaffold(title: "Cancel the \(e.name) on \(Fmt.dayMonthLong.string(from: e.start))?",
                              subtitle: "\(e.crewAssigned) crew and the inventory holds are released. \(client?.name ?? "The client") is not notified automatically.") {
                    EmptyView()
                } actions: {
                    VStack(spacing: Space.sm) {
                        MButton(title: "Cancel the \(e.type.rawValue)", style: .destructive) { store.cancelEvent(e.id); cancelConfirm = false; store.pop() }
                        MButton(title: "Keep it", style: .tertiary, size: .compact) { cancelConfirm = false }
                    }
                }
                .presentationDetents([.medium])
            }
        } else {
            ContentUnavailableView("Event not found", systemImage: "calendar.badge.exclamationmark")
        }
    }

    private func sectionRow(symbol: String, title: String, summary: String, expanded: Bool? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ListRow(title: title, subtitle: summary) {
                IconTile(symbol: symbol)
            } trailing: {
                Image(systemName: "chevron.right").font(.system(size: 14)).foregroundStyle(MColor.textMute)
                    .rotationEffect(.degrees(expanded == true ? 90 : 0))
            }
        }
        .buttonStyle(.plain)
    }

    private func paymentsBlock(_ e: Event) -> some View {
        VStack(spacing: 0) {
            ForEach(store.milestones(for: e.id)) { m in
                Hairline()
                PaymentRow(milestone: m, subtitle: paymentSubtitle(m), subtitleColor: m.status == .overdue ? MColor.danger : MColor.textMute) {
                    if m.isOpen { recordSheet = m }
                }
            }
            HStack(spacing: Space.md) {
                MButton(title: "Record payment", icon: "indianrupeesign", style: .secondary, size: .compact) {
                    if let next = store.milestones(for: e.id).first(where: \.isOpen) { recordSheet = next }
                }
                Button { store.push(.paymentSchedule(e.id)) } label: { Text("Schedule").type(.buttonSm).foregroundStyle(MColor.accentText) }.buttonStyle(.plain)
            }
            .padding(Space.lg)
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private func paymentSubtitle(_ m: Milestone) -> String {
        switch m.status {
        case .paid: return "Paid \(Fmt.weekdayDayMonth.string(from: m.paidOn ?? m.due))" + (m.method.map { " · \($0.rawValue)" } ?? "")
        case .overdue: return "Due \(Fmt.weekdayDayMonth.string(from: m.due)) · \(Fmt.daysLate(m.due)) days late"
        case .pending: return "Due \(Fmt.weekdayDayMonth.string(from: m.due)) · \(Fmt.relativeDays(m.due))"
        }
    }
}
