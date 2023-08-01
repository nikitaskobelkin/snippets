// The AuthViewModel is a SwiftUI-based authentication view model that manages user authentication flow using Combine's ObservableObject
// and @Published properties for seamless data observation. It handles sign-in, sign-up, and email verification processes using async/await
// concurrency. The view model communicates with AccountManagerProtocol and InteractionManagerProtocol, abstracting authentication logic
// and user interaction. With SwiftUI's animation support and input validation, it ensures a reactive and smooth user experience during
// authentication.

import SwiftUI

final class AuthViewModel: ObservableObject {
    @Published private(set) var step: AuthStep
    @Published private(set) var isLoading: Bool
    @Published private(set) var shouldDismiss: Bool
    @Published var data: AuthFormModel
    @Published var toast: ToastDataModel? // object for showing in Toaster system custom notifications
    @Published var emailError: Bool
    @Published var passwordError: Bool
    @Published var showEmailConfirmation: Bool
    @Published var connectionError: Bool

    private let accountManager: AccountManagerProtocol
    private let interactionManager: InteractionManagerProtocol

    init(
        accountManager: AccountManagerProtocol,
        interactionManager: InteractionManagerProtocol
    ) {
        data = AuthFormModel()
        emailError = false
        passwordError = false
        showEmailConfirmation = false
        connectionError = false
        step = .first // it's extension property, not case
        isLoading = false
        shouldDismiss = false
        self.accountManager = accountManager
        self.interactionManager = interactionManager
    }

    func `continue`() {
        switch step {
        case .email:
            guard data.email.isEmail else {
                emailError = true
                interactionManager.toInteract(.error)
                return
            }
            handleNextStep()
        case .password:
            guard !data.password.isEmpty else {
                passwordError = true
                interactionManager.toInteract(.error)
                return
            }
            signIn()
        case .createPassword:
            guard !data.password.isEmpty && data.password.count >= AuthConstants.minPasswordSize else {
                passwordError = true
                interactionManager.toInteract(.error)
                toast = ToastDataModel(title: .createPassword, subTitle: .hintPassword, type: .error)
                return
            }
            signUp()
        }
    }

    func goBack() {
        passwordError = false
        data.password = ""
        withAnimation {
            step = AuthStep.first
        }
    }

    func verifyEmail() {
        isLoading = true
        Task { @MainActor in
            defer { isLoading = false }
            if let error = await accountManager.verify() {
                handleAndShowError(error: error)
                return
            }
            interactionManager.toInteract(.soft)
            toast = ToastDataModel(title: .success, subTitle: .emailVerificationToastText, type: .success)
        }
    }

    private func handleNextStep() {
        isLoading = true
        Task { @MainActor in
            defer { isLoading = false }
            let response = await accountManager.isExistedAccount(email: data.email)
            switch response {
            case let .success(isExisted):
                withAnimation {
                    step = isExisted ? .password : .createPassword
                }
            case let .failure(error):
                handleAndShowError(error: error)
            }
        }
    }

    private func signIn() {
        isLoading = true
        Task { @MainActor in
            defer { isLoading = false }
            if let error = await accountManager.auth(email: data.email.lowercased(), password: data.password) {
                handleAndShowError(error: error)
                return
            }
            interactionManager.toInteract(.soft)
            guard let emailIsVerified = accountManager.emailIsVerified else {
                withAnimation {
                    step = .first
                }
                return
            }
            if !emailIsVerified {
                showEmailConfirmation = true
                return
            }
            shouldDismiss = true
        }
    }

    private func signUp() {
        isLoading = true
        Task { @MainActor in
            defer { isLoading = false }
            if let error = await accountManager.createAccount(email: data.email, password: data.password) {
                handleAndShowError(error: error)
                return
            }
            if let error = await accountManager.verify() {
                handleAndShowError(error: error)
                return
            }
            showEmailConfirmation = true
        }
    }

    @MainActor
    private func handleAndShowError(error: AccountError) {
        interactionManager.toInteract(.error)
        switch error {
        case .noConnection:
            connectionError = true
        default:
            toast = ToastDataModel(title: .oops, subTitle: error.description, type: .error)
            guard error == .requiresRecentSignIn else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                guard let self = self else { return  }
                self.goBack()
            }
        }
    }
}
