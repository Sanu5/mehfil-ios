import SwiftUI

/// Mobile number + OTP in two steps. Used to sign in, to attach a number to an Apple/Google account, to change it,
/// and to re-authenticate before deleting a phone account. Calls `onVerified` with the E.164 number.
struct PhoneVerifySheet: View {
    @Environment(AuthService.self) private var auth
    @Environment(\.dismiss) private var dismiss
    var intent: AuthService.PhoneIntent
    var initialPhone: String = ""
    var onVerified: (String) -> Void

    @State private var code = "91"
    @State private var number = ""
    @State private var otp = ""
    @State private var sentTo: String?
    @State private var busy = false
    @State private var error: String?
    @State private var resendIn = 0
    @FocusState private var focus: Field?
    private enum Field { case number, otp }

    private var title: String {
        switch intent {
        case .signIn: "Continue with your mobile number"
        case .link: "Verify your mobile number"
        case .update: "Change your mobile number"
        case .reauth: "Confirm it's you"
        }
    }
    private var e164: String? { Fmt.e164(code: code, number: number) }

    var body: some View {
        SheetScaffold(title: title, subtitle: sentTo.map { "We sent a 6-digit code by SMS to \(Fmt.phone($0))." } ?? "We'll text you a 6-digit code to confirm the number.") {
            if sentTo == nil {
                HStack(alignment: .top, spacing: Space.sm) {
                    InputField(label: "Code", text: $code, placeholder: "91", keyboard: .numberPad).frame(width: 84)
                    InputField(label: "Mobile number", text: $number, placeholder: "98110 08123", keyboard: .numberPad)
                        .focused($focus, equals: .number)
                }
            } else {
                InputField(label: "6-digit code", text: $otp, placeholder: "••••••", keyboard: .numberPad, oneTimeCode: true)
                    .focused($focus, equals: .otp)
                    .onChange(of: otp) { _, v in if v.count == 6 { verify() } }
            }
            if let error { Text(error).type(.caption).foregroundStyle(MColor.danger) }
        } actions: {
            VStack(spacing: Space.sm) {
                if sentTo == nil {
                    MButton(title: "Send code", loading: busy) { send() }.disabled(e164 == nil)
                } else {
                    MButton(title: "Verify", loading: busy) { verify() }.disabled(otp.count < 6)
                    MButton(title: resendIn > 0 ? "Resend in \(resendIn)s" : "Resend code", style: .tertiary, size: .compact) { send() }.disabled(resendIn > 0 || busy)
                    MButton(title: "Change number", style: .tertiary, size: .compact) { sentTo = nil; otp = ""; error = nil }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .onAppear {
            if !initialPhone.isEmpty, initialPhone.hasPrefix("+") {
                let digits = initialPhone.filter(\.isNumber)
                if digits.hasPrefix("91"), digits.count == 12 { code = "91"; number = String(digits.dropFirst(2)) } else { number = digits }
            }
            focus = .number
        }
        .task(id: resendIn) {
            guard resendIn > 0 else { return }
            try? await Task.sleep(for: .seconds(1))
            resendIn -= 1
        }
    }

    private func send() {
        guard let phone = e164 else { return }
        error = nil; busy = true
        Task {
            do { try await auth.sendCode(to: phone); sentTo = phone; otp = ""; resendIn = 30; focus = .otp }
            catch { self.error = AuthService.phoneMessage(for: error) }
            busy = false
        }
    }

    private func verify() {
        guard otp.count == 6, !busy else { return }
        error = nil; busy = true
        Task {
            do {
                let phone = try await auth.confirmCode(otp, intent: intent)
                busy = false
                onVerified(phone)
                dismiss()
            } catch {
                self.error = AuthService.phoneMessage(for: error); busy = false
            }
        }
    }
}

/// A read-only phone row with its verification state and the action that opens the OTP sheet.
struct PhoneRow: View {
    var phone: String
    var verified: Bool
    var action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            Text("Mobile number").type(.caption).foregroundStyle(MColor.textMute)
            Button(action: action) {
                HStack(spacing: Space.sm) {
                    Text(phone.isEmpty ? "Add and verify" : Fmt.phone(phone)).type(.bodyMd).foregroundStyle(phone.isEmpty ? MColor.textMute : MColor.text)
                    Spacer()
                    if verified {
                        Label("Verified", systemImage: "checkmark.seal.fill").type(.caption).foregroundStyle(MColor.accentText)
                        Text("Change").type(.buttonSm).foregroundStyle(MColor.accentText)
                    } else {
                        Text(phone.isEmpty ? "Verify" : "Verify now").type(.buttonSm).foregroundStyle(MColor.accentText)
                    }
                }
                .padding(.horizontal, Space.md).frame(height: Dim.input)
                .background(MColor.surface, in: RoundedRectangle(cornerRadius: Radius.sm, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: Radius.sm, style: .continuous).strokeBorder(MColor.lineInput, lineWidth: 1))
            }
            .buttonStyle(.plain)
            Text(verified ? "Clients see this number on your shared page." : "Numbers are confirmed with a one-time code before they're saved.").type(.caption).foregroundStyle(MColor.textMute)
        }
    }
}
