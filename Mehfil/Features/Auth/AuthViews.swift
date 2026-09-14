import SwiftUI
import AuthenticationServices

/// Welcome — the only screen a signed-out user sees. Apple first (App Store guideline 4.8), then Google.
struct WelcomeView: View {
    @Environment(AuthService.self) private var auth
    @Environment(\.colorScheme) private var scheme
    @State private var busy = false
    @State private var error: String?

    var body: some View {
        ZStack {
            MColor.ground.ignoresSafeArea()
            VStack(alignment: .leading, spacing: Space.xl) {
                Spacer()
                Text("M").type(.displayHero).foregroundStyle(MColor.emphasisText)
                    .frame(width: 64, height: 64).background(MColor.emphasisBg, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
                VStack(alignment: .leading, spacing: Space.sm) {
                    Text("Mehfil").type(.displayHero).foregroundStyle(MColor.text)
                    Text("Run the wedding season without the spreadsheet.").type(.headingMd).foregroundStyle(MColor.text)
                    Text("Every date, every rupee outstanding, every double-booking — before it becomes a problem.").type(.bodyMd).foregroundStyle(MColor.textMute)
                }
                VStack(alignment: .leading, spacing: Space.md) {
                    point("calendar", "The calendar is the spine")
                    point("indianrupeesign", "Outstanding money on the home screen")
                    point("exclamationmark.triangle", "Conflicts surface early, unprompted")
                }
                Spacer()
                VStack(spacing: Space.sm) {
                    if auth.isCloud {
                        SignInWithAppleButton(.continue) { _ in } onCompletion: { _ in }
                            .signInWithAppleButtonStyle(scheme == .dark ? .white : .black)
                            .frame(height: Dim.button).clipShape(Capsule()).allowsHitTesting(false)
                            .overlay(Button { run { try await auth.signInWithApple() } } label: { Color.clear }.buttonStyle(.plain))
                        Button { run { try await auth.signInWithGoogle() } } label: {
                            HStack(spacing: Space.sm) {
                                GoogleMark().frame(width: 18, height: 18)
                                Text("Continue with Google").type(.buttonMd)
                            }
                            .foregroundStyle(MColor.text).frame(maxWidth: .infinity).frame(height: Dim.button)
                            .background(MColor.surface, in: Capsule()).overlay(Capsule().strokeBorder(MColor.lineInput, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    } else {
                        MButton(title: "Continue on this device", icon: "iphone") { auth.continueOnDevice() }
                        Text("This build has no cloud configuration, so your data stays on this device. See backend/README.md to enable Apple and Google sign-in.")
                            .type(.caption).foregroundStyle(MColor.textMute).multilineTextAlignment(.center)
                    }
                    if let error { Text(error).type(.caption).foregroundStyle(MColor.danger).multilineTextAlignment(.center) }
                    Text("By continuing you agree to the [Terms](https://github.com/Sanu5/mehfil-ios/blob/main/TERMS.md) and [Privacy Policy](https://github.com/Sanu5/mehfil-ios/blob/main/PRIVACY.md).")
                        .type(.caption).foregroundStyle(MColor.textMute).tint(MColor.accentText).multilineTextAlignment(.center).padding(.top, Space.xs)
                }
            }
            .padding(.horizontal, Space.xl).padding(.bottom, Space.lg)
            if busy { MColor.scrim.ignoresSafeArea(); ProgressView().tint(.white) }
        }
    }

    private func point(_ symbol: String, _ text: String) -> some View {
        HStack(spacing: Space.md) {
            Image(systemName: symbol).font(.system(size: 16, weight: .light)).foregroundStyle(MColor.accentText).frame(width: Dim.icon)
            Text(text).type(.bodyMd).foregroundStyle(MColor.text)
        }
    }
    private func run(_ work: @escaping () async throws -> Void) {
        error = nil; busy = true
        Task {
            do { try await work() } catch AuthError.cancelled { } catch { self.error = error.localizedDescription }
            busy = false
        }
    }
}

/// The four-colour G, drawn so no asset is needed.
struct GoogleMark: View {
    var body: some View {
        ZStack {
            Circle().trim(from: 0.05, to: 0.30).stroke(Color(red: 0.98, green: 0.74, blue: 0.02), lineWidth: 4)
            Circle().trim(from: 0.30, to: 0.55).stroke(Color(red: 0.20, green: 0.66, blue: 0.33), lineWidth: 4)
            Circle().trim(from: 0.55, to: 0.80).stroke(Color(red: 0.26, green: 0.52, blue: 0.96), lineWidth: 4)
            Circle().trim(from: 0.80, to: 0.95).stroke(Color(red: 0.92, green: 0.26, blue: 0.21), lineWidth: 4)
            Rectangle().fill(Color(red: 0.26, green: 0.52, blue: 0.96)).frame(width: 8, height: 4).offset(x: 4)
        }
        .rotationEffect(.degrees(-90))
    }
}

/// Onboarding — the business card the rest of the app is signed with.
struct OnboardingView: View {
    @Environment(AuthService.self) private var auth
    @Environment(AppStore.self) private var store
    var account: Account
    @State private var owner = ""
    @State private var business = ""
    @State private var phone = ""
    @State private var area = ""
    @State private var loadSample = true
    @State private var saving = false

    var body: some View {
        NavigationStack {
            ScreenScaffold(title: "Set up your business", subtitle: "Signed in with \(account.providerLabel)" + (account.email.map { " · \($0)" } ?? ""), spacing: Space.lg, bottomPadding: 120) {
                InputField(label: "Your name", text: $owner, placeholder: "Anand Mehra")
                InputField(label: "Business name", text: $business, placeholder: "Mehfil Decor")
                InputField(label: "Phone", text: $phone, placeholder: "98110 08123", keyboard: .phonePad)
                InputField(label: "Area", text: $area, placeholder: "Sector 44, Gurugram")
                Toggle(isOn: $loadSample) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Start with a sample season").type(.bodyMdStrong).foregroundStyle(MColor.text)
                        Text("Twelve events, crew, inventory and payments to explore. You can erase it later from Profile.").type(.caption).foregroundStyle(MColor.textMute)
                    }
                }
                .tint(MColor.accent).padding(.top, Space.sm)
            }
            .dockedActions {
                MButton(title: "Open Mehfil", loading: saving) {
                    saving = true
                    Task {
                        await store.completeOnboarding(profile: .new(owner: owner.trimmingCharacters(in: .whitespaces), business: business.trimmingCharacters(in: .whitespaces), phone: phone, area: area), loadSample: loadSample)
                        saving = false
                    }
                }
                .disabled(owner.trimmingCharacters(in: .whitespaces).isEmpty || business.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Sign out") { try? auth.signOut() }.type(.buttonSm) } }
            .onAppear { if owner.isEmpty, let n = account.name { owner = n } }
        }
    }
}

/// Account — who is signed in, sign out, erase data, delete the account (App Store guideline 5.1.1(v)).
struct AccountView: View {
    @Environment(AuthService.self) private var auth
    @Environment(AppStore.self) private var store
    @State private var confirmErase = false
    @State private var confirmDelete = false
    @State private var busy = false
    @State private var error: String?

    var body: some View {
        let account = auth.account
        ScreenScaffold(title: "Account", subtitle: account.map { "\($0.providerLabel)" + ($0.email.map { " · \($0)" } ?? "") }, spacing: Space.lg) {
            RowGroup {
                ListRow(title: account?.name ?? store.vendor?.ownerName ?? "You", subtitle: account?.email ?? (auth.isCloud ? "Signed in" : "On this device only")) {
                    IconTile(symbol: "person")
                } trailing: { EmptyView() }
                Hairline(inset: 68)
                ListRow(title: "Storage", subtitle: auth.isCloud ? "Synced to your Mehfil cloud account" : "This device — not backed up") {
                    IconTile(symbol: auth.isCloud ? "icloud" : "iphone")
                } trailing: { EmptyView() }
            }
            RowGroup {
                Button { Task { await store.loadSampleSeason() } } label: {
                    ListRow(title: "Load the sample season", subtitle: "Adds the demo events, crew and payments") { IconTile(symbol: "sparkles") } trailing: { Chevron() }
                }.buttonStyle(.plain)
                Hairline(inset: 68)
                Button { confirmErase = true } label: {
                    ListRow(title: "Erase all data", subtitle: "Events, clients, crew, inventory and payments") { IconTile(symbol: "trash", color: MColor.danger) } trailing: { Chevron() }
                }.buttonStyle(.plain)
            }
            VStack(spacing: Space.sm) {
                MButton(title: "Sign out", style: .secondary) { try? auth.signOut() }
                MButton(title: "Delete account", style: .destructive) { confirmDelete = true }
                if let error { Text(error).type(.caption).foregroundStyle(MColor.danger).multilineTextAlignment(.center) }
            }
            .padding(.top, Space.md)
            Text("Deleting removes your account and every event, client, crew member and payment record. It cannot be undone.")
                .type(.caption).foregroundStyle(MColor.textMute)
            HStack(spacing: Space.lg) {
                Link("Privacy Policy", destination: URL(string: "https://github.com/Sanu5/mehfil-ios/blob/main/PRIVACY.md")!)
                Link("Terms", destination: URL(string: "https://github.com/Sanu5/mehfil-ios/blob/main/TERMS.md")!)
            }
            .type(.caption).tint(MColor.accentText)
        }
        .overlay { if busy { ZStack { MColor.scrim.ignoresSafeArea(); ProgressView().tint(.white) } } }
        .sheet(isPresented: $confirmErase) {
            SheetScaffold(title: "Erase everything in \(store.vendor?.businessName ?? "Mehfil")?", subtitle: "Every event, client, crew member, item and payment record goes. Your account and profile stay.") { EmptyView() } actions: {
                VStack(spacing: Space.sm) {
                    MButton(title: "Erase all data", style: .destructive) { confirmErase = false; perform { try await store.eraseAllData(); store.show(.info, "All data erased") } }
                    MButton(title: "Keep it", style: .tertiary, size: .compact) { confirmErase = false }
                }
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $confirmDelete) {
            SheetScaffold(title: "Delete your Mehfil account?", subtitle: "You'll be asked to sign in again to confirm. \(store.vendor?.businessName ?? "Your business") and all its records are deleted permanently.") { EmptyView() } actions: {
                VStack(spacing: Space.sm) {
                    MButton(title: "Delete account and data", style: .destructive) {
                        confirmDelete = false
                        perform {
                            try await store.eraseAllData()
                            try await auth.deleteAccount()
                        }
                    }
                    MButton(title: "Keep my account", style: .tertiary, size: .compact) { confirmDelete = false }
                }
            }
            .presentationDetents([.medium])
        }
    }

    private func perform(_ work: @escaping () async throws -> Void) {
        error = nil; busy = true
        Task { do { try await work() } catch AuthError.cancelled { } catch { self.error = error.localizedDescription }; busy = false }
    }
}
