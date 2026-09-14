import SwiftUI

/// Five destinations in the system tab bar (Liquid Glass on iOS 26). Each tab owns a NavigationStack.
struct RootView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        @Bindable var store = store
        TabView(selection: $store.selectedTab) {
            ForEach(AppTab.allCases) { tab in
                Tab(tab.title, systemImage: tab.symbol, value: tab) {
                    NavigationStack(path: store.binding(for: tab)) {
                        root(for: tab)
                            .navigationDestination(for: Route.self) { route in
                                // Pushed screens drop the tab bar (NOTES tab bar policy): frees the bottom for timelines, forms and docked actions.
                                destination(route).toolbar(.hidden, for: .tabBar)
                            }
                    }
                }
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .overlay(alignment: .bottom) {
            if let toast = store.toast {
                ToastView(toast: toast)
                    .padding(.bottom, 72)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    @ViewBuilder
    private func root(for tab: AppTab) -> some View {
        switch tab {
        case .home: HomeView()
        case .events: EventListView()
        case .money: ReceivablesView()
        case .team: CrewListView()
        case .profile: ProfileView()
        }
    }

    @ViewBuilder
    private func destination(_ route: Route) -> some View {
        switch route {
        case .calendarMonth: CalendarMonthView()
        case .dayDetail(let d): DayDetailView(day: d)
        case .seasonSummary: SeasonSummaryView()
        case .eventDetail(let id): EventDetailView(eventId: id)
        case .createEvent: CreateEventView()
        case .runsheet(let id): RunsheetView(eventId: id)
        case .changeRequest(let id): ChangeRequestView(requestId: id)
        case .paymentSchedule(let id): PaymentScheduleView(eventId: id)
        case .expenses(let id): ExpensesView(eventId: id)
        case .assignCrew(let id): AssignCrewView(eventId: id)
        case .attendance(let id): AttendanceView(initialEventId: id)
        case .inventory: InventoryView()
        case .itemDetail(let id): ItemDetailView(itemId: id)
        case .clients: ClientListView()
        case .sharedPage(let id): SharedEventPageView(eventId: id)
        case .enquiry(let id): EnquiryIntakeView(enquiryId: id)
        case .crewList: CrewListView(pushed: true)
        case .packages: PackagesView()
        case .account: AccountView()
        }
    }
}
