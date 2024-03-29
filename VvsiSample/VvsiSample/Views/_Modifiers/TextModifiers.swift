//  Copyright © 2024 Rob Vander Sloot
//

import SwiftUI

/// View modifier for standard application text.
struct AppText: ViewModifier {
    let font: Font
    let color: Color

    init(font: Font, color: Color = .appText) {
        self.font = font
        self.color = color
    }

    func body(content: Content) -> some View {
        content
            .font(font)
            .foregroundStyle(color)
    }
}

/// View extensions for shortcuts to the application text view modifier.
extension Text {
    func appTitle1() -> some View { modifier(AppText(font: .appTitle1)) }
    func appTitle2() -> some View { modifier(AppText(font: .appTitle2)) }
    func appTitle3() -> some View { modifier(AppText(font: .appTitle3)) }
    func appBodyText() -> some View { modifier(AppText(font: .appBody)) }
    func appBodyTextSmall() -> some View { modifier(AppText(font: .appBodySmall)) }
    func appBodyTextExtraSmall() -> some View { modifier(AppText(font: .appBodyExtraSmall)) }
    func appTextError() -> some View { modifier(AppText(font: .appBodySmall, color: .appTextError)) }
}
