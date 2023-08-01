// The AuthView is a SwiftUI-based view responsible for managing user authentication in an iOS app. It interacts with the AuthViewModel to
// handle sign-in and sign-up processes, displaying appropriate UI elements based on the current authentication step. The view utilizes
// custom text fields, buttons, and modifiers to ensure a smooth user experience, including loading indicators, toasts, and disconnection
// alerts. By combining SwiftUI's declarative approach and the AuthViewModel, the view provides an intuitive and responsive interface for
// seamless user authentication.

import SwiftUI

struct AuthView: View {
    @State private var isSecurePassword: Bool = false
    @StateObject var viewModel: AuthViewModel
    @Binding var isPresented: Bool

    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: MagicNumber.x2) {
                AuthLogoView()
                    .padding(.bottom, isPasswordStep ? 0 : MagicNumber.x)
                if isPasswordStep {
                    EmailTipView(action: viewModel.goBack, email: viewModel.data.email)
                        .padding(.bottom, MagicNumber.x)
                }
                switch viewModel.step {
                case .email:
                    SkladTextField(
                        title: .email,
                        proxy: .proxyEmail,
                        value: Binding<String>(
                            get: { viewModel.data.email },
                            set: { viewModel.data.email = $0.lowercased() }
                        ),
                        error: $viewModel.emailError
                    )
                case .password, .createPassword:
                    // TODO: Should add hint for creating password, but iOS 16 includes bug with Menu and keyboard safe area
                    SkladTextField(
                        title: passwordTitle,
                        proxy: .proxyPassword,
                        value: $viewModel.data.password,
                        error: $viewModel.passwordError,
                        activeButton: {
                            textfieldPasswordButton
                        },
                        type: isSecurePassword ? .default : .secure
                    )
                }
                Text(
                    Localization.privacy(
                        termsURL: AuthConstants.termsURL,
                        privacyURL: AuthConstants.privacyURL
                    ).markdown
                )
                .modifier(FontBody(size: MagicNumber.x * 1.5, color: .doubleLightGray))
                .multilineTextAlignment(.leading)
                .tint(.doubleLightGray)
            }
            .padding(.vertical, MagicNumber.x3)
            .padding(.horizontal, MagicNumber.x4)
            StickyButtonView(
                action: viewModel.continue,
                title: titleButton.value,
                icon: iconButton,
                isDisabled: viewModel.data.email.isEmpty
            )
        }
        .isLoading(viewModel.isLoading)
        .onChange(of: viewModel.shouldDismiss) { value in
            guard value else { return }
            isPresented = !value
        }
        .toaster(toast: $viewModel.toast, isFit: true)
        .disconnectAlert(isPresented: $viewModel.connectionError, retry: viewModel.continue)
    }
}

// MARK: - Extra properties

extension AuthView {
    var titleButton: Localization {
        switch viewModel.step {
        case .email:
            return viewModel.data.email.isEmpty ? .signIn : .continue
        case .password:
            return .signIn
        case .createPassword:
            return .signUp
        }
    }

    var iconButton: IconName? {
        viewModel.data.email.isEmpty ? nil : .arrow_right_circle_fill
    }

    var isPasswordStep: Bool {
        viewModel.step == .password || viewModel.step == .createPassword
    }

    var passwordTitle: Localization {
        viewModel.step == .password ? .password : .createPassword
    }

    var passwordHints: [FormHint] {
        viewModel.step == .createPassword ? [.limitation(text: .hintPassword)] : []
    }

    @ViewBuilder var textfieldPasswordButton: some View {
        Button(action: {
            isSecurePassword.toggle()
        }) {
            IconView(
                name: isSecurePassword ? .eye : .eyeSlash,
                fontSize: MagicNumber.x2,
                color: .doubleLightGray
            )
        }
    }
}
