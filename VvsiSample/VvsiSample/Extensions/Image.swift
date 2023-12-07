//  Copyright © 2023 Rob Vander Sloot
//

import SwiftUI

extension Image {

    func scale(size: CGSize) -> some View {
        self
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size.width, height: size.height)
    }

    func scale(height: CGFloat) -> some View {
        self
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: height)
    }

    func scale(width: CGFloat) -> some View {
        self
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: width)
    }
}
