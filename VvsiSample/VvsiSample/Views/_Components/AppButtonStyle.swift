//  Copyright © 2023 Rob Vander Sloot
//

import SwiftUI

struct AppButtonStyle {

    // MARK: - Primary Button Style

    struct Primary: ButtonStyle {
        @Environment(\.isEnabled) var isEnabled

        func makeBody(configuration: Configuration) -> some View {
            return configuration.label
                .font(.appButtonPrimary)
                .foregroundStyle(isEnabled ? .appButtonPrimaryOnSurface : .appOnSurfaceDisabled)
                .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .background(isEnabled ? .appButtonPrimarySurface : .appSurfaceDisabled)
                .cornerRadius(8)
        }
    }
}


// MARK: - Previews

#Preview("Light") {
    ButtonPreview()
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    ButtonPreview()
    .preferredColorScheme(.dark)
}

fileprivate struct ButtonPreview: View {
    var body: some View {
        VStack(spacing: 16) {
            Button(action: {
            }, label: {
                Label("Button", systemImage: "arrowshape.right.circle")
            })
            .buttonStyle(AppButtonStyle.Primary())

            // disabled
            Button(action: {
            }, label: {
                Label("Button", systemImage: "arrowshape.right.circle")
            })
            .buttonStyle(AppButtonStyle.Primary())
            .disabled(true)
        }
    }
}
