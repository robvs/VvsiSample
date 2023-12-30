//  Copyright © 2024 Rob Vander Sloot
//

import SwiftUI

/// View modifier for standard application text.
struct AppText: ViewModifier {
    let font: Font

    func body(content: Content) -> some View {
        content
            .font(font)
            .foregroundStyle(.appText)
    }
}

/// View extensions for shortcuts to the application text view modifier.
extension View {
    func appTitle1() -> some View { modifier(AppText(font: .appTitle1)) }
    func appTitle2() -> some View { modifier(AppText(font: .appTitle2)) }
    func appTitle3() -> some View { modifier(AppText(font: .appTitle3)) }
    func appBodyText() -> some View { modifier(AppText(font: .appBody)) }
    func appBodyTextSmall() -> some View { modifier(AppText(font: .appBodySmall)) }
    func appBodyTextExtraSmall() -> some View { modifier(AppText(font: .appBodyExtraSmall)) }
}
