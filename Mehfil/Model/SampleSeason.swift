import Foundation

/// The design's content model (NOTES.md), offered as a sample season during onboarding and for demos.
/// Every date is shifted by whole weeks so the focal Saturday lands on the next Saturday from today.
enum SampleSeason {
    static let anchor = Cal.date(2026, 11, 14)      // Kapoor sangeet in the design

    static func profile() -> VendorProfile {
        VendorProfile(ownerName: "Anand Mehra", businessName: "Mehfil Decor", phone: "98110 08123", area: "Sector 44, Gurugram", since: "since 2018",
                      upi: "mehfil@upi", bankLabel: "HDFC ••4471", seasonTarget: 6_000_000, lastSeasonBooked: 3_580_000, lastSeasonEvents: 9,
                      notifyPayments: true, notifyConflicts: true, notifyChanges: true, createdAt: Cal.today)
    }

    static func data() -> VendorData {
        let shiftDays = Cal.daysBetween(anchor, Cal.nextSaturday)
        func d(_ y: Int, _ m: Int, _ day: Int, _ h: Int = 0, _ min: Int = 0) -> Date { Cal.adding(shiftDays, .day, to: Cal.date(y, m, day, h, min)) }
        let now = Cal.today

        let leela = Venue(name: "The Leela Ambience", area: "Gurugram", hall: "Grand Ballroom")
        let ashiyana = Venue(name: "Ashiyana Farms", area: "Chattarpur", hall: nil)
        let sky = Venue(name: "Sky Banquets", area: "Sector 29", hall: nil)
        let taj = Venue(name: "Taj Palace", area: "New Delhi", hall: nil)

        var v = VendorData()
        v.clients = [
            Client(id: "kapoor", name: "Vikram Kapoor", phone: "98110 42760", isRepeat: false, avatar: 1, createdAt: now),
            Client(id: "sharma", name: "Ritu Sharma", phone: "98100 51234", isRepeat: true, avatar: 2, createdAt: now),
            Client(id: "gill", name: "Harpreet Gill", phone: "98180 66210", isRepeat: true, avatar: 8, createdAt: now),
            Client(id: "fernandes", name: "Melissa Fernandes", phone: "98910 30045", isRepeat: false, avatar: 6, createdAt: now),
            Client(id: "reddy", name: "Lakshmi Reddy", phone: "98990 12876", isRepeat: true, avatar: 7, createdAt: now),
            Client(id: "ahmed", name: "Farah Ahmed", phone: "98710 40320", isRepeat: true, avatar: 3, createdAt: now),
        ]
        func ev(_ id: String, _ name: String, _ client: String, _ type: EventType, _ start: Date, _ end: Date, _ venue: Venue, _ guests: Int, _ quoted: Int, _ hue: EventHue,
                _ status: EventStatus, _ assigned: Int, _ needed: Int, _ plan: String? = nil, _ inv: String, _ needsPlan: Bool = false) -> Event {
            Event(id: id, name: name, clientId: client, type: type, start: start, end: end, venue: venue, guests: guests, quoted: quoted, hue: hue, status: status,
                  crewAssigned: assigned, crewNeeded: needed, crewPlan: plan, inventorySummary: inv, createdAt: now)
        }
        v.events = [
            ev("kapoor-sangeet", "Kapoor sangeet", "kapoor", .sangeet, d(2026, 11, 14, 17), d(2026, 11, 14, 23, 30), leela, 450, 640_000, .one, .upcoming, 12, 14, "2 coordinators, 6 decorators, 6 helpers", "250 chairs · 120 drapes · 24 par cans"),
            ev("sharma-mehendi", "Sharma mehendi", "sharma", .mehendi, d(2026, 11, 14, 12), d(2026, 11, 14, 17), ashiyana, 200, 210_000, .two, .upcoming, 8, 8, "1 coordinator, 3 decorators, 4 helpers", "80 chairs · 90 drapes · 15 tables"),
            ev("gill-engagement", "Gill engagement", "gill", .engagement, d(2026, 11, 14, 19), d(2026, 11, 14, 23), sky, 180, 195_000, .three, .upcoming, 8, 8, "1 coordinator, 3 decorators, 4 helpers", "50 chairs · 80 drapes · 16 par cans"),
            ev("fernandes-reception", "Fernandes reception", "fernandes", .reception, d(2026, 11, 21, 19), d(2026, 11, 22, 0), taj, 600, 980_000, .four, .upcoming, 18, 18, nil, "600 chairs · 160 drapes · 60 tables"),
            ev("reddy-haldi", "Reddy haldi", "reddy", .haldi, d(2026, 11, 29, 10), d(2026, 11, 29, 14), ashiyana, 150, 180_000, .one, .upcoming, 6, 6, nil, "150 chairs · 40 drapes"),
            ev("sharma-reception", "Sharma reception", "sharma", .reception, d(2026, 12, 5, 19), d(2026, 12, 6, 0), taj, 500, 760_000, .two, .upcoming, 16, 16, nil, "500 chairs · 140 drapes · 50 tables"),
            ev("ahmed-nikah", "Ahmed nikah", "ahmed", .nikah, d(2026, 12, 12, 11), d(2026, 12, 12, 16), leela, 350, 420_000, .three, .upcoming, 10, 10, nil, "350 chairs · 100 drapes"),
            ev("reddy-reception", "Reddy reception", "reddy", .reception, d(2026, 12, 19, 19), d(2026, 12, 20, 0), sky, 300, 340_000, .four, .upcoming, 12, 12, nil, "300 chairs · 80 drapes"),
            ev("ahmed-reception", "Ahmed reception", "ahmed", .reception, d(2027, 1, 9, 19), d(2027, 1, 10, 0), leela, 400, 260_000, .one, .upcoming, 0, 12, nil, nil ?? "Not planned yet"),
            ev("ahmed-mehendi", "Ahmed mehendi", "ahmed", .mehendi, d(2026, 10, 3, 12), d(2026, 10, 3, 17), ashiyana, 120, 160_000, .two, .completed, 6, 6, nil, "120 chairs · 40 drapes"),
            ev("reddy-engagement", "Reddy engagement", "reddy", .engagement, d(2026, 10, 10, 18), d(2026, 10, 10, 23), sky, 160, 145_000, .three, .completed, 7, 7, nil, "160 chairs · 60 drapes"),
            ev("gill-sangeet", "Gill sangeet", "gill", .sangeet, d(2026, 10, 24, 18), d(2026, 10, 25, 0), leela, 300, 310_000, .four, .completed, 12, 12, nil, "300 chairs · 100 drapes"),
        ]
        func ms(_ id: String, _ e: String, _ name: String, _ amt: Int, _ due: Date, _ st: MilestoneStatus, _ kind: MilestoneKind, paid: Date? = nil, method: PaymentMethod? = nil, ref: String? = nil) -> Milestone {
            Milestone(id: id, eventId: e, name: name, amount: amt, due: due, status: st, kind: kind, paidOn: paid, method: method, reference: ref)
        }
        v.milestones = [
            ms("kap-1", "kapoor-sangeet", "Booking advance", 160_000, d(2026, 10, 2), .paid, .advance, paid: d(2026, 10, 2), method: .upi, ref: "2810…4471"),
            ms("kap-2", "kapoor-sangeet", "Second instalment", 240_000, d(2026, 11, 7), .pending, .instalment),
            ms("kap-3", "kapoor-sangeet", "Balance", 160_000, d(2026, 11, 14), .pending, .balance),
            ms("kap-4", "kapoor-sangeet", "Post-event settlement", 80_000, d(2026, 11, 30), .pending, .settlement),
            ms("shm-1", "sharma-mehendi", "Booking advance", 105_000, d(2026, 9, 20), .paid, .advance, paid: d(2026, 9, 20), method: .bank),
            ms("shm-2", "sharma-mehendi", "Balance", 105_000, d(2026, 11, 14), .pending, .balance),
            ms("gil-1", "gill-engagement", "Booking advance", 60_000, d(2026, 10, 1), .paid, .advance, paid: d(2026, 10, 1), method: .upi),
            ms("gil-2", "gill-engagement", "Balance", 135_000, d(2026, 11, 14), .pending, .balance),
            ms("fer-1", "fernandes-reception", "Booking advance", 490_000, d(2026, 9, 5), .paid, .advance, paid: d(2026, 9, 5), method: .bank),
            ms("fer-2", "fernandes-reception", "Second instalment", 245_000, d(2026, 11, 18), .pending, .instalment),
            ms("fer-3", "fernandes-reception", "Balance", 245_000, d(2026, 11, 21), .pending, .balance),
            ms("rh-1", "reddy-haldi", "Booking advance", 45_000, d(2026, 10, 15), .paid, .advance, paid: d(2026, 10, 15), method: .cash),
            ms("rh-2", "reddy-haldi", "Balance", 135_000, d(2026, 11, 29), .pending, .balance),
            ms("shr-1", "sharma-reception", "Advance", 190_000, d(2026, 11, 1), .pending, .advance),
            ms("shr-2", "sharma-reception", "Second instalment", 285_000, d(2026, 11, 28), .pending, .instalment),
            ms("shr-3", "sharma-reception", "Balance", 285_000, d(2026, 12, 5), .pending, .balance),
            ms("an-1", "ahmed-nikah", "Booking advance", 105_000, d(2026, 10, 20), .paid, .advance, paid: d(2026, 10, 20), method: .upi),
            ms("an-2", "ahmed-nikah", "Second instalment", 157_500, d(2026, 11, 28), .pending, .instalment),
            ms("rr-1", "reddy-reception", "Booking advance", 85_000, d(2026, 12, 5), .pending, .advance),
            ms("am-1", "ahmed-mehendi", "Full payment", 160_000, d(2026, 10, 3), .paid, .balance, paid: d(2026, 10, 3), method: .upi),
            ms("re-1", "reddy-engagement", "Full payment", 145_000, d(2026, 10, 10), .paid, .balance, paid: d(2026, 10, 10), method: .bank),
            ms("gs-1", "gill-sangeet", "Full payment", 310_000, d(2026, 10, 24), .paid, .balance, paid: d(2026, 10, 24), method: .upi),
        ]
        v.reminders = [
            SentReminder(id: "r1", milestoneId: "kap-2", tone: .gentle, channel: .whatsapp, sentAt: d(2026, 11, 9, 10, 15), outcome: "seen 10:40 · no reply"),
            SentReminder(id: "r2", milestoneId: "kap-2", tone: .standard, channel: .sms, sentAt: d(2026, 11, 11, 9, 2), outcome: "delivered"),
        ]
        func cm(_ id: String, _ name: String, _ role: CrewRole, lead: Bool = false, avatar: Int? = nil, _ bookings: [String] = [], note: String? = nil) -> CrewMember {
            CrewMember(id: id, name: name, role: role, isLead: lead, dayRate: role.defaultDayRate, avatar: avatar, bookings: bookings, note: note)
        }
        let K = "kapoor-sangeet", S = "sharma-mehendi", G = "gill-engagement"
        v.crew = [
            cm("priya", "Priya Malhotra", .coordinator, avatar: 7, [K]),
            cm("rohit", "Rohit Verma", .coordinator, avatar: 1, [S], note: "coordinator"),
            cm("suresh", "Suresh Yadav", .decorator, lead: true, avatar: 5, [K, G], note: "lead"),
            cm("manoj", "Manoj Kumar", .decorator, avatar: 8, [K]),
            cm("deepak", "Deepak Singh", .decorator, avatar: 4, [K]),
            cm("arjun", "Arjun Mehta", .decorator, avatar: 2, [K]),
            cm("kavita", "Kavita Rani", .decorator, avatar: 6, [S], note: "free from 17:30"),
            cm("nitin", "Nitin Saini", .decorator, [G]),
            cm("pooja", "Pooja Bisht", .decorator, [G]),
            cm("ramesh", "Ramesh", .helper, avatar: 3, [K]),
            cm("sunil", "Sunil", .helper, [], note: "free all day"),
            cm("vikram-s", "Vikram Singh", .helper, avatar: 1, [K]),
            cm("anil", "Anil", .helper, [G]),
            cm("ravi", "Ravi", .helper, [G]),
            cm("mohan", "Mohan", .helper, [S]),
            cm("ajay", "Ajay", .helper, [K]),
            cm("bhola", "Bhola", .helper, [K]),
            cm("chandan", "Chandan", .helper, [K]),
            cm("dinesh", "Dinesh", .helper, [K]),
            cm("gopal", "Gopal", .helper, [K]),
            cm("harish", "Harish", .helper, [S]),
            cm("imran", "Imran", .helper, [S]),
            cm("jagdish", "Jagdish", .helper, [S]),
            cm("karan", "Karan", .helper, [S]),
            cm("prakash", "Prakash", .helper, [S]),
            cm("lalit", "Lalit", .helper, [G]),
            cm("naveen", "Naveen", .helper, [G]),
            cm("om", "Om Prakash", .helper, [G]),
        ]
        v.attendance = [
            Attendance(id: K, states: ["priya": .arrived, "suresh": .arrived, "manoj": .arrived, "deepak": .confirmed, "arjun": .confirmed, "ramesh": .arrived, "vikram-s": .absent,
                                       "ajay": .arrived, "bhola": .arrived, "chandan": .arrived, "dinesh": .arrived, "gopal": .confirmed]),
            Attendance(id: S, states: ["rohit": .arrived, "kavita": .arrived, "mohan": .confirmed]),
            Attendance(id: G, states: ["suresh": .confirmed, "anil": .confirmed, "ravi": .confirmed]),
        ]
        let d14 = d(2026, 11, 14), d21 = d(2026, 11, 21), d29 = d(2026, 11, 29), d5 = d(2026, 12, 5), d12 = d(2026, 12, 12), d19 = d(2026, 12, 19)
        v.inventory = [
            InventoryItem(id: "drapes", name: "Drape panels", total: 240, detail: "3 m velvet · 12 colours", holds: [
                Hold(eventId: K, qty: 120, date: d14), Hold(eventId: S, qty: 90, date: d14), Hold(eventId: G, qty: 80, date: d14),
                Hold(eventId: "fernandes-reception", qty: 160, date: d21), Hold(eventId: "sharma-reception", qty: 140, date: d5), Hold(eventId: "ahmed-nikah", qty: 100, date: d12)]),
            InventoryItem(id: "tables", name: "Round tables", total: 60, detail: "6 ft · seats 10", holds: [
                Hold(eventId: K, qty: 45, date: d14), Hold(eventId: S, qty: 15, date: d14), Hold(eventId: "fernandes-reception", qty: 60, date: d21), Hold(eventId: "sharma-reception", qty: 50, date: d5)]),
            InventoryItem(id: "chairs", name: "Chiavari chairs", total: 600, detail: "Gold · with cushions", holds: [
                Hold(eventId: K, qty: 250, date: d14), Hold(eventId: S, qty: 80, date: d14), Hold(eventId: G, qty: 50, date: d14),
                Hold(eventId: "fernandes-reception", qty: 600, date: d21), Hold(eventId: "reddy-haldi", qty: 150, date: d29), Hold(eventId: "sharma-reception", qty: 500, date: d5),
                Hold(eventId: "ahmed-nikah", qty: 350, date: d12), Hold(eventId: "reddy-reception", qty: 300, date: d19)]),
            InventoryItem(id: "parcans", name: "Par cans", total: 48, detail: "LED · RGBW", holds: [
                Hold(eventId: K, qty: 24, date: d14), Hold(eventId: G, qty: 16, date: d14), Hold(eventId: "fernandes-reception", qty: 40, date: d21)]),
            InventoryItem(id: "risers", name: "Stage risers", total: 24, detail: "4 × 8 ft · 2 ft high", holds: [
                Hold(eventId: K, qty: 12, date: d14), Hold(eventId: G, qty: 6, date: d14), Hold(eventId: "fernandes-reception", qty: 20, date: d21)]),
        ]
        let tasks: [(String, String, String, String, String, Bool)] = [
            ("Setup", "09:00–14:00", "Unload and set stage risers", "Suresh's team · 6 crew", "1 h 30", true),
            ("Setup", "09:00–14:00", "Rig par cans on truss", "Deepak, Arjun", "2 h", true),
            ("Setup", "09:00–14:00", "Hang 120 drape panels", "Manoj's team · 4 crew", "3 h", false),
            ("Dressing", "14:00–17:00", "Floral mandap and entrance", "Kavita · 3 crew", "2 h 30", false),
            ("Dressing", "14:00–17:00", "Lay 45 round tables", "Ramesh, Sunil, Vikram", "1 h", false),
            ("Event", "17:00–23:30", "Lights and sound check", "Deepak · 30 min", "before 16:30", false),
            ("Event", "17:00–23:30", "Welcome florals at guest arrival", "Kavita · 2 crew", "17:00", false),
            ("Event", "17:00–23:30", "Pack-down and load trucks", "All crew", "from 23:30", false),
        ]
        v.tasks = tasks.enumerated().map { i, t in RunsheetTask(id: "t\(i + 1)", eventId: K, block: t.0, blockTime: t.1, title: t.2, crew: t.3, duration: t.4, done: t.5, order: i) }
        v.expenses = [
            Expense(id: "e1", eventId: G, name: "Agency crew · conflict cover", detail: "8 crew from Shakti Events · 2 days", amount: 38_400),
            Expense(id: "e2", eventId: G, name: "Flowers", detail: "Marigold, roses, foliage · Ghazipur mandi", amount: 42_000),
            Expense(id: "e3", eventId: G, name: "Lighting and truss hire", detail: "4 m truss · 24 par cans", amount: 35_000),
            Expense(id: "e4", eventId: G, name: "Fabric and drapes", detail: "Cleaning and 40 new panels", amount: 28_000),
            Expense(id: "e5", eventId: G, name: "Venue surcharge", detail: "Sky Banquets · outside vendor fee", amount: 52_000),
            Expense(id: "e6", eventId: G, name: "Transport", detail: "2 trucks · Chattarpur to Sector 29", amount: 12_500),
        ]
        v.packages = defaultPackages()
        v.changeRequests = [
            ChangeRequest(id: "cr1", eventId: K, summary: "Add 200 guests. 450 becomes 650.", guestsDelta: 200, impacts: [
                ChangeImpact(resource: "Chiavari chairs", detail: "380 → 500 of 600 held on \(Fmt.dayMonth.string(from: d14))", delta: "+120", isShort: false, icon: "inventory"),
                ChangeImpact(resource: "Round tables", detail: "All 60 held · hire 20 more", delta: "+20 · ₹8,000", isShort: true, icon: "inventory"),
                ChangeImpact(resource: "Helpers", detail: "Ramesh, Sunil, Anil, Ravi", delta: "+4 · ₹3,200", isShort: false, icon: "people"),
                ChangeImpact(resource: "Transport", detail: "Second truck, chairs and tables", delta: "₹4,500", isShort: false, icon: "transport"),
            ], addedCost: 15_700, revisedQuote: 710_000, perGuest: 350, status: .pending, requestedAt: Cal.calendar.date(bySettingHour: 8, minute: 12, second: 0, of: now) ?? now, via: "WhatsApp"),
        ]
        v.enquiries = [
            Enquiry(id: "q1", name: "Anjali Kapoor", phone: "98110 77120", source: "Referral · Vikram Kapoor", budget: "₹3,00,000 – ₹5,00,000", date: d5, guests: 250,
                    notes: "Sister's engagement. Pastel florals, saw the Fernandes reel. Wants a quote by Friday.", status: .open, createdAt: now),
            Enquiry(id: "q2", name: "Neha Bhatia", phone: "98200 41100", source: "Instagram", budget: "₹1,50,000 – ₹3,00,000", date: d(2027, 1, 16), guests: 150, notes: "Haldi at home, Chattarpur.", status: .open, createdAt: now),
            Enquiry(id: "q3", name: "Rohan Kapadia", phone: "98330 20011", source: "Wedding planner", budget: "Over ₹10,00,000", date: d(2027, 1, 30), guests: 700, notes: "Destination-style reception, two stages.", status: .open, createdAt: now),
        ]
        return v
    }

    static func defaultPackages() -> [Package] {
        [
            Package(id: "stage", name: "Stage & backdrop", detail: "12 m truss, 40 par cans", price: 180_000),
            Package(id: "mandap", name: "Floral mandap", detail: "fresh marigold and jasmine", price: 95_000),
            Package(id: "drapes", name: "Drapes & ceiling", detail: "160 panels", price: 130_000),
            Package(id: "arch", name: "Entrance arch", detail: "4 m floral arch", price: 40_000),
            Package(id: "lighting", name: "Lighting & sound", detail: "par cans, moving heads, PA", price: 75_000),
            Package(id: "seating", name: "Seating & tables", detail: "chiavari chairs, round tables, linen", price: 60_000),
        ]
    }

    static let enquirySources = ["Referral", "Instagram", "WhatsApp", "Wedding planner", "Walk-in", "Website"]
    static let budgetRanges = ["Under ₹1,50,000", "₹1,50,000 – ₹3,00,000", "₹3,00,000 – ₹5,00,000", "₹5,00,000 – ₹10,00,000", "Over ₹10,00,000"]
}
