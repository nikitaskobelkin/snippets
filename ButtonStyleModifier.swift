// The PrimaryButton is a custom SwiftUI button style that provides a consistent visual representation for primary buttons. It conforms to
// the ButtonStyle protocol. The style allows customization of the button's minimum width, maximum width, and vertical padding. It's like
// wrapper as reusable component in implementation.

import SwiftUI

// MARK: - Primary Button Style

struct PrimaryButton: ButtonStyle {
    var minWidth: CGFloat?
    var maxWidth: CGFloat?
    var verticalPadding: CGFloat = MagicNumber.x3

    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .font(.system(size: MagicNumber.x2, weight: .bold))
            .frame(minWidth: minWidth ?? .none, maxWidth: maxWidth ?? .none)
            .padding(.vertical, verticalPadding)
            .padding(.horizontal, MagicNumber.x5)
            .foregroundColor(.white)
            .background(Color.indigo)
            .cornerRadius(MagicNumber.x2)
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(), value: configuration.isPressed)
            .haptical(.medium, value: configuration)
    }
}
