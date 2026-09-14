import SwiftUI

/// E4 · Profile and settings — deliberately short.
struct ProfileView: View {
    @Environment(AppStore.self) private var store
    @State private var appearanceSheet = false

    var body: some View {
        @Bindable var store = store
        let repeatCount = store.clients.filter(\.isRepeat).count
        ScreenScaffold(title: "Profile", subtitle: "\(Seed.businessName) · Gurugram", isRoot: true, spacing: Space.lg) {
            HStack(spacing: Space.md) {
                Text("M").type(.headingLg).foregroundStyle(MColor.emphasisText)
                    .frame(width: 48, height: 48).background(MColor.emphasisBg, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(Seed.businessName).type(.headingSm).foregroundStyle(MColor.text)
                    Text("\(Seed.vendorName) · \(Seed.businessArea) · \(Seed.businessSince)").type(.caption).foregroundStyle(MColor.textMute)
                }
                Spacer()
                Chevron()
            }
            .frame(maxWidth: .infinity, alignment: .leading).card()

            RowGroup {
                row("person.2", "Team", "\(store.crew.count + 1) members · \(store.crew.filter { $0.role == .coordinator }.count) coordinators") { store.push(.crewList) }
                Hairline(inset: 68)
                row("person", "Clients", "\(store.clients.count) clients · \(repeatCount) repeat") { store.push(.clients) }
                Hairline(inset: 68)
                row("square.stack.3d.up", "Package templates", "\(Seed.packages.count + 2) templates · from \(Fmt.inr(Seed.packages.map(\.price).min() ?? 0))") { store.show(.info, "Templates are coming with the next release") }
                Hairline(inset: 68)
                row("creditcard", "Payment details", "UPI \(Seed.upi) · \(Seed.bank)") { store.show(.info, "Payment details are managed by your accountant") }
                Hairline(inset: 68)
                row("sun.max", "Appearance", store.appearance == .system ? "\(currentSchemeLabel) · follows system" : store.appearance.label) { appearanceSheet = true }
                Hairline(inset: 68)
                row("bell", "Notifications", "Payments, conflicts, change requests") { store.show(.info, "All three alert types are on") }
            }
        }
        .sheet(isPresented: $appearanceSheet) {
            SheetScaffold(title: "Appearance") {
                RowGroup {
                    ForEach(Array(Appearance.allCases.enumerated()), id: \.element.id) { i, a in
                        if i > 0 { Hairline() }
                        Button { store.appearance = a } label: {
                            ListRow(title: a.label, selected: store.appearance == a) { EmptyView() } trailing: {
                                if store.appearance == a { Image(systemName: "checkmark").foregroundStyle(MColor.accentText) }
                            }
                        }.buttonStyle(.plain)
                    }
                }
            } actions: { MButton(title: "Done") { appearanceSheet = false } }
            .presentationDetents([.medium])
        }
    }

    @Environment(\.colorScheme) private var scheme
    private var currentSchemeLabel: String { scheme == .dark ? "Dark" : "Light" }

    private func row(_ symbol: String, _ title: String, _ subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ListRow(title: title, subtitle: subtitle) { IconTile(symbol: symbol) } trailing: { Chevron() }
        }
        .buttonStyle(.plain)
    }
}

/// E1 · Client list — search, rows with event count and lifetime value; repeat clients carry a marker.
struct ClientListView: View {
    @Environment(AppStore.self) private var store
    @State private var query = ""

