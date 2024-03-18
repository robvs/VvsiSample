//  Copyright © 2024 Rob Vander Sloot
//

import SwiftUI

extension Image {


    /// Resize the image to fit within the given dimensions while maintaining its original aspect ratio.
    /// - Parameter size: The maximum dimensions of the resized image.
    /// - Returns: The resized image.
    func scale(size: CGSize) -> some View {
        self
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size.width, height: size.height)
    }


    /// Resize the image to fit within the given height while maintaining its original aspect ratio.
    /// - Parameter height: The resized image height.
    /// - Returns: The resized image.
    func scale(height: CGFloat) -> some View {
        self
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: height)
    }


    /// Resize the image to fit within the given height while maintaining its original aspect ratio.
    /// - Parameter width: The resized image width.
    /// - Returns: The resized image.
    func scale(width: CGFloat) -> some View {
        self
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: width)
    }
}
