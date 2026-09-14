import Foundation
import SwiftUI
import Observation
import AuthenticationServices
import CryptoKit
import FirebaseCore
import FirebaseAuth
import GoogleSignIn

struct Account: Equatable {
    var uid: String
    var name: String?
    var email: String?
    var phone: String?          // E.164, present once a number has been verified with an OTP
    var provider: String        // "apple.com" | "google.com" | "phone" | "device"
    var providerLabel: String { switch provider { case "apple.com": "Apple"; case "google.com": "Google"; case "phone": "Phone"; default: "This device" } }
}

enum AuthError: LocalizedError {
    case cancelled, noToken, noPresenter, notConfigured, appleUnavailable, noCodeSent, notSignedIn
    var errorDescription: String? {
        switch self {
        case .noCodeSent: "Send a code first."
        case .notSignedIn: "You're not signed in."
        case .cancelled: "Sign-in was cancelled."
        case .appleUnavailable: "Sign in with Apple isn't available here. Sign in to an Apple Account in Settings first, then try again."
        case .noToken: "The sign-in provider did not return a token."
        case .noPresenter: "Nothing to present the sign-in from."
        case .notConfigured: "Cloud sign-in is not configured in this build."
        }
    }
}

/// Firebase Auth when the build has a config; otherwise a single on-device account so the app still works.
@Observable
final class AuthService {
    enum State: Equatable { case loading, signedOut, signedIn(Account) }
    private(set) var state: State = .loading
    let isCloud: Bool
    private var listener: AuthStateDidChangeListenerHandle?
    private var currentNonce: String?
    private var appleCoordinator: AppleSignInCoordinator?
    private static let localKey = "localAccountActive"

