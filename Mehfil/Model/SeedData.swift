import Foundation

// The content model is fixed by NOTES.md ("Content model (fixed for all phases)").
// Every string, number and date here is real content, never placeholder (spec §6).

enum Seed {
    static let vendorFirstName = "Anand"
    static let vendorName = "Anand Mehra"
    static let businessName = "Mehfil Decor"
    static let businessArea = "Sector 44, Gurugram"
    static let businessSince = "since 2018"
    static let businessPhone = "98110 08123"
    static let upi = "mehfil@upi"
    static let bank = "HDFC ••4471"

    static let venues = (
        leela: Venue(name: "The Leela Ambience", area: "Gurugram", hall: "Grand Ballroom"),
        ashiyana: Venue(name: "Ashiyana Farms", area: "Chattarpur", hall: nil),
        sky: Venue(name: "Sky Banquets", area: "Sector 29", hall: nil),
        taj: Venue(name: "Taj Palace", area: "New Delhi", hall: nil)
    )

    static let clients: [Client] = [
        Client(id: "kapoor", name: "Vikram Kapoor", phone: "98110 42760", isRepeat: false, eventCount: 1, lifetimeValue: 640_000, nextEventDate: Cal.date(2026, 11, 14), avatar: 1),
        Client(id: "sharma", name: "Ritu Sharma", phone: "98100 51234", isRepeat: true, eventCount: 2, lifetimeValue: 970_000, nextEventDate: Cal.date(2026, 11, 14), avatar: 2),
        Client(id: "gill", name: "Harpreet Gill", phone: "98180 66210", isRepeat: true, eventCount: 2, lifetimeValue: 505_000, nextEventDate: Cal.date(2026, 11, 14), avatar: 8),
        Client(id: "fernandes", name: "Melissa Fernandes", phone: "98910 30045", isRepeat: false, eventCount: 1, lifetimeValue: 980_000, nextEventDate: Cal.date(2026, 11, 21), avatar: 6),
        Client(id: "reddy", name: "Lakshmi Reddy", phone: "98990 12876", isRepeat: true, eventCount: 3, lifetimeValue: 665_000, nextEventDate: Cal.date(2026, 11, 29), avatar: 7),
        Client(id: "ahmed", name: "Farah Ahmed", phone: "98710 40320", isRepeat: true, eventCount: 3, lifetimeValue: 840_000, nextEventDate: Cal.date(2026, 12, 12), avatar: 3),
    ]

