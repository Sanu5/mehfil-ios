import SwiftUI

/// A1 · Home — answer "what do I need to worry about today" in under three seconds.
struct HomeView: View {
    @Environment(AppStore.self) private var store

    private var nextSaturday: Date {
        let wd = Cal.calendar.component(.weekday, from: Cal.today)
        let delta = (7 - wd + 7) % 7
        return Cal.startOfDay(Cal.adding(delta == 0 ? 7 : delta, .day, to: Cal.today))
    }
    private var saturdayEvents: [Event] { store.events(on: nextSaturday) }
    /// Home ranks urgency above chronology (NOTES Phase 2): the conflicted event leads.
    private var attention: Event? { saturdayEvents.first(where: \.hasCrewConflict) ?? store.upcomingEvents.first }
    private var greeting: String {
        let h = Cal.calendar.component(.hour, from: Cal.today)
        return h < 12 ? "Good morning" : (h < 17 ? "Good afternoon" : "Good evening")
    }

    var body: some View {
        ScreenScaffold(title: "\(greeting), \(Seed.vendorFirstName)",
                       subtitle: "\(Fmt.weekdayLong.string(from: Cal.today)) · \(saturdayEvents.count) events this Saturday", isRoot: true,
                       headerTrailing: AnyView(GlassIconButton(symbol: "chart.bar") { store.push(.seasonSummary) })) {
            if let (a, b) = store.seasonConflict {
                ConflictBanner(text: "\(a.name) and \(b.name) both need Suresh's decor team on \(Fmt.weekdayDayMonth.string(from: a.start)).") {
                    store.push(.assignCrew(a.id), in: .team)
                }
            }

            receivables

            VStack(alignment: .leading, spacing: Space.md) {
                SectionHeading(title: attention.map { "Needs attention · \(Fmt.weekdayShort.string(from: $0.start))urday, \(Fmt.relativeDays($0.start))" } ?? "Next up",
                               link: "Calendar") { store.push(.calendarMonth) }
                if let e = attention {
                    EventCard(event: e, client: store.client(for: e), paymentState: store.paymentState(for: e)) { store.push(.eventDetail(e.id)) }
                    let others = saturdayEvents.filter { $0.id != e.id }
                    if !others.isEmpty {
                        Text("Also Saturday · " + others.map { "\($0.name) \(Fmt.time.string(from: $0.start))" }.joined(separator: " · "))
                            .type(.caption).foregroundStyle(MColor.textMute).fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            HStack(spacing: Space.md) {
                StatTile(figure: "\(store.events(inMonth: Cal.month(Cal.today), year: Cal.year(Cal.today)).count)", label: "Events this month") { store.selectedTab = .events }
                StatTile(figure: "\(Seed.crewOnDutyToday)", label: "Crew on duty today") { store.selectedTab = .team }
                StatTile(figure: "\(Seed.openEnquiries)", label: "Open enquiries") { store.push(.enquiry, in: .profile) }
            }
        }
    }

    private var receivables: some View {
        Button { store.selectedTab = .money } label: {
            HStack(spacing: Space.md) {
                VStack(alignment: .leading, spacing: Space.xs) {
                    Text("Outstanding across \(store.eventsWithOpenMoney) events").type(.caption).foregroundStyle(MColor.textMute)
                    Text(Fmt.inr(store.totalOutstanding)).type(.displayHero).foregroundStyle(MColor.text)
                    if store.overdueTotal > 0 {
                        HStack(spacing: Space.xs) {
                            Image(systemName: "exclamationmark.circle").font(.system(size: 12)).foregroundStyle(MColor.danger)
                            Text("\(Fmt.inr(store.overdueTotal)) overdue · \(store.overdueSurnames)").type(.caption).foregroundStyle(MColor.danger)
                        }
                    } else {
                        Text("Nothing overdue").type(.caption).foregroundStyle(MColor.textMute)
                    }
                }
                Spacer()
                Chevron()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .card()
        }
        .buttonStyle(PressableCardStyle())
    }
}

/// A2 · Calendar month — see the shape of the month.
struct CalendarMonthView: View {
    @Environment(AppStore.self) private var store
    @State private var month: Date = Cal.date(2026, 11, 1)
    @State private var selected: Date = Cal.date(2026, 11, 14)

    private var monthEvents: [Event] { store.events(inMonth: Cal.month(month), year: Cal.year(month)) }
    private var byDay: [Int: [Event]] { Dictionary(grouping: monthEvents, by: { Cal.day($0.start) }) }
    private var conflictDays: Set<Int> { Set(monthEvents.filter(\.hasCrewConflict).map { Cal.day($0.start) }) }
    private var dayEvents: [Event] { store.events(on: selected) }

    var body: some View {
        ScreenScaffold(title: Fmt.monthYear.string(from: month), subtitle: "\(monthEvents.count) events · \(Fmt.inr(monthEvents.reduce(0) { $0 + $1.quoted })) booked", spacing: Space.lg) {
            CalendarGrid(month: month, selected: $selected, eventsByDay: byDay, conflictDays: conflictDays)
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 30).onEnded { v in
                    if v.translation.width < -30 { shift(1) } else if v.translation.width > 30 { shift(-1) }
                })

            SectionHeading(title: Fmt.weekdayLong.string(from: selected),
                           trailing: dayEvents.isEmpty ? "No events" : "\(dayEvents.count) events" + (store.conflicts(on: selected).isEmpty ? "" : " · two overlap"),
                           link: dayEvents.isEmpty ? nil : "Timeline") { store.push(.dayDetail(selected)) }
                .padding(.top, Space.sm)

            if dayEvents.isEmpty {
                Text("Nothing booked on this day.").type(.bodyMd).foregroundStyle(MColor.textMute).frame(maxWidth: .infinity, alignment: .center).padding(.vertical, Space.xl)
            } else {
                VStack(spacing: Space.md) {
                    ForEach(dayEvents) { e in
                        EventCard(event: e, client: store.client(for: e), paymentState: store.paymentState(for: e), compact: true) { store.push(.eventDetail(e.id)) }
                    }
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button { shift(-1) } label: { Image(systemName: "chevron.left") }
                Button { shift(1) } label: { Image(systemName: "chevron.right") }
            }
        }
    }

    private func shift(_ n: Int) {
        withAnimation(.snappy(duration: 0.25)) {
            month = Cal.adding(n, .month, to: month)
            selected = Cal.calendar.date(from: Cal.calendar.dateComponents([.year, .month], from: month))!
        }
    }
}

/// A3 · Calendar day detail — overlapping commitments render side by side; the conflict is visible from the layout.
struct DayDetailView: View {
    @Environment(AppStore.self) private var store
    var day: Date

    var body: some View {
        let evs = store.events(on: day)
        let crew = evs.reduce(0) { $0 + $1.crewAssigned }
        let overlap = store.conflicts(on: day)
        ScreenScaffold(title: Fmt.weekdayLong.string(from: day),
                       subtitle: "\(evs.count) events · \(crew) crew" + (overlap.isEmpty ? "" : " · two overlap from \(Fmt.time.string(from: overlap.map(\.start).max() ?? day))")) {
            TimelineStrip(events: evs) { store.push(.eventDetail($0.id)) }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Assign crew", systemImage: "person.2") { if let e = evs.first { store.push(.assignCrew(e.id), in: .team) } }
                    Button("Check inventory", systemImage: "shippingbox") { store.push(.inventory, in: .team) }
                } label: { Image(systemName: "ellipsis") }
            }
        }
    }
}

/// A4 · Season summary — the screen a vendor shows their spouse.
struct SeasonSummaryView: View {
    @Environment(AppStore.self) private var store

