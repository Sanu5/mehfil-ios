import SwiftUI

/// D1 · Crew list — grouped by role, availability for the selected date.
struct CrewListView: View {
    @Environment(AppStore.self) private var store
    var pushed = false
    @State private var day: Date = Cal.date(2026, 11, 14)

    private var dayEventIds: [String] { store.events(on: day).map(\.id) }
    private func booked(_ m: CrewMember) -> [Event] { m.bookedOn.compactMap { id in dayEventIds.contains(id) ? store.event(id) : nil } }
    private var conflictDays: Set<Date> { Set(store.events.filter(\.hasCrewConflict).map { Cal.startOfDay($0.start) }) }

    var body: some View {
        ScreenScaffold(title: "Team", subtitle: store.crew.isEmpty ? "No crew yet" : "\(store.crew.count) crew · \(Seed.crewOnDutyToday) on duty today", isRoot: !pushed, spacing: Space.lg,
                       headerTrailing: pushed ? nil : AnyView(GlassMenuButton { menuItems })) {
            DateStrip(selected: $day, conflictDays: conflictDays)
            if store.crew.isEmpty {
                EmptyState(headline: "No crew added", line: "Add your coordinators, decorators and helpers with their day rates.", actionTitle: "Add crew member", actionIcon: "plus", primary: true) {
                    store.show(.info, "Crew onboarding is coming with the next release")
                }.padding(.top, 140)
            } else {
                ForEach(CrewRole.allCases, id: \.self) { role in
                    let members = store.crew.filter { $0.role == role }
                    let bookedCount = members.filter { !booked($0).isEmpty }.count
                    VStack(spacing: Space.md) {
                        SectionHeading(title: role.plural, trailing: "\(Fmt.weekdayDayMonth.string(from: day)) · \(bookedCount) of \(members.count) booked")
                        RowGroup {
                            ForEach(Array(members.enumerated()), id: \.element.id) { i, m in
                                if i > 0 { Hairline(inset: 68) }
                                let b = booked(m)
                                Button {
                                    if let e = b.first ?? store.events(on: day).first { store.push(.assignCrew(e.id)) }
                                } label: {
                                    ListRow(title: m.name, subtitle: "\(m.isLead ? "Lead \(m.role.rawValue)" : m.role.label) · \(Fmt.inr(m.role.dayRate))/day") {
                                        Avatar(index: m.avatar, name: m.name)
                                    } trailing: {
                                        HStack(spacing: Space.sm) {
                                            Text(b.isEmpty ? "Available" : b.map(\.surname).joined(separator: " · ")).type(.caption)
                                                .foregroundStyle(b.count > 1 ? MColor.danger : (b.isEmpty ? MColor.accentText : MColor.textMute))
                                            Chevron()
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
        .toolbar {
            if pushed { ToolbarItem(placement: .topBarTrailing) { Menu { menuItems } label: { Image(systemName: "ellipsis") } } }
        }
    }

    @ViewBuilder private var menuItems: some View {
        Button("Attendance today", systemImage: "checkmark.circle") { if let e = store.events(on: day).first { store.push(.attendance(e.id)) } }
        Button("Inventory", systemImage: "shippingbox") { store.push(.inventory) }
        Button("Add crew member", systemImage: "person.badge.plus") { store.show(.info, "Crew onboarding is coming with the next release") }
    }
}

/// D2 · Assign crew — available first, booked members listed (not disabled) with the conflicting event named inline.
struct AssignCrewView: View {
    @Environment(AppStore.self) private var store
    var eventId: String
    @State private var compare: CrewMember?

    var body: some View {
        if let e = store.event(eventId) {
            let assigned = store.assignedCrew(for: e.id)
            let others = store.events(on: e.start).filter { $0.id != e.id }
            let available = store.crew.filter { m in !m.bookedOn.contains { others.map(\.id).contains($0) } }
            let booked = store.crew.filter { m in m.bookedOn.contains { others.map(\.id).contains($0) } }
            let byRole = Dictionary(grouping: assigned, by: \.role)
            let plan = e.crewPlan.isEmpty ? CrewRole.allCases.map { "\(byRole[$0]?.count ?? 0) \($0.plural.lowercased())" }.joined(separator: ", ") : e.crewPlan
            let short = max(0, e.crewNeeded - e.crewAssigned)
            // The member booked here and on another event that day names the conflict (Suresh → Gill).
            let clash = store.crew.first { m in m.bookedOn.contains(e.id) && m.bookedOn.contains { others.map(\.id).contains($0) } }
            let clashEvent = clash.flatMap { m in others.first { m.bookedOn.contains($0.id) } }
            ScreenScaffold(title: "Assign crew", subtitle: "\(e.name) · \(Fmt.weekdayLong.string(from: e.start))", spacing: Space.lg) {
                VStack(alignment: .leading, spacing: Space.sm) {
                    Text("Assigned for \(Fmt.weekdayDayMonth.string(from: e.start))").type(.caption).foregroundStyle(MColor.textMute)
                    HStack(alignment: .firstTextBaseline, spacing: Space.sm) {
                        Text("\(e.crewAssigned)").type(.displayHero).foregroundStyle(MColor.text)
                        Text("of \(e.crewNeeded) needed · \(plan)").type(.caption).foregroundStyle(MColor.textMute)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    ProgressBar(fraction: Double(e.crewAssigned) / Double(max(1, e.crewNeeded)))
                    Text((short > 0 ? "\(short) \(short == 1 ? "helper" : "helpers") short" : "Fully staffed") + (clash.map { " · \($0.firstName)'s team also on \(clashEvent?.surname ?? "another event")" } ?? "")).type(.caption).foregroundStyle(short > 0 || clash != nil ? MColor.danger : MColor.textMute)
                }
                .frame(maxWidth: .infinity, alignment: .leading).card()

                VStack(spacing: Space.md) {
                    SectionHeading(title: "Available on \(Fmt.weekdayDayMonth.string(from: e.start))", trailing: "\(available.count)")
                    RowGroup {
                        ForEach(Array(available.enumerated()), id: \.element.id) { i, m in
                            if i > 0 { Hairline(inset: 68) }
                            let on = m.bookedOn.contains(e.id)
                            ListRow(title: m.name, subtitle: "\(m.role.label) · \(on ? "assigned" : (m.availabilityNote ?? "free"))", selected: on) {
                                Avatar(index: m.avatar, name: m.name)
                            } trailing: {
                                toggle(on: on) { store.toggleAssignment(crewId: m.id, eventId: e.id) }
                            }
                        }
                    }
                }

                if !booked.isEmpty {
                    VStack(spacing: Space.md) {
                        SectionHeading(title: "Booked that day", trailing: "tap to compare")
                        RowGroup {
                            ForEach(Array(booked.enumerated()), id: \.element.id) { i, m in
                                if i > 0 { Hairline(inset: 68) }
                                let on = m.bookedOn.contains(e.id)
                                let other = others.first { m.bookedOn.contains($0.id) }
                                Button { compare = m } label: {
                                    ListRow(title: m.name, subtitle: (other.map { "\($0.name) \(Fmt.timeRange($0.start, $0.end))" } ?? "") + (m.availabilityNote.map { " · \($0)" } ?? ""),
                                            subtitleColor: on ? MColor.danger : MColor.textMute, selected: on) {
                                        Avatar(index: m.avatar, name: m.name)
                                    } trailing: {
                                        toggle(on: on) { compare = m }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Attendance", systemImage: "checkmark.circle") { store.push(.attendance(e.id)) }
                        Button("Open event", systemImage: "calendar") { store.push(.eventDetail(e.id)) }
                    } label: { Image(systemName: "ellipsis") }
                }
            }
            .sheet(item: $compare) { m in
                if let other = others.first(where: { m.bookedOn.contains($0.id) }) {
                    CrewComparisonSheet(member: m, target: e, other: other).presentationDetents([.medium, .large])
                }
            }
        }
    }

    private func toggle(on: Bool, action: @escaping () -> Void) -> some View {
        Button { withAnimation(.snappy(duration: 0.2)) { action() } } label: {
            Image(systemName: on ? "checkmark" : "plus").font(.system(size: 14, weight: .medium))
                .foregroundStyle(on ? MColor.textOnPrimary : MColor.accentText)
                .frame(width: 32, height: 32)
                .background(on ? MColor.accent : Color.clear, in: Circle())
                .overlay(Circle().strokeBorder(on ? Color.clear : MColor.accentText, lineWidth: 1))
                .frame(width: Dim.touch, height: Dim.touch).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// D2 comparison sheet — both events with the consequence of choosing each; reassignment is a real decision.
struct CrewComparisonSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    var member: CrewMember
    var target: Event
    var other: Event
    @State private var choice: String = ""

    private func agencyCost(for e: Event) -> Int { e.crewAssigned * 4800 / (e.id == "gill-engagement" ? 1 : 1) }

    var body: some View {
        SheetScaffold(title: "\(member.firstName)'s team is booked twice") {
            option(target, consequence: "\(other.surname) then needs agency crew · \(Fmt.inr(other.id == "gill-engagement" ? 38_400 : agencyCost(for: other)))")
            option(other, consequence: "\(target.surname) then needs agency crew · \(Fmt.inr(target.id == "kapoor-sangeet" ? 57_600 : agencyCost(for: target)))")
        } actions: {
            VStack(spacing: Space.sm) {
                let chosen = choice == other.id ? other : target
                let dropped = choice == other.id ? target : other
                MButton(title: "Move the team to \(chosen.surname)") { store.moveTeam(crewId: member.id, to: chosen.id, from: dropped.id); dismiss() }
                MButton(title: "Keep on \(other.surname)", style: .tertiary, size: .compact) { dismiss() }
            }
        }
        .onAppear { choice = target.id }
    }

    private func option(_ e: Event, consequence: String) -> some View {
        let selected = choice == e.id
        return Button { withAnimation(.snappy(duration: 0.2)) { choice = e.id } } label: {
            HStack(alignment: .top, spacing: Space.md) {
                RoundedRectangle(cornerRadius: 2).fill(MColor.event(e.hue)).frame(width: Dim.edge)
                VStack(alignment: .leading, spacing: Space.xs) {
                    Text(e.name).type(.headingSm).foregroundStyle(MColor.text)
                    Text("\(Fmt.timeRange(e.start, e.end)) · \(e.guests) guests · \(Fmt.inr(e.quoted))").type(.caption).foregroundStyle(MColor.textMute)
                    HStack(spacing: Space.xs) {
                        Image(systemName: "exclamationmark.circle").font(.system(size: 11)).foregroundStyle(MColor.danger)
                        Text(consequence).type(.caption).foregroundStyle(MColor.danger)
                    }
                }
                Spacer()
                Image(systemName: selected ? "checkmark.circle" : "circle").font(.system(size: 20, weight: .light)).foregroundStyle(selected ? MColor.accentText : MColor.line)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Space.lg)
            .background(selected ? MColor.surfaceSelected : MColor.surface, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).strokeBorder(selected ? MColor.accent : MColor.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

/// D3 · Attendance — used at 6am on an event morning. Three-state control with single-tap cycling.
struct AttendanceView: View {
    @Environment(AppStore.self) private var store
    var initialEventId: String
    @State private var eventId: String = ""

    private struct Choice: Identifiable, Hashable { var id: String; var label: String }

    var body: some View {
        let e0 = store.event(initialEventId)
        let day = e0?.start ?? Cal.today
        let todays = store.events(on: day)
        let choices = todays.map { Choice(id: $0.id, label: $0.surname) }
        let current = store.event(eventId.isEmpty ? initialEventId : eventId) ?? e0
        ScreenScaffold(title: "Attendance", subtitle: "\(Fmt.weekdayLong.string(from: day)) · \(todays.count) events today", spacing: Space.lg) {
            if choices.count > 1 {
                SegmentedControl(items: choices, label: \.label, selection: Binding(get: { choices.first { $0.id == (current?.id ?? "") } ?? choices[0] }, set: { eventId = $0.id }))
            }
            if let e = current {
                let members = store.assignedCrew(for: e.id)
                let states = store.attendance(for: e.id)
                let arrived = members.filter { states[$0.id] == .arrived }.count
                let confirmed = members.filter { (states[$0.id] ?? .confirmed) == .confirmed }.count
                let absent = members.filter { states[$0.id] == .absent }.count
                HStack(alignment: .top, spacing: Space.md) {
                    Text("\(arrived) of \(members.count)").type(.displayMd).foregroundStyle(MColor.text).monospacedDigit()
                    VStack(alignment: .leading, spacing: 2) {
                        Text("arrived at \(e.venue.name)").type(.bodyMd).foregroundStyle(MColor.text)
                        Text("Call time 09:00 · \(confirmed) confirmed on the way" + (absent > 0 ? " · \(absent) absent" : "")).type(.caption).foregroundStyle(MColor.textMute)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading).card()

                RowGroup {
                    ForEach(Array(members.enumerated()), id: \.element.id) { i, m in
                        if i > 0 { Hairline(inset: 68) }
                        let s = states[m.id] ?? .confirmed
                        ListRow(title: m.name, subtitle: m.role.label + (m.isLead ? " · lead" : "")) {
                            Avatar(index: m.avatar, name: m.name)
                        } trailing: {
                            TriState(state: s) {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                withAnimation(.snappy(duration: 0.2)) { store.cycleAttendance(eventId: e.id, crewId: m.id) }
                            }
                        }
                    }
                }
            }
        }
        .onAppear { if eventId.isEmpty { eventId = initialEventId } }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Message absentees", systemImage: "bubble") { store.show(.success, "Sent on WhatsApp") }
                    Button("Open runsheet", systemImage: "list.bullet.rectangle") { if let e = current { store.push(.runsheet(e.id)) } }
                } label: { Image(systemName: "ellipsis") }
            }
        }
    }
}

/// Tri-state control: confirmed = outline ink · arrived = filled emphasis · absent = ruby outline on ruby tint (NOTES Phase 5).
struct TriState: View {
    var state: AttendanceState
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: Space.xs) {
                Image(systemName: state == .arrived ? "checkmark.circle" : (state == .absent ? "xmark.circle" : "checkmark")).font(.system(size: 11))
                Text(state.label).type(.caption)
            }
            .foregroundStyle(state == .arrived ? MColor.emphasisText : (state == .absent ? MColor.danger : MColor.text))
            .padding(.horizontal, 10).frame(height: 28)
            .background(state == .arrived ? MColor.emphasisBg : (state == .absent ? MColor.dangerTint : Color.clear), in: Capsule())
            .overlay(Capsule().strokeBorder(state == .arrived ? Color.clear : (state == .absent ? MColor.danger : MColor.lineInput), lineWidth: 1))
            .frame(minHeight: Dim.touch).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// D4 · Inventory — commitment bars per item; over-committed items sorted to the top.
struct InventoryView: View {
    @Environment(AppStore.self) private var store
    @State private var day: Date = Cal.date(2026, 11, 14)

    private var conflictDays: Set<Date> { Set(store.inventory.flatMap { item in item.holds.map { Cal.startOfDay($0.date) }.filter { item.isOver(on: $0) } }) }

    var body: some View {
        let items = store.inventory.sorted { a, b in
            let ao = a.isOver(on: day), bo = b.isOver(on: day)
            if ao != bo { return ao }
            return Double(a.committed(on: day)) / Double(a.total) > Double(b.committed(on: day)) / Double(b.total)
        }
        let over = items.filter { $0.isOver(on: day) }.count
        ScreenScaffold(title: "Inventory", subtitle: store.inventory.isEmpty ? "Nothing tracked yet" : "\(Fmt.weekdayLong.string(from: day)) · \(over == 0 ? "nothing over" : "\(over) item\(over == 1 ? "" : "s") over")", spacing: Space.lg) {
            DateStrip(selected: $day, conflictDays: conflictDays)
            if store.inventory.isEmpty {
                EmptyState(headline: "No inventory tracked", line: "Add chairs, drapes, rigs and tables to see what is committed on any date.", actionTitle: "Add item", actionIcon: "plus", primary: true) {
                    store.show(.info, "Item entry is coming with the next release")
                }.padding(.top, 140)
            } else {
                RowGroup {
                    ForEach(Array(items.enumerated()), id: \.element.id) { i, item in
                        if i > 0 { Hairline() }
                        let c = item.committed(on: day)
                        let isOver = c > item.total
                        Button { store.push(.itemDetail(item.id)) } label: {
                            VStack(alignment: .leading, spacing: Space.sm) {
                                HStack {
                                    Text(item.name).type(.bodyMdStrong).foregroundStyle(MColor.text)
                                    Spacer()
                                    Text(isOver ? "\(c) of \(item.total) · \(c - item.total) over" : "\(c) of \(item.total)").type(.bodyTabularStrong).monospacedDigit().foregroundStyle(isOver ? MColor.danger : MColor.textMute)
                                    Chevron()
                                }
                                CommitmentBar(committed: c, total: item.total)
                                let holds = item.holds.filter { Cal.sameDay($0.date, day) }
                                Text(holds.isEmpty ? "Free on this date" : holds.map { "\(store.event($0.eventId)?.surname ?? "") \($0.qty)" }.joined(separator: " · ")).type(.caption).foregroundStyle(MColor.textMute)
                            }
                            .padding(Space.lg).contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Add item", systemImage: "plus") { store.show(.info, "Item entry is coming with the next release") }
                    Button("Crew for this date", systemImage: "person.2") { store.push(.crewList) }
                } label: { Image(systemName: "ellipsis") }
            }
        }
    }
}

/// D5 · Item detail — 30-day commitment strip and the events holding the item.
struct ItemDetailView: View {
    @Environment(AppStore.self) private var store
    var itemId: String

    var body: some View {
        if let item = store.item(itemId) {
            let start = Cal.startOfDay(Cal.today)
            let days = (0..<31).map { Cal.adding($0, .day, to: start) }
            let values = days.map { item.committed(on: $0) }
            let peak = zip(days, values).max { $0.1 < $1.1 }
            let holds = item.holds.sorted { $0.date < $1.date }
            ScreenScaffold(title: item.name, subtitle: "\(item.total) in stock · \(item.detail)", spacing: Space.lg) {
                VStack(alignment: .leading, spacing: Space.md) {
                    HStack {
                        Text("Committed · next 30 days").type(.caption).foregroundStyle(MColor.textMute)
                        Spacer()
                        if let peak, peak.1 > 0 { Text("peak \(peak.1) on \(Fmt.weekdayDayMonth.string(from: peak.0))").type(.caption).foregroundStyle(peak.1 > item.total ? MColor.danger : MColor.textMute) }
                    }
                    HStack(alignment: .bottom, spacing: 2) {
                        ForEach(days.indices, id: \.self) { i in
                            let v = values[i]
                            let over = v > item.total
                            let h = v == 0 ? 2 : max(4, 72 * CGFloat(v) / CGFloat(max(item.total, values.max() ?? 1)))
                            RoundedRectangle(cornerRadius: 1.5).fill(v == 0 ? MColor.line : (over ? MColor.danger : MColor.accent)).frame(height: h)
                        }
                    }
                    .frame(height: 72, alignment: .bottom)
                    HStack {
                        ForEach([0, 9, 19, 30], id: \.self) { i in
                            Text(Fmt.dayMonth.string(from: days[i])).type(.caption).foregroundStyle(MColor.textMute)
                            if i != 30 { Spacer() }
                        }
                    }
                    HStack(spacing: Space.lg) {
                        legend(MColor.accent, "Committed")
                        legend(MColor.danger, "Over \(item.total)")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading).card()

                VStack(spacing: Space.md) {
                    SectionHeading(title: "Events holding \(item.name.lowercased())", trailing: "\(holds.count) · \(holds.reduce(0) { $0 + $1.qty }) \(item.name.lowercased().split(separator: " ").last ?? "")")
                    RowGroup {
                        ForEach(Array(holds.enumerated()), id: \.offset) { i, h in
                            if i > 0 { Hairline(inset: 68) }
                            if let e = store.event(h.eventId) {
                                Button { store.push(.eventDetail(e.id)) } label: {
                                    ListRow(title: e.name, subtitle: "\(Fmt.weekdayDayMonth.string(from: h.date)) · \(e.venue.name)") {
                                        IconTile(symbol: "calendar")
                                    } trailing: {
                                        HStack(spacing: Space.sm) { Text("\(h.qty)").type(.bodyTabularStrong).monospacedDigit().foregroundStyle(MColor.text); Chevron() }
                                    }
                                }.buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Edit stock", systemImage: "pencil") { store.show(.info, "Stock editing is coming with the next release") }
                    } label: { Image(systemName: "ellipsis") }
                }
            }
        }
    }
    private func legend(_ c: Color, _ t: String) -> some View {
        HStack(spacing: Space.xs) { Circle().fill(c).frame(width: 8, height: 8); Text(t).type(.caption).foregroundStyle(MColor.textMute) }
    }
}