    static let events: [Event] = [
        Event(id: "kapoor-sangeet", name: "Kapoor sangeet", clientId: "kapoor", type: .sangeet,
              start: Cal.date(2026, 11, 14, 17, 0), end: Cal.date(2026, 11, 14, 23, 30), venue: venues.leela,
              guests: 450, quoted: 640_000, hue: .one, status: .upcoming, crewAssigned: 12, crewNeeded: 14, crewPlan: "2 coordinators, 6 decorators, 6 helpers",
              hasCrewConflict: true, inventorySummary: "250 chairs · 120 drapes · 24 par cans", runsheetSummary: "8 tasks · setup 09:00 · 2 done"),
        Event(id: "sharma-mehendi", name: "Sharma mehendi", clientId: "sharma", type: .mehendi,
              start: Cal.date(2026, 11, 14, 12, 0), end: Cal.date(2026, 11, 14, 17, 0), venue: venues.ashiyana,
              guests: 200, quoted: 210_000, hue: .two, status: .upcoming, crewAssigned: 8, crewNeeded: 8, crewPlan: "1 coordinator, 3 decorators, 4 helpers",
              hasCrewConflict: false, inventorySummary: "80 chairs · 90 drapes · 15 tables", runsheetSummary: "5 tasks · setup 08:00"),
        Event(id: "gill-engagement", name: "Gill engagement", clientId: "gill", type: .engagement,
              start: Cal.date(2026, 11, 14, 19, 0), end: Cal.date(2026, 11, 14, 23, 0), venue: venues.sky,
              guests: 180, quoted: 195_000, hue: .three, status: .upcoming, crewAssigned: 8, crewNeeded: 8, crewPlan: "1 coordinator, 3 decorators, 4 helpers",
              hasCrewConflict: true, inventorySummary: "50 chairs · 80 drapes · 16 par cans", runsheetSummary: "6 tasks · setup 14:00"),
        Event(id: "fernandes-reception", name: "Fernandes reception", clientId: "fernandes", type: .reception,
              start: Cal.date(2026, 11, 21, 19, 0), end: Cal.date(2026, 11, 22, 0, 0), venue: venues.taj,
              guests: 600, quoted: 980_000, hue: .four, status: .upcoming, crewAssigned: 18, crewNeeded: 18,
              hasCrewConflict: false, inventorySummary: "600 chairs · 160 drapes · 60 tables", runsheetSummary: "9 tasks · setup 10:00"),
        Event(id: "reddy-haldi", name: "Reddy haldi", clientId: "reddy", type: .haldi,
              start: Cal.date(2026, 11, 29, 10, 0), end: Cal.date(2026, 11, 29, 14, 0), venue: venues.ashiyana,
              guests: 150, quoted: 180_000, hue: .one, status: .upcoming, crewAssigned: 6, crewNeeded: 6,
              hasCrewConflict: false, inventorySummary: "150 chairs · 40 drapes", runsheetSummary: "4 tasks · setup 07:00"),
        Event(id: "sharma-reception", name: "Sharma reception", clientId: "sharma", type: .reception,
              start: Cal.date(2026, 12, 5, 19, 0), end: Cal.date(2026, 12, 6, 0, 0), venue: venues.taj,
              guests: 500, quoted: 760_000, hue: .two, status: .upcoming, crewAssigned: 16, crewNeeded: 16,
              hasCrewConflict: false, inventorySummary: "500 chairs · 140 drapes · 50 tables", runsheetSummary: "8 tasks · setup 10:00"),
        Event(id: "ahmed-nikah", name: "Ahmed nikah", clientId: "ahmed", type: .nikah,
              start: Cal.date(2026, 12, 12, 11, 0), end: Cal.date(2026, 12, 12, 16, 0), venue: venues.leela,
              guests: 350, quoted: 420_000, hue: .three, status: .upcoming, crewAssigned: 10, crewNeeded: 10,
              hasCrewConflict: false, inventorySummary: "350 chairs · 100 drapes", runsheetSummary: "6 tasks · setup 07:00"),
        Event(id: "reddy-reception", name: "Reddy reception", clientId: "reddy", type: .reception,
              start: Cal.date(2026, 12, 19, 19, 0), end: Cal.date(2026, 12, 20, 0, 0), venue: venues.sky,
              guests: 300, quoted: 340_000, hue: .four, status: .upcoming, crewAssigned: 12, crewNeeded: 12,
              hasCrewConflict: false, inventorySummary: "300 chairs · 80 drapes", runsheetSummary: "7 tasks · setup 11:00"),
        Event(id: "ahmed-reception", name: "Ahmed reception", clientId: "ahmed", type: .reception,
              start: Cal.date(2027, 1, 9, 19, 0), end: Cal.date(2027, 1, 10, 0, 0), venue: venues.leela,
              guests: 400, quoted: 260_000, hue: .one, status: .upcoming, crewAssigned: 0, crewNeeded: 12,
              hasCrewConflict: false, inventorySummary: "Not planned yet", runsheetSummary: "No tasks yet"),
        Event(id: "ahmed-mehendi", name: "Ahmed mehendi", clientId: "ahmed", type: .mehendi,
              start: Cal.date(2026, 10, 3, 12, 0), end: Cal.date(2026, 10, 3, 17, 0), venue: venues.ashiyana,
              guests: 120, quoted: 160_000, hue: .two, status: .completed, crewAssigned: 6, crewNeeded: 6,
              hasCrewConflict: false, inventorySummary: "120 chairs · 40 drapes", runsheetSummary: "5 tasks · all done"),
        Event(id: "reddy-engagement", name: "Reddy engagement", clientId: "reddy", type: .engagement,
              start: Cal.date(2026, 10, 10, 18, 0), end: Cal.date(2026, 10, 10, 23, 0), venue: venues.sky,
              guests: 160, quoted: 145_000, hue: .three, status: .completed, crewAssigned: 7, crewNeeded: 7,
              hasCrewConflict: false, inventorySummary: "160 chairs · 60 drapes", runsheetSummary: "6 tasks · all done"),
        Event(id: "gill-sangeet", name: "Gill sangeet", clientId: "gill", type: .sangeet,
              start: Cal.date(2026, 10, 24, 18, 0), end: Cal.date(2026, 10, 25, 0, 0), venue: venues.leela,
              guests: 300, quoted: 310_000, hue: .four, status: .completed, crewAssigned: 12, crewNeeded: 12,
              hasCrewConflict: false, inventorySummary: "300 chairs · 100 drapes", runsheetSummary: "8 tasks · all done"),
    ]

