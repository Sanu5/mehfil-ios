import SwiftUI

/// B6 · Change request — show consequences, not a form.
struct ChangeRequestView: View {
    @Environment(AppStore.self) private var store
    var eventId: String

    private let addedCost = 15_700
    private let revised = 710_000
    private let perGuest = 350

    var body: some View {
        if let e = store.event(eventId), let client = store.client(for: e) {
            let original = e.quoted
            let margin = (revised - original) - addedCost
            ScreenScaffold(title: "Change request", largeTitle: false, spacing: Space.lg, bottomPadding: 140) {
                // The requested change stated in plain language
                VStack(alignment: .leading, spacing: Space.sm) {
                    Text("Add 200 guests. \(e.guests) becomes \(e.guests + 200), \(Cal.daysBetween(Cal.today, e.start)) days out.").type(.headingMd).foregroundStyle(MColor.text)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("\(e.name) · \(client.name) on WhatsApp, today 08:12").type(.caption).foregroundStyle(MColor.textMute)
                }
                .frame(maxWidth: .infinity, alignment: .leading).card()

                // Impact list: resource · specific delta · state
                RowGroup {
                    ForEach(Array(Seed.changeImpacts.enumerated()), id: \.element.id) { i, imp in
                        if i > 0 { Hairline() }
                        HStack(spacing: Space.md) {
                            Image(systemName: imp.icon).font(.system(size: 17, weight: .light)).foregroundStyle(imp.isShort ? MColor.danger : MColor.textMute)
                                .frame(width: Dim.avatar, height: Dim.avatar)
                                .background(imp.isShort ? MColor.dangerTint : Color.clear, in: Circle())
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

                // Revised total against original
                VStack(spacing: Space.md) {
                    totalRow("Original quote", original)
                    totalRow("Added cost to you", addedCost)
                    Rectangle().fill(MColor.line).frame(height: 1)
                    HStack(alignment: .firstTextBaseline) {
                        Text("Revised quote").type(.bodyMdStrong).foregroundStyle(MColor.text)
                        Spacer()
                        Text(Fmt.inr(revised)).type(.headingLg).foregroundStyle(MColor.text).monospacedDigit()
                    }
                    Text("200 guests at ₹\(perGuest) · \(Fmt.inr(margin)) margin on the change").type(.caption).foregroundStyle(MColor.textMute)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .card()
            }
            .dockedActions {
                VStack(spacing: Space.sm) {
                    MButton(title: "Approve and send revised quote") { store.approveChangeRequest(eventId: e.id); store.pop() }
                    // Decline is tertiary, not destructive — declining destroys nothing (NOTES Phase 3).
                    MButton(title: "Decline change", style: .tertiary, size: .compact) { store.declineChangeRequest(); store.pop() }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Call \(client.name)", systemImage: "phone") { if let u = URL(string: "tel://\(client.phone.replacingOccurrences(of: " ", with: ""))") { UIApplication.shared.open(u) } }
                        Button("Open event", systemImage: "calendar") { store.push(.eventDetail(e.id)) }
                    } label: { Image(systemName: "ellipsis") }
                }
            }
        }
    }

    private func totalRow(_ label: String, _ amount: Int) -> some View {
        HStack { Text(label).type(.bodyMd).foregroundStyle(MColor.textMute); Spacer(); Money(amount) }
    }
}