    var body: some View {
        let list = store.clients.filter { query.isEmpty || $0.name.localizedCaseInsensitiveContains(query) || $0.phone.contains(query) }
            .sorted { $0.lifetimeValue > $1.lifetimeValue }
        let lifetime = store.clients.reduce(0) { $0 + $1.lifetimeValue }
        let repeatCount = store.clients.filter(\.isRepeat).count
        ScreenScaffold(title: "Clients", subtitle: store.clients.isEmpty ? "No clients yet" : "\(store.clients.count) clients · \(Fmt.inr(lifetime)) lifetime", spacing: Space.lg) {
            if store.clients.isEmpty {
                EmptyState(headline: "No clients yet", line: "Each client is added with their first event or enquiry.", actionTitle: "Create event") { store.push(.createEvent, in: .events) }
                    .padding(.top, 140)
            } else {
                HStack(spacing: Space.md) {
                    StatTile(figure: "\(repeatCount) of \(store.clients.count)", label: "Repeat clients")
                    StatTile(figure: Fmt.inr(store.clients.isEmpty ? 0 : lifetime / store.clients.count / 100 * 100), label: "Average lifetime value")
                }
                RowGroup {
                    ForEach(Array(list.enumerated()), id: \.element.id) { i, c in
                        if i > 0 { Hairline(inset: 68) }
                        Button {
                            if let e = store.upcomingEvents.first(where: { $0.clientId == c.id }) ?? store.events.first(where: { $0.clientId == c.id }) { store.push(.eventDetail(e.id)) }
                        } label: {
                            ListRow(title: c.name, subtitle: "\(c.eventCount) event\(c.eventCount == 1 ? "" : "s")" + (c.nextEventDate.map { " · next \(Fmt.dayMonth.string(from: $0))" } ?? "")) {
                                Avatar(index: c.avatar, name: c.name)
                            } trailing: {
                                HStack(spacing: Space.sm) {
                                    if c.isRepeat { Image(systemName: "star").font(.system(size: 11)).foregroundStyle(MColor.accentText) }
                                    Money(c.lifetimeValue)
                                    Chevron()
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .searchable(text: $query, prompt: "Search by name or phone")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { Button { store.push(.enquiry) } label: { Image(systemName: "plus") } }
        }
    }
}

/// E3 · Enquiry intake — conflict check on the tentative date, convert to event.
struct EnquiryIntakeView: View {
    @Environment(AppStore.self) private var store
    @State private var name = Seed.enquiry.name
    @State private var source = Seed.enquiry.source
    @State private var budget = Seed.enquiry.budget
    @State private var date: Date? = Seed.enquiry.date
    @State private var guests = Seed.enquiry.guests
    @State private var notes = Seed.enquiry.notes
    @State private var showDate = false
    @State private var showSource = false
    @State private var showBudget = false
    @FocusState private var notesFocused: Bool

    private var conflicts: [Event] { date.map { store.events(on: $0) } ?? [] }

    var body: some View {
        ScreenScaffold(title: "New enquiry", largeTitle: false, spacing: Space.lg, bottomPadding: 100) {
            InputField(label: "Name", text: $name, placeholder: "Who is asking")
            PickerField(label: "Source", value: source) { showSource = true }
            PickerField(label: "Budget range", value: budget) { showBudget = true }
            PickerField(label: "Tentative date", value: date.map { Fmt.weekdayLongYear.string(from: $0) } ?? "", placeholder: "Pick a date", trailing: "calendar", highlighted: date != nil) { showDate = true }
            if let d = date, !conflicts.isEmpty {
                let c = conflicts[0]
                InlineConflictWarning(sentence: conflicts.count == 1 ? "\(c.name) runs that evening at \(c.venue.name) with \(c.crewAssigned) crew." : "\(conflicts.count) events already run on \(Fmt.dayMonth.string(from: d)).",
                                      events: conflicts, linkTitle: "See \(Fmt.dayMonth.string(from: d)) timeline") { store.push(.dayDetail(d)) }
            }
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Guest estimate").type(.bodyMd).foregroundStyle(MColor.text)
                    Text("Rough is fine").type(.caption).foregroundStyle(MColor.textMute)
                }
                Spacer()
                MStepper(value: $guests, range: 10...5000, step: 10)
            }
            VStack(alignment: .leading, spacing: Space.sm) {
                Text("Notes").type(.caption).foregroundStyle(MColor.textMute)
                TextEditor(text: $notes).type(.bodyMd).foregroundStyle(MColor.text).scrollContentBackground(.hidden).focused($notesFocused)
                    .frame(minHeight: 72).padding(Space.sm)
                    .background(MColor.surface, in: RoundedRectangle(cornerRadius: Radius.sm, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: Radius.sm, style: .continuous).strokeBorder(notesFocused ? MColor.accent : MColor.lineInput, lineWidth: 1))
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { Button("Save") { store.show(.success, "Enquiry saved"); store.pop() }.type(.buttonSm) }
        }
        .dockedActions {
            MButton(title: "Convert to event") {
                store.draft = EventDraft(clientName: name, phone: "", type: .engagement, date: date, venue: "", guests: guests, packageIds: [], quoted: 0)
                store.pop(); store.push(.createEvent, in: .events)
            }
            .disabled(name.isEmpty)
        }
        .sheet(isPresented: $showDate) {
            SheetScaffold(title: "Tentative date", subtitle: "Conflicts are checked as soon as you pick.") {
                DatePicker("Date", selection: Binding(get: { date ?? Cal.date(2026, 12, 5) }, set: { date = Cal.startOfDay($0) }), displayedComponents: .date)
                    .datePickerStyle(.graphical).tint(MColor.accent).environment(\.calendar, Cal.calendar)
            } actions: { MButton(title: "Done") { showDate = false } }
            .presentationDetents([.large])
        }
        .sheet(isPresented: $showSource) { choiceSheet("Source", Seed.enquirySources, $source, $showSource) }
        .sheet(isPresented: $showBudget) { choiceSheet("Budget range", Seed.budgetRanges, $budget, $showBudget) }
    }

    private func choiceSheet(_ title: String, _ options: [String], _ value: Binding<String>, _ shown: Binding<Bool>) -> some View {
        SheetScaffold(title: title) {
            RowGroup {
                ForEach(Array(options.enumerated()), id: \.offset) { i, o in
                    if i > 0 { Hairline() }
                    Button { value.wrappedValue = o; shown.wrappedValue = false } label: {
                        ListRow(title: o, selected: value.wrappedValue == o) { EmptyView() } trailing: {
                            if value.wrappedValue == o { Image(systemName: "checkmark").foregroundStyle(MColor.accentText) }
                        }
                    }.buttonStyle(.plain)
                }
            }
        } actions: { EmptyView() }
        .presentationDetents([.medium])
    }
}

/// E2 · Shared event page — the read-only view the vendor sends the client. Cream ground, the only gradient mesh,
/// no chips or tiles from the vendor side. Always light: it is the client's page (NOTES Phase 6).
struct SharedEventPageView: View {
    @Environment(AppStore.self) private var store
    var eventId: String

    var body: some View {
        if let e = store.event(eventId), let client = store.client(for: e) {
            let collected = store.collected(for: e.id)
            let due = store.milestones(for: e.id).filter(\.isOpen)
            ScrollView {
                VStack(alignment: .leading, spacing: Space.xl) {
                    VStack(alignment: .leading, spacing: Space.sm) {
                        Text("\(Seed.businessName.uppercased()) · FOR THE \(e.surname.uppercased()) FAMILY").type(.microCap).foregroundStyle(Palette.inkMute).tracking(0.6)
                        Text(e.name).type(.displayHero).foregroundStyle(Palette.ink)
                        Text("\(Fmt.weekdayLong.string(from: e.start)) · from \(Fmt.time.string(from: e.start))").type(.bodyLg).foregroundStyle(Palette.ink)
                        Text([e.venue.short, e.venue.hall].compactMap { $0 }.joined(separator: " · ")).type(.bodyLg).foregroundStyle(Palette.inkSecondary)
                    }
                    .padding(.top, Space.lg)

                    section("What we are bringing") {
                        line("Stage with 12 m floral backdrop", "40 lights")
                        line("Marigold and jasmine mandap", "fresh")
                        line("Velvet ceiling drapes, 120 panels", "ivory")
                        line("Seating for \(e.guests) with \(store.item("tables")?.holds.first { $0.eventId == e.id }?.qty ?? 45) round tables", "")
                    }
                    section("On the day") {
                        line("Setup begins", "09:00")
                        line("Venue ready for your walkthrough", "16:30")
                        line("Guests arrive", Fmt.time.string(from: e.start))
                        line("Pack-down", Fmt.time.string(from: e.end))
                    }

                    VStack(alignment: .leading, spacing: Space.sm) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("Received").type(.bodyLg).foregroundStyle(Palette.ink)
                            Spacer()
                            Text("\(Fmt.inr(collected)) of \(Fmt.inr(e.quoted))").type(.bodyLg).foregroundStyle(Palette.ink).monospacedDigit()
                        }
                        GeometryReader { g in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Palette.ink.opacity(0.12))
                                Capsule().fill(Palette.ink).frame(width: g.size.width * CGFloat(collected) / CGFloat(max(1, e.quoted)))
                            }
                        }.frame(height: 4)
                        Text(due.map { "\(Fmt.inr($0.amount)) \($0.due <= Cal.today ? "due now" : ($0.kind == .balance ? "on the day" : "by \(Fmt.dayMonth.string(from: $0.due))"))" }.joined(separator: " · ") + " · UPI \(Seed.upi)")
                            .type(.caption).foregroundStyle(Palette.inkMute).fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(Space.lg).background(Palette.canvasCream, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).strokeBorder(Palette.lemon.opacity(0.25), lineWidth: 1))

                    HStack(spacing: Space.sm) {
                        ForEach(1...3, id: \.self) { i in
                            Image("mood-\(i)").resizable().aspectRatio(4/3, contentMode: .fill)
                                .frame(maxWidth: .infinity).clipShape(RoundedRectangle(cornerRadius: Radius.sm, style: .continuous))
                        }
                    }

                    HStack(spacing: Space.md) {
                        Text("M").type(.headingSm).foregroundStyle(Palette.onPrimary).frame(width: 36, height: 36).background(Palette.brandDark, in: RoundedRectangle(cornerRadius: Radius.sm, style: .continuous))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(Seed.vendorName) · \(Seed.businessName)").type(.bodyMdStrong).foregroundStyle(Palette.ink).lineLimit(1).minimumScaleFactor(0.8)
                            Text("\(Seed.businessPhone) · \(Seed.businessArea)").type(.caption).foregroundStyle(Palette.inkMute).lineLimit(1).minimumScaleFactor(0.8)
                        }
                        .layoutPriority(1)
                        Spacer(minLength: Space.sm)
                        Button {
                            if let u = URL(string: "https://wa.me/91\(Seed.businessPhone.replacingOccurrences(of: " ", with: ""))") { UIApplication.shared.open(u) }
                        } label: {
                            HStack(spacing: Space.xs) { Image(systemName: "bubble").font(.system(size: 14)); Text("Chat").type(.buttonSm) }
                                .foregroundStyle(Palette.ink).padding(.horizontal, Space.md).frame(height: 40)
                                .overlay(Capsule().strokeBorder(Palette.ink, lineWidth: 1))
                        }.buttonStyle(.plain)
                    }
                    .padding(.bottom, Space.xl)
                }
                .padding(.horizontal, Space.xl)
            }
            .background(mesh.ignoresSafeArea())
            .environment(\.colorScheme, .light)
            .toolbarColorScheme(.light, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: URL(string: "https://mehfil.app/e/\(e.id)")!, subject: Text(e.name), message: Text("Your \(e.type.rawValue) plan from \(Seed.businessName)")) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
    }

    private var mesh: some View {
        ZStack {
            Palette.canvasCream
            RadialGradient(colors: [Palette.primarySubdued.opacity(0.85), .clear], center: .init(x: 0.85, y: 0.12), startRadius: 0, endRadius: 320)
            RadialGradient(colors: [Palette.magenta.opacity(0.42), .clear], center: .init(x: 0.25, y: 0.18), startRadius: 0, endRadius: 260)
            RadialGradient(colors: [Palette.primarySoft.opacity(0.20), .clear], center: .init(x: 0.6, y: 0.3), startRadius: 0, endRadius: 300)
            RadialGradient(colors: [Palette.ruby.opacity(0.14), .clear], center: .init(x: 0.1, y: 0.05), startRadius: 0, endRadius: 220)
            RadialGradient(colors: [Palette.lemon.opacity(0.16), .clear], center: .init(x: 0.9, y: 0.35), startRadius: 0, endRadius: 240)
            LinearGradient(colors: [.clear, Palette.canvasCream.opacity(0.7), Palette.canvasCream], startPoint: .init(x: 0.5, y: 0.25), endPoint: .init(x: 0.5, y: 0.6))
        }
    }

    private func section<C: View>(_ title: String, @ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            Text(title).type(.headingSm).foregroundStyle(Palette.ink)
            content()
        }
    }
    private func line(_ l: String, _ r: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(l).type(.bodyLg).foregroundStyle(Palette.ink)
            Spacer()
            Text(r).type(.bodyLg).foregroundStyle(Palette.inkMute).monospacedDigit()
        }
    }
}