    static let milestones: [Milestone] = [
        // Kapoor sangeet — advance paid, second overdue, balance in 2 days, settlement 30 Nov
        Milestone(id: "kap-1", eventId: "kapoor-sangeet", name: "Booking advance", amount: 160_000, due: Cal.date(2026, 10, 2), status: .paid, paidOn: Cal.date(2026, 10, 2), method: .upi, reference: "2810…4471", kind: .advance),
        Milestone(id: "kap-2", eventId: "kapoor-sangeet", name: "Second instalment", amount: 240_000, due: Cal.date(2026, 11, 7), status: .overdue, paidOn: nil, method: nil, reference: nil, kind: .instalment),
        Milestone(id: "kap-3", eventId: "kapoor-sangeet", name: "Balance", amount: 160_000, due: Cal.date(2026, 11, 14), status: .pending, paidOn: nil, method: nil, reference: nil, kind: .balance),
        Milestone(id: "kap-4", eventId: "kapoor-sangeet", name: "Post-event settlement", amount: 80_000, due: Cal.date(2026, 11, 30), status: .pending, paidOn: nil, method: nil, reference: nil, kind: .settlement),
        // Sharma mehendi
        Milestone(id: "shm-1", eventId: "sharma-mehendi", name: "Booking advance", amount: 105_000, due: Cal.date(2026, 9, 20), status: .paid, paidOn: Cal.date(2026, 9, 20), method: .bank, reference: nil, kind: .advance),
        Milestone(id: "shm-2", eventId: "sharma-mehendi", name: "Balance", amount: 105_000, due: Cal.date(2026, 11, 14), status: .pending, paidOn: nil, method: nil, reference: nil, kind: .balance),
        // Gill engagement
        Milestone(id: "gil-1", eventId: "gill-engagement", name: "Booking advance", amount: 60_000, due: Cal.date(2026, 10, 1), status: .paid, paidOn: Cal.date(2026, 10, 1), method: .upi, reference: nil, kind: .advance),
        Milestone(id: "gil-2", eventId: "gill-engagement", name: "Balance", amount: 135_000, due: Cal.date(2026, 11, 14), status: .pending, paidOn: nil, method: nil, reference: nil, kind: .balance),
        // Fernandes reception
        Milestone(id: "fer-1", eventId: "fernandes-reception", name: "Booking advance", amount: 490_000, due: Cal.date(2026, 9, 5), status: .paid, paidOn: Cal.date(2026, 9, 5), method: .bank, reference: nil, kind: .advance),
        Milestone(id: "fer-2", eventId: "fernandes-reception", name: "Second instalment", amount: 245_000, due: Cal.date(2026, 11, 18), status: .pending, paidOn: nil, method: nil, reference: nil, kind: .instalment),
        Milestone(id: "fer-3", eventId: "fernandes-reception", name: "Balance", amount: 245_000, due: Cal.date(2026, 11, 21), status: .pending, paidOn: nil, method: nil, reference: nil, kind: .balance),
        // Reddy haldi
        Milestone(id: "rh-1", eventId: "reddy-haldi", name: "Booking advance", amount: 45_000, due: Cal.date(2026, 10, 15), status: .paid, paidOn: Cal.date(2026, 10, 15), method: .cash, reference: nil, kind: .advance),
        Milestone(id: "rh-2", eventId: "reddy-haldi", name: "Balance", amount: 135_000, due: Cal.date(2026, 11, 29), status: .pending, paidOn: nil, method: nil, reference: nil, kind: .balance),
        // Sharma reception — advance overdue since 1 Nov
        Milestone(id: "shr-1", eventId: "sharma-reception", name: "Advance", amount: 190_000, due: Cal.date(2026, 11, 1), status: .overdue, paidOn: nil, method: nil, reference: nil, kind: .advance),
        Milestone(id: "shr-2", eventId: "sharma-reception", name: "Second instalment", amount: 285_000, due: Cal.date(2026, 11, 28), status: .pending, paidOn: nil, method: nil, reference: nil, kind: .instalment),
        Milestone(id: "shr-3", eventId: "sharma-reception", name: "Balance", amount: 285_000, due: Cal.date(2026, 12, 5), status: .pending, paidOn: nil, method: nil, reference: nil, kind: .balance),
        // Ahmed nikah
        Milestone(id: "an-1", eventId: "ahmed-nikah", name: "Booking advance", amount: 105_000, due: Cal.date(2026, 10, 20), status: .paid, paidOn: Cal.date(2026, 10, 20), method: .upi, reference: nil, kind: .advance),
        Milestone(id: "an-2", eventId: "ahmed-nikah", name: "Second instalment", amount: 157_500, due: Cal.date(2026, 11, 28), status: .pending, paidOn: nil, method: nil, reference: nil, kind: .instalment),
        // Reddy reception — advance due 5 Dec
        Milestone(id: "rr-1", eventId: "reddy-reception", name: "Booking advance", amount: 85_000, due: Cal.date(2026, 12, 5), status: .pending, paidOn: nil, method: nil, reference: nil, kind: .advance),
        // Completed events — all paid
        Milestone(id: "am-1", eventId: "ahmed-mehendi", name: "Full payment", amount: 160_000, due: Cal.date(2026, 10, 3), status: .paid, paidOn: Cal.date(2026, 10, 3), method: .upi, reference: nil, kind: .balance),
        Milestone(id: "re-1", eventId: "reddy-engagement", name: "Full payment", amount: 145_000, due: Cal.date(2026, 10, 10), status: .paid, paidOn: Cal.date(2026, 10, 10), method: .bank, reference: nil, kind: .balance),
        Milestone(id: "gs-1", eventId: "gill-sangeet", name: "Full payment", amount: 310_000, due: Cal.date(2026, 10, 24), status: .paid, paidOn: Cal.date(2026, 10, 24), method: .upi, reference: nil, kind: .balance),
    ]

