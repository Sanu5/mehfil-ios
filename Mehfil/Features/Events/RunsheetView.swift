import SwiftUI
import UniformTypeIdentifiers

/// B5 · Runsheet — used on the wedding day, standing at the venue.
struct RunsheetView: View {
    @Environment(AppStore.self) private var store
    var eventId: String
    @State private var marker = Seed.runsheetMarkers[0]
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

    var body: some View {
        if let e = store.event(eventId) {
            ScrollViewReader { proxy in
                ScreenScaffold(title: "Runsheet", subtitle: "\(e.name) · \(Fmt.weekdayLong.string(from: e.start))", spacing: Space.lg, bottomPadding: 100) {
                    scrubber(proxy)
                    ForEach(blocks, id: \.0) { name, time, list in
                        VStack(spacing: Space.md) {
                            SectionHeading(title: "\(name) · \(time)", trailing: "\(list.filter(\.done).count) of \(list.count) done")
                            RowGroup {
                                ForEach(Array(list.enumerated()), id: \.element.id) { i, t in
                                    if i > 0 { Hairline(inset: 56) }
                                    taskRow(t, block: name, list: list)
                                }
                            }
                        }
                        .id(name)
                    }
                }
                .dockedActions {
                    MButton(title: "Add task", icon: "plus", style: .secondary) { addSheet = true }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Share with crew", systemImage: "square.and.arrow.up") { store.show(.success, "Runsheet shared on WhatsApp") }
                        Button("Mark all done", systemImage: "checkmark.circle") { for t in tasks where !t.done { store.toggleTask(t.id) } }
                    } label: { Image(systemName: "ellipsis") }
                }
            }
            .sheet(isPresented: $addSheet) { addTaskSheet }
        }
    }

    /// Horizontal day scrubber — floats on glass, scrolls the list to the matching block.
    private func scrubber(_ proxy: ScrollViewProxy) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Space.sm) {
                ForEach(Seed.runsheetMarkers, id: \.self) { m in
                    Button {
                        withAnimation(.snappy(duration: 0.25)) {
                            marker = m
                            let h = Int(m.prefix(2)) ?? 9
                            proxy.scrollTo(h < 14 ? "Setup" : (h < 17 ? "Dressing" : "Event"), anchor: .top)
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

    private func taskRow(_ t: RunsheetTask, block: String, list: [RunsheetTask]) -> some View {
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
            withAnimation(.snappy(duration: 0.25)) { store.moveTask(from: IndexSet(integer: fi), to: ti > fi ? ti + 1 : ti, in: block, eventId: eventId) }
            return true
        } isTargeted: { dragging = $0 ? t.id : nil }
        .contextMenu {
            Button("Move up", systemImage: "arrow.up") { if let i = list.firstIndex(where: { $0.id == t.id }), i > 0 { store.moveTask(from: IndexSet(integer: i), to: i - 1, in: block, eventId: eventId) } }
            Button("Move down", systemImage: "arrow.down") { if let i = list.firstIndex(where: { $0.id == t.id }), i < list.count - 1 { store.moveTask(from: IndexSet(integer: i), to: i + 2, in: block, eventId: eventId) } }
        }
    }

    private var addTaskSheet: some View {
        SheetScaffold(title: "Add task", subtitle: "It joins the block you pick and can be dragged into place.") {
            InputField(label: "Task", text: $newTitle, placeholder: "Hang the entrance florals")
            InputField(label: "Crew", text: $newCrew, placeholder: "Kavita · 2 crew")
            VStack(alignment: .leading, spacing: Space.sm) {
                Text("Block").type(.caption).foregroundStyle(MColor.textMute)
                SegmentedControl(items: blocks.map { BlockChoice(id: $0.0) }, label: \.id, selection: Binding(get: { BlockChoice(id: newBlock) }, set: { newBlock = $0.id }))
            }
        } actions: {
            MButton(title: "Add task") {
                store.addTask(eventId: eventId, block: newBlock, title: newTitle, crew: newCrew.isEmpty ? "Unassigned" : newCrew)
                newTitle = ""; newCrew = ""; addSheet = false
            }.disabled(newTitle.isEmpty)
        }
        .presentationDetents([.large])
    }
    private struct BlockChoice: Identifiable, Hashable { var id: String }
}