    init() {
        isCloud = Backend.isConfigured
        if isCloud {
            if let clientID = FirebaseApp.app()?.options.clientID { GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID) }
            #if targetEnvironment(simulator)
            // The simulator has no APNs: let the fictional test numbers from the Firebase console work without app verification.
            Auth.auth().settings?.isAppVerificationDisabledForTesting = true
            #endif
            listener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
                self?.state = user.map { .signedIn(Self.account(from: $0)) } ?? .signedOut
            }
        } else {
            state = UserDefaults.standard.bool(forKey: Self.localKey) ? .signedIn(Self.localAccount) : .signedOut
        }
    }

    var account: Account? { if case .signedIn(let a) = state { return a }; return nil }
    static let localAccount = Account(uid: "local-device", name: nil, email: nil, phone: nil, provider: "device")

    private static func account(from user: User) -> Account {
        Account(uid: user.uid, name: user.displayName, email: user.email, phone: user.phoneNumber,
                provider: user.providerData.first(where: { $0.providerID != "firebase" })?.providerID ?? "firebase")
    }

    // MARK: Device-only account (no Firebase config)

    func continueOnDevice() {
        UserDefaults.standard.set(true, forKey: Self.localKey)
        state = .signedIn(Self.localAccount)
    }

    // MARK: Sign in with Apple

    @MainActor
    func signInWithApple() async throws {
        guard isCloud else { throw AuthError.notConfigured }
        let nonce = Self.randomNonce()
        currentNonce = nonce
        let (credential, _) = try await requestApple(nonce: nonce)
        guard let tokenData = credential.identityToken, let idToken = String(data: tokenData, encoding: .utf8) else { throw AuthError.noToken }
        let firebaseCredential = OAuthProvider.appleCredential(withIDToken: idToken, rawNonce: nonce, fullName: credential.fullName)
        let result = try await Auth.auth().signIn(with: firebaseCredential)
        // Apple only sends the name on the first authorization; keep it on the Firebase user.
        if result.user.displayName == nil, let name = credential.fullName, let formatted = PersonNameComponentsFormatter().string(from: name).nilIfEmpty {
            let change = result.user.createProfileChangeRequest(); change.displayName = formatted; try? await change.commitChanges()
            state = .signedIn(Self.account(from: result.user))
        }
    }

    @MainActor
    private func requestApple(nonce: String) async throws -> (ASAuthorizationAppleIDCredential, String?) {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = Self.sha256(nonce)
        let coordinator = AppleSignInCoordinator()
        appleCoordinator = coordinator
        defer { appleCoordinator = nil }
        return try await coordinator.perform(request)
    }

    // MARK: Google

    @MainActor
    func signInWithGoogle() async throws {
        guard isCloud else { throw AuthError.notConfigured }
        guard let presenter = Self.topViewController() else { throw AuthError.noPresenter }
        let result: GIDSignInResult
        do { result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenter) }
        catch let e as NSError where e.code == GIDSignInError.canceled.rawValue { throw AuthError.cancelled }
        guard let idToken = result.user.idToken?.tokenString else { throw AuthError.noToken }
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: result.user.accessToken.tokenString)
        try await Auth.auth().signIn(with: credential)
    }

    // MARK: Phone number + OTP

    /// What a verified code should do: start a session, attach the number to the signed-in account, replace it, or prove identity.
    enum PhoneIntent { case signIn, link, update, reauth }
    private var phoneVerificationID: String?

    /// Texts a 6-digit code to an E.164 number. On a device Firebase verifies the app silently over APNs; on the
    /// simulator (no APNs) it falls back to a reCAPTCHA page, so the Google URL scheme must be registered.
    @MainActor
    func sendCode(to phone: String) async throws {
        guard isCloud else { throw AuthError.notConfigured }
        phoneVerificationID = try await PhoneAuthProvider.provider().verifyPhoneNumber(phone, uiDelegate: nil)
    }

    /// Confirms the code and applies the intent. Returns the verified number as Firebase stores it (E.164).
    @MainActor @discardableResult
    func confirmCode(_ code: String, intent: PhoneIntent) async throws -> String {
        guard let id = phoneVerificationID else { throw AuthError.noCodeSent }
        let credential = PhoneAuthProvider.provider().credential(withVerificationID: id, verificationCode: code.filter(\.isNumber))
        let user: User
        switch intent {
        case .signIn:
            user = try await Auth.auth().signIn(with: credential).user
        case .link:
            guard let u = Auth.auth().currentUser else { throw AuthError.notSignedIn }
            do { user = try await u.link(with: credential).user }
            catch let e as NSError where e.code == AuthErrorCode.providerAlreadyLinked.rawValue { try await u.updatePhoneNumber(credential); user = u }
        case .update:
            guard let u = Auth.auth().currentUser else { throw AuthError.notSignedIn }
            try await u.updatePhoneNumber(credential); user = u
        case .reauth:
            guard let u = Auth.auth().currentUser else { throw AuthError.notSignedIn }
            try await u.reauthenticate(with: credential); user = u
        }
        phoneVerificationID = nil
        state = .signedIn(Self.account(from: user))
        return user.phoneNumber ?? ""
    }

    /// Firebase's phone-auth errors in plain words.
    static func phoneMessage(for error: Error) -> String {
        let e = error as NSError
        guard e.domain == AuthErrorDomain, let code = AuthErrorCode(rawValue: e.code) else { return error.localizedDescription }
        switch code {
        case .invalidPhoneNumber, .missingPhoneNumber: return "Enter a valid mobile number with its country code."
        case .invalidVerificationCode: return "That code isn't right. Check the SMS and try again."
        case .sessionExpired: return "The code has expired — send a new one."
        case .credentialAlreadyInUse: return "This number is already linked to another Mehfil account."
        case .tooManyRequests, .quotaExceeded: return "Too many attempts from this device. Try again in a while."
        case .captchaCheckFailed, .appNotVerified: return "We couldn't confirm this app. Try again on a real device."
        case .requiresRecentLogin: return "Please sign in again before changing your number."
        default: return error.localizedDescription
        }
    }

    // MARK: Sign out / delete

    func signOut() throws {
        if isCloud {
            GIDSignIn.sharedInstance.signOut()
            try Auth.auth().signOut()
        } else {
            UserDefaults.standard.set(false, forKey: Self.localKey)
            state = .signedOut
        }
    }

    /// Deletes the Firebase user. Re-authenticates first (Firebase requires a recent sign-in) and revokes the
    /// Sign in with Apple token, as App Store Review requires. The caller deletes the vendor's data beforehand.
    @MainActor
    func deleteAccount() async throws {
        guard isCloud else { UserDefaults.standard.set(false, forKey: Self.localKey); state = .signedOut; return }
        guard let user = Auth.auth().currentUser else { return }
        let provider = user.providerData.first?.providerID ?? ""
        if provider == "apple.com" {
            let nonce = Self.randomNonce()
            let (credential, code) = try await requestApple(nonce: nonce)
            guard let tokenData = credential.identityToken, let idToken = String(data: tokenData, encoding: .utf8) else { throw AuthError.noToken }
            try await user.reauthenticate(with: OAuthProvider.appleCredential(withIDToken: idToken, rawNonce: nonce, fullName: nil))
            if let code { try? await Auth.auth().revokeToken(withAuthorizationCode: code) }
        } else if provider == "google.com" {
            guard let presenter = Self.topViewController() else { throw AuthError.noPresenter }
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenter)
            guard let idToken = result.user.idToken?.tokenString else { throw AuthError.noToken }
            try await user.reauthenticate(with: GoogleAuthProvider.credential(withIDToken: idToken, accessToken: result.user.accessToken.tokenString))
        }
        // "phone" accounts re-authenticate with an OTP (confirmCode(_:intent: .reauth)) before the caller gets here.
        try await user.delete()
        GIDSignIn.sharedInstance.signOut()
    }

    func handle(url: URL) -> Bool { isCloud ? (Auth.auth().canHandle(url) || GIDSignIn.sharedInstance.handle(url)) : false }

    // MARK: Helpers

    private static func randomNonce(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var bytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
        return String(bytes.map { charset[Int($0) % charset.count] })
    }
    private static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8)).map { String(format: "%02x", $0) }.joined()
    }
    @MainActor
    private static func topViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        guard var top = scenes.flatMap(\.windows).first(where: \.isKeyWindow)?.rootViewController else { return nil }
        while let presented = top.presentedViewController { top = presented }
        return top
    }
}

/// Bridges ASAuthorizationController's delegate to async/await.
final class AppleSignInCoordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private var continuation: CheckedContinuation<(ASAuthorizationAppleIDCredential, String?), Error>?

    @MainActor
    func perform(_ request: ASAuthorizationAppleIDRequest) async throws -> (ASAuthorizationAppleIDCredential, String?) {
        try await withCheckedThrowingContinuation { cont in
            continuation = cont
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { continuation?.resume(throwing: AuthError.noToken); return }
        let code = credential.authorizationCode.flatMap { String(data: $0, encoding: .utf8) }
        continuation?.resume(returning: (credential, code)); continuation = nil
    }
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        if let e = error as? ASAuthorizationError {
            switch e.code {
            case .canceled: continuation?.resume(throwing: AuthError.cancelled)
            // 1000: no Apple Account on this device/simulator, or the app was built without the Sign in with Apple entitlement.
            case .unknown: continuation?.resume(throwing: AuthError.appleUnavailable)
            default: continuation?.resume(throwing: error)
            }
        } else { continuation?.resume(throwing: error) }
        continuation = nil
    }
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.flatMap(\.windows).first(where: \.isKeyWindow) ?? ASPresentationAnchor()
    }
}

extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