    /// Reminders already sent for the Kapoor second instalment (NOTES: "Sent before" on C4).
    static let sentReminders: [String: [SentReminder]] = [
        "kap-2": [
            SentReminder(id: "r1", tone: .gentle, sent: Cal.date(2026, 11, 9, 10, 15), channel: .whatsapp, outcome: "seen 10:40 · no reply"),
            SentReminder(id: "r2", tone: .standard, sent: Cal.date(2026, 11, 11, 9, 2), channel: .sms, outcome: "delivered"),
        ]
    ]

    static let crew: [CrewMember] = [
        CrewMember(id: "priya", name: "Priya Malhotra", role: .coordinator, isLead: false, avatar: 7, bookedOn: ["kapoor-sangeet"], availabilityNote: nil),
        CrewMember(id: "rohit", name: "Rohit Verma", role: .coordinator, isLead: false, avatar: 1, bookedOn: ["sharma-mehendi"], availabilityNote: "coordinator"),
        CrewMember(id: "suresh", name: "Suresh Yadav", role: .decorator, isLead: true, avatar: 5, bookedOn: ["kapoor-sangeet", "gill-engagement"], availabilityNote: "lead"),
        CrewMember(id: "manoj", name: "Manoj Kumar", role: .decorator, isLead: false, avatar: 8, bookedOn: ["kapoor-sangeet"], availabilityNote: nil),
        CrewMember(id: "deepak", name: "Deepak Singh", role: .decorator, isLead: false, avatar: 4, bookedOn: ["kapoor-sangeet"], availabilityNote: nil),
        CrewMember(id: "arjun", name: "Arjun Mehta", role: .decorator, isLead: false, avatar: 2, bookedOn: ["kapoor-sangeet"], availabilityNote: nil),
        CrewMember(id: "kavita", name: "Kavita Rani", role: .decorator, isLead: false, avatar: 6, bookedOn: ["sharma-mehendi"], availabilityNote: "free from 17:30"),
        CrewMember(id: "ramesh", name: "Ramesh", role: .helper, isLead: false, avatar: 3, bookedOn: ["kapoor-sangeet"], availabilityNote: nil),
        CrewMember(id: "sunil", name: "Sunil", role: .helper, isLead: false, avatar: nil, bookedOn: [], availabilityNote: "free all day"),
        CrewMember(id: "vikram-s", name: "Vikram Singh", role: .helper, isLead: false, avatar: 1, bookedOn: ["kapoor-sangeet"], availabilityNote: nil),
        CrewMember(id: "anil", name: "Anil", role: .helper, isLead: false, avatar: nil, bookedOn: ["gill-engagement"], availabilityNote: nil),
        CrewMember(id: "ravi", name: "Ravi", role: .helper, isLead: false, avatar: nil, bookedOn: ["gill-engagement"], availabilityNote: nil),
        CrewMember(id: "mohan", name: "Mohan", role: .helper, isLead: false, avatar: nil, bookedOn: ["sharma-mehendi"], availabilityNote: nil),
    ]