    private var booked: Int { store.events.filter { $0.status != .cancelled }.reduce(0) { $0 + $1.quoted } }
    private var count: Int { store.events.filter { $0.status != .cancelled }.count }

    var body: some View {
        let pct = Int((Double(booked) / Double(Seed.seasonTarget) * 100).rounded())
        let delta = Int((Double(booked - Seed.lastSeasonBooked) / Double(Seed.lastSeasonBooked) * 100).rounded())
        ScreenScaffold(title: "Season 2026–27", subtitle: "October to February · \(count) events booked", spacing: Space.lg) {
            VStack(alignment: .leading, spacing: Space.sm) {
                Text("Booked this season").type(.caption).foregroundStyle(MColor.textMute)
                Text(Fmt.inr(booked)).type(.displayHero).foregroundStyle(MColor.text)
                ProgressBar(fraction: Double(booked) / Double(Seed.seasonTarget)).padding(.top, Space.xs)
                Text("\(pct)% of the \(Fmt.inr(Seed.seasonTarget)) target · \(Fmt.inr(Seed.seasonTarget - booked)) to go").type(.caption).foregroundStyle(MColor.textMute)
            }
            .frame(maxWidth: .infinity, alignment: .leading).card()

            VStack(alignment: .leading, spacing: Space.md) {
                Text("Booked value by month").type(.caption).foregroundStyle(MColor.textMute)
                MonthBars(months: Seed.seasonMonths)
            }
            .frame(maxWidth: .infinity, alignment: .leading).card()

            HStack(spacing: Space.md) {
                StatTile(figure: "\(count)", label: "Events booked")
                StatTile(figure: Fmt.inr(count == 0 ? 0 : booked / count / 100 * 100), label: "Average ticket")
            }

            HStack(alignment: .top, spacing: Space.md) {
                Image(systemName: "arrow.up.right").font(.system(size: 18, weight: .light)).foregroundStyle(MColor.accentText).frame(width: Dim.icon, height: Dim.icon)
                VStack(alignment: .leading, spacing: Space.xs) {
                    Text("\(delta >= 0 ? "+" : "")\(delta)%").type(.displayMd).foregroundStyle(MColor.text)
                    Text("against last season").type(.bodyMd).foregroundStyle(MColor.text)
                    Text("\(Fmt.inr(Seed.lastSeasonBooked)) across \(Seed.lastSeasonEvents) events by this point in 2025").type(.caption).foregroundStyle(MColor.textMute)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading).card()
        }
    }
}

/// Single-series bars in accent; lakh notation because full grouping does not fit a 60pt column (NOTES).
struct MonthBars: View {
    var months: [(String, Int)]
    var body: some View {
        let maxV = max(1, months.map(\.1).max() ?? 1)
        HStack(alignment: .bottom, spacing: Space.md) {
            ForEach(months.indices, id: \.self) { i in
                let (name, v) = months[i]
                VStack(spacing: Space.xs) {
                    if v > 0 { Text(Fmt.lakh(v)).type(.caption).foregroundStyle(MColor.text).monospacedDigit() }
                    else { Text("—").type(.caption).foregroundStyle(MColor.textMute) }
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(v > 0 ? MColor.accent : MColor.line)
                        .frame(height: v > 0 ? max(4, Dim.chart * CGFloat(v) / CGFloat(maxV)) : 2)
                    Text(name).type(.caption).foregroundStyle(MColor.textMute)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: Dim.chart + 48, alignment: .bottom)
    }
}
