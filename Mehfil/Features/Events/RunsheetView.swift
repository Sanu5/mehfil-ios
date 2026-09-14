import SwiftUI
import UniformTypeIdentifiers

/// B5 · Runsheet — used on the wedding day, standing at the venue.
struct RunsheetView: View {
    @Environment(AppStore.self) private var store
    var eventId: String
    @State private var marker = "09:00"
    @State private var addSheet = false
    @State private var newTitle = ""
    @State private var newCrew = ""
    @State private var newBlock = "Setup"
    @State private var dragging: String?

    private var tasks: [RunsheetTask] { store.tasks.filter { $0.eventId == eventId } }
    private var blocks: [(String, String, [RunsheetTask])] {
        var order: [String] = []; var dict: [String: [RunsheetTask]] = [:]; var times: [String: String] = [:]
        for t in tasks { if dict[t.block] == nil { order.append(t.block) }; dict[t.block, default: []].append(t); times[t.block] = t.blockTime }
        return order.map { ($0, times[$0] ?? "", dict[$0] ?? []) }
    }
    private let defaultBlocks = ["Setup", "Dressing", "Event"]

    var body: some View {
        if let e = store.event(eventId) {
            ScrollViewReader { proxy in
                ScreenScaffold(title: "Runsheet", subtitle: "\(e.name) · \(Fmt.weekdayLong.string(from: e.start))", spacing: Space.lg, bottomPadding: 100) {
                    scrubber(proxy)
                    if tasks.isEmpty {
                        EmptyState(headline: "No tasks yet", line: "Add the setup, dressing and event-time tasks so the crew knows what happens when.", actionTitle: "Add task", actionIcon: "plus", primary: true) { addSheet = true }
                            .padding(.top, 80)
                    }
                    ForEach(blocks, id: \.0) { name, time, list in
                        VStack(spacing: Space.md) {
                            SectionHeading(title: time.isEmpty ? name : "\(name) · \(time)", trailing: "\(list.filter(\.done).count) of \(list.count) done")
                            RowGroup {
                                ForEach(Array(list.enumerated()), id: \.element.id) { i, t in
                                    if i > 0 { Hairline(inset: 56) }
                                    taskRow(t, list: list)
                                }
                            }
                        }
                        .id(name)
                    }
                }
                .dockedActions { MButton(title: "Add task", icon: "plus", style: .secondary) { addSheet = true } }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ShareLink(item: shareText(e), subject: Text("Runsheet · \(e.name)")) { Label("Share with crew", systemImage: "square.and.arrow.up") }
                        Button("Mark all done", systemImage: "checkmark.circle") { for t in tasks where !t.done { store.toggleTask(t.id) } }
                    } label: { Image(systemName: "ellipsis") }
                }
            }
            .sheet(isPresented: $addSheet) { addTaskSheet }
        }
    }

    private func shareText(_ e: Event) -> String {
        var s = "Runsheet · \(e.name) · \(Fmt.weekdayLong.string(from: e.start))\n"
        for (name, time, list) in blocks { s += "\n\(name) \(time)\n"; for t in list { s += "\(t.done ? "✓" : "○") \(t.title) — \(t.crew) · \(t.duration)\n" } }
        return s
    }

    /// Horizontal day scrubber — scrolls the list to the matching block.
    private func scrubber(_ proxy: ScrollViewProxy) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Space.sm) {
                ForEach(store.runsheetMarkers, id: \.self) { m in
                    Button {
                        withAnimation(.snappy(duration: 0.25)) {
                            marker = m
                            let h = Int(m.prefix(2)) ?? 9
                            let target = h < 14 ? "Setup" : (h < 17 ? "Dressing" : "Event")
                            if blocks.contains(where: { $0.0 == target }) { proxy.scrollTo(target, anchor: .top) }
                        }
                    } label: {
                        Text(m).type(.buttonSm).monospacedDigit()
                            .foregroundStyle(marker == m ? MColor.textOnPrimary : MColor.text)
                            .padding(.horizontal, Space.md).frame(height: 36)
                            .background(marker == m ? MColor.accent : MColor.surface, in: Capsule())
                            .overlay(Capsule().strokeBorder(marker == m ? Color.clear : MColor.line, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .scrollClipDisabled()
    }

    private func taskRow(_ t: RunsheetTask, list: [RunsheetTask]) -> some View {
        HStack(spacing: Space.md) {
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                withAnimation(.snappy(duration: 0.2)) { store.toggleTask(t.id) }
            } label: {
                ZStack {
                    Circle().strokeBorder(t.done ? MColor.accent : MColor.lineInput, lineWidth: 1.5)
                    if t.done { Circle().fill(MColor.accent); Image(systemName: "checkmark").font(.system(size: 11, weight: .semibold)).foregroundStyle(MColor.textOnPrimary) }
                }
                .frame(width: 24, height: 24).frame(width: Dim.touch, height: Dim.touch).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            VStack(alignment: .leading, spacing: 2) {
                Text(t.title).type(.bodyMdStrong).foregroundStyle(t.done ? MColor.textMute : MColor.text).strikethrough(t.done, color: MColor.textMute)
                Text("\(t.crew) · \(t.duration)").type(.caption).foregroundStyle(MColor.textMute)
            }
            Spacer()
            Image(systemName: "line.3.horizontal").font(.system(size: 14)).foregroundStyle(MColor.textMute).frame(width: Dim.touch, height: Dim.touch)
        }
        .padding(.horizontal, Space.sm)
        .frame(minHeight: Dim.row)
        .background(dragging == t.id ? MColor.surfaceSelected : Color.clear)
        .contentShape(Rectangle())
        // Long-press drag reorders within the block (spec B5).
        .draggable(t.id) { Text(t.title).type(.bodyMdStrong).padding().glassEffect() }
        .dropDestination(for: String.self) { ids, _ in
            guard let from = ids.first, let fi = list.firstIndex(where: { $0.id == from }), let ti = list.firstIndex(where: { $0.id == t.id }), fi != ti else { return false }
            withAnimation(.snappy(duration: 0.25)) { store.moveTask(from, delta: ti - fi) }
            return true
        } isTargeted: { dragging = $0 ? t.id : nil }
        .contextMenu {
            Button("Move up", systemImage: "arrow.up") { store.moveTask(t.id, delta: -1) }
            Button("Move down", systemImage: "arrow.down") { store.moveTask(t.id, delta: 1) }
        }
    }

    private var addTaskSheet: some View {
        let names = blocks.isEmpty ? defaultBlocks : blocks.map { $0.0 }
        return SheetScaffold(title: "Add task", subtitle: "It joins the block you pick and can be dragged into place.") {
            InputField(label: "Task", text: $newTitle, placeholder: "Hang the entrance florals")
            InputField(label: "Crew", text: $newCrew, placeholder: "Kavita · 2 crew")
            VStack(alignment: .leading, spacing: Space.sm) {
                Text("Block").type(.caption).foregroundStyle(MColor.textMute)
                SegmentedControl(items: names.map { BlockChoice(id: $0) }, label: \.id, selection: Binding(get: { BlockChoice(id: names.contains(newBlock) ? newBlock : names[0]) }, set: { newBlock = $0.id }))
            }
        } actions: {
            MButton(title: "Add task") {
                store.addTask(eventId: eventId, block: names.contains(newBlock) ? newBlock : names[0], title: newTitle.trimmingCharacters(in: .whitespaces), crew: newCrew.isEmpty ? "Unassigned" : newCrew)
                newTitle = ""; newCrew = ""; addSheet = false
            }.disabled(newTitle.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .presentationDetents([.large])
    }
    private struct BlockChoice: Identifiable, Hashable { var id: String }
}

/// B6 · Change request — show consequences, not a form.
struct ChangeRequestView: View {
    @Environment(AppStore.self) private var store
    var requestId: String

    var body: some View {
        if let cr = store.changeRequest(requestId), let e = store.event(cr.eventId) {
            let client = store.client(for: e)
            let margin = (cr.revisedQuote - e.quoted) - cr.addedCost
            ScreenScaffold(title: "Change request", largeTitle: false, spacing: Space.lg, bottomPadding: cr.status == .pending ? 140 : Space.xxl) {
                VStack(alignment: .leading, spacing: Space.sm) {
                    Text("\(cr.summary.trimmingCharacters(in: .whitespaces)) \(Cal.daysBetween(Cal.today, e.start)) days out.").type(.headingMd).foregroundStyle(MColor.text).fixedSize(horizontal: false, vertical: true)
                    Text("\(e.name) · \(client?.name ?? "Client") via \(cr.via), \(Fmt.weekdayDayMonthTime.string(from: cr.requestedAt))").type(.caption).foregroundStyle(MColor.textMute)
                    if cr.status != .pending { StatusChip(kind: cr.status == .approved ? .confirmed : .cancelled) }
                }
                .frame(maxWidth: .infinity, alignment: .leading).card()

                RowGroup {
                    ForEach(Array(cr.impacts.enumerated()), id: \.offset) { i, imp in
                        if i > 0 { Hairline() }
                        HStack(spacing: Space.md) {
                            Image(systemName: imp.icon == "people" ? "person.2" : (imp.icon == "transport" ? "truck.box" : "shippingbox"))
                                .font(.system(size: 17, weight: .light)).foregroundStyle(imp.isShort ? MColor.danger : MColor.textMute)
                                .frame(width: Dim.avatar, height: Dim.avatar).background(imp.isShort ? MColor.dangerTint : Color.clear, in: Circle())
                            VStack(alignment: .leading, spacing: 2) {
                                Text(imp.resource).type(.bodyMdStrong).foregroundStyle(MColor.text)
                                Text(imp.detail).type(.caption).foregroundStyle(imp.isShort ? MColor.danger : MColor.textMute)
                            }
                            Spacer()
                            Text(imp.delta).type(.bodyTabularStrong).foregroundStyle(MColor.text).monospacedDigit()
                        }
                        .padding(.horizontal, Space.lg).frame(minHeight: Dim.row).padding(.vertical, Space.xs)
                    }
                }

                VStack(spacing: Space.md) {
                    totalRow("Original quote", e.quoted)
                    totalRow("Added cost to you", cr.addedCost)
                    Rectangle().fill(MColor.line).frame(height: 1)
                    HStack(alignment: .firstTextBaseline) {
                        Text("Revised quote").type(.bodyMdStrong).foregroundStyle(MColor.text)
                        Spacer()
                        Text(Fmt.inr(cr.revisedQuote)).type(.headingLg).foregroundStyle(MColor.text).monospacedDigit()
                    }
                    Text("\(cr.guestsDelta) guests at ₹\(cr.perGuest) · \(Fmt.inr(margin)) margin on the change").type(.caption).foregroundStyle(margin < 0 ? MColor.danger : MColor.textMute)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .card()
            }
            .dockedActions {
                if cr.status == .pending {
                    VStack(spacing: Space.sm) {
                        MButton(title: "Approve and send revised quote") { store.approveChangeRequest(cr.id); store.pop() }
                        // Decline is tertiary, not destructive — declining destroys nothing (NOTES Phase 3).
                        MButton(title: "Decline change", style: .tertiary, size: .compact) { store.declineChangeRequest(cr.id); store.pop() }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        if let client, !client.phone.isEmpty { Button("Call \(client.name)", systemImage: "phone") { if let u = URL(string: "tel://\(Fmt.phoneDigits(client.phone))") { UIApplication.shared.open(u) } } }
                        Button("Open event", systemImage: "calendar") { store.push(.eventDetail(e.id)) }
                    } label: { Image(systemName: "ellipsis") }
                }
            }
        } else {
            ContentUnavailableView("Change request not found", systemImage: "arrow.triangle.2.circlepath")
        }
    }

    private func totalRow(_ label: String, _ amount: Int) -> some View {
        HStack { Text(label).type(.bodyMd).foregroundStyle(MColor.textMute); Spacer(); Money(amount) }
    }
}