    /// Attendance on the focal event morning (D3), keyed by crew id.
    static let kapoorAttendance: [(String, AttendanceState)] = [
        ("priya", .arrived), ("suresh", .arrived), ("manoj", .arrived), ("deepak", .confirmed), ("arjun", .confirmed),
        ("ramesh", .arrived), ("vikram-s", .absent), ("sunil", .confirmed),
        ("anil", .arrived), ("ravi", .arrived), ("mohan", .arrived), ("kavita", .arrived),
    ]
    static let sharmaAttendance: [(String, AttendanceState)] = [
        ("rohit", .arrived), ("kavita", .arrived), ("mohan", .confirmed), ("sunil", .arrived),
    ]
    static let gillAttendance: [(String, AttendanceState)] = [
        ("suresh", .confirmed), ("anil", .confirmed), ("ravi", .confirmed),
    ]

    static let inventory: [InventoryItem] = {
        let d14 = Cal.date(2026, 11, 14), d21 = Cal.date(2026, 11, 21), d29 = Cal.date(2026, 11, 29), d5 = Cal.date(2026, 12, 5), d12 = Cal.date(2026, 12, 12), d19 = Cal.date(2026, 12, 19)
        return [
            InventoryItem(id: "drapes", name: "Drape panels", total: 240, detail: "3 m velvet · 12 colours", holds: [
                .init(eventId: "kapoor-sangeet", qty: 120, date: d14), .init(eventId: "sharma-mehendi", qty: 90, date: d14), .init(eventId: "gill-engagement", qty: 80, date: d14),
                .init(eventId: "fernandes-reception", qty: 160, date: d21), .init(eventId: "sharma-reception", qty: 140, date: d5), .init(eventId: "ahmed-nikah", qty: 100, date: d12)]),
            InventoryItem(id: "tables", name: "Round tables", total: 60, detail: "6 ft · seats 10", holds: [
                .init(eventId: "kapoor-sangeet", qty: 45, date: d14), .init(eventId: "sharma-mehendi", qty: 15, date: d14),
                .init(eventId: "fernandes-reception", qty: 60, date: d21), .init(eventId: "sharma-reception", qty: 50, date: d5)]),
            InventoryItem(id: "chairs", name: "Chiavari chairs", total: 600, detail: "Gold · with cushions", holds: [
                .init(eventId: "kapoor-sangeet", qty: 250, date: d14), .init(eventId: "sharma-mehendi", qty: 80, date: d14), .init(eventId: "gill-engagement", qty: 50, date: d14),
                .init(eventId: "fernandes-reception", qty: 600, date: d21), .init(eventId: "reddy-haldi", qty: 150, date: d29), .init(eventId: "sharma-reception", qty: 500, date: d5),
                .init(eventId: "ahmed-nikah", qty: 350, date: d12), .init(eventId: "reddy-reception", qty: 300, date: d19)]),
            InventoryItem(id: "parcans", name: "Par cans", total: 48, detail: "LED · RGBW", holds: [
                .init(eventId: "kapoor-sangeet", qty: 24, date: d14), .init(eventId: "gill-engagement", qty: 16, date: d14),
                .init(eventId: "fernandes-reception", qty: 40, date: d21)]),
            InventoryItem(id: "risers", name: "Stage risers", total: 24, detail: "4 × 8 ft · 2 ft high", holds: [
                .init(eventId: "kapoor-sangeet", qty: 12, date: d14), .init(eventId: "gill-engagement", qty: 6, date: d14),
                .init(eventId: "fernandes-reception", qty: 20, date: d21)]),
        ]
    }()

    static let runsheet: [RunsheetTask] = [
        RunsheetTask(id: "t1", eventId: "kapoor-sangeet", block: "Setup", blockTime: "09:00–14:00", title: "Unload and set stage risers", crew: "Suresh's team · 6 crew", duration: "1 h 30", done: true),
        RunsheetTask(id: "t2", eventId: "kapoor-sangeet", block: "Setup", blockTime: "09:00–14:00", title: "Rig par cans on truss", crew: "Deepak, Arjun", duration: "2 h", done: true),
        RunsheetTask(id: "t3", eventId: "kapoor-sangeet", block: "Setup", blockTime: "09:00–14:00", title: "Hang 120 drape panels", crew: "Manoj's team · 4 crew", duration: "3 h", done: false),
        RunsheetTask(id: "t4", eventId: "kapoor-sangeet", block: "Dressing", blockTime: "14:00–17:00", title: "Floral mandap and entrance", crew: "Kavita · 3 crew", duration: "2 h 30", done: false),
        RunsheetTask(id: "t5", eventId: "kapoor-sangeet", block: "Dressing", blockTime: "14:00–17:00", title: "Lay 45 round tables", crew: "Ramesh, Sunil, Vikram", duration: "1 h", done: false),
        RunsheetTask(id: "t6", eventId: "kapoor-sangeet", block: "Event", blockTime: "17:00–23:30", title: "Lights and sound check", crew: "Deepak · 30 min", duration: "before 16:30", done: false),
        RunsheetTask(id: "t7", eventId: "kapoor-sangeet", block: "Event", blockTime: "17:00–23:30", title: "Welcome florals at guest arrival", crew: "Kavita · 2 crew", duration: "17:00", done: false),
        RunsheetTask(id: "t8", eventId: "kapoor-sangeet", block: "Event", blockTime: "17:00–23:30", title: "Pack-down and load trucks", crew: "All crew", duration: "from 23:30", done: false),
    ]
    static let runsheetMarkers = ["09:00", "12:00", "14:00", "17:00", "21:00", "23:30"]

    static let gillExpenses: [Expense] = [
        Expense(id: "e1", name: "Agency crew · conflict cover", detail: "8 crew from Shakti Events · 2 days", amount: 38_400),
        Expense(id: "e2", name: "Flowers", detail: "Marigold, roses, foliage · Ghazipur mandi", amount: 42_000),
        Expense(id: "e3", name: "Lighting and truss hire", detail: "4 m truss · 24 par cans", amount: 35_000),
        Expense(id: "e4", name: "Fabric and drapes", detail: "Cleaning and 40 new panels", amount: 28_000),
        Expense(id: "e5", name: "Venue surcharge", detail: "Sky Banquets · outside vendor fee", amount: 52_000),
        Expense(id: "e6", name: "Transport", detail: "2 trucks · Chattarpur to Sector 29", amount: 12_500),
    ]

    static let packages: [Package] = [
        Package(id: "stage", name: "Stage & backdrop", detail: "12 m truss, 40 par cans", price: 180_000),
        Package(id: "mandap", name: "Floral mandap", detail: "fresh marigold and jasmine", price: 95_000),
        Package(id: "drapes", name: "Drapes & ceiling", detail: "160 panels", price: 130_000),
        Package(id: "arch", name: "Entrance arch", detail: "4 m floral arch", price: 40_000),
    ]

    static let changeImpacts: [ChangeImpact] = [
        ChangeImpact(id: "c1", resource: "Chiavari chairs", detail: "380 → 500 of 600 held on 14 Nov", delta: "+120", isShort: false, icon: "shippingbox"),
        ChangeImpact(id: "c2", resource: "Round tables", detail: "All 60 held · hire 20 more", delta: "+20 · ₹8,000", isShort: true, icon: "shippingbox"),
        ChangeImpact(id: "c3", resource: "Helpers", detail: "Ramesh, Sunil, Anil, Ravi", delta: "+4 · ₹3,200", isShort: false, icon: "person.2"),
        ChangeImpact(id: "c4", resource: "Transport", detail: "Second truck, chairs and tables", delta: "₹4,500", isShort: false, icon: "truck.box"),
    ]

    static let enquiry = Enquiry(id: "q1", name: "Anjali Kapoor", source: "Referral · Vikram Kapoor", budget: "₹3,00,000 – ₹5,00,000",
                                 date: Cal.date(2026, 12, 5), guests: 250,
                                 notes: "Sister's engagement. Pastel florals, saw the Fernandes reel. Wants a quote by Friday.")
    static let enquirySources = ["Referral · Vikram Kapoor", "Instagram", "WhatsApp", "Wedding planner", "Walk-in"]
    static let budgetRanges = ["Under ₹1,50,000", "₹1,50,000 – ₹3,00,000", "₹3,00,000 – ₹5,00,000", "₹5,00,000 – ₹10,00,000", "Over ₹10,00,000"]
    static let openEnquiries = 3
    /// Setup crew at the warehouse today; the app has no shift model yet.
    static let crewOnDutyToday = 4

    // Season 2026–27 (Oct–Feb)
    static let seasonTarget = 6_000_000
    static let lastSeasonBooked = 3_580_000
    static let lastSeasonEvents = 9
    static let seasonMonths: [(String, Int)] = [("Oct", 615_000), ("Nov", 2_205_000), ("Dec", 1_520_000), ("Jan", 260_000), ("Feb", 0)]
}
