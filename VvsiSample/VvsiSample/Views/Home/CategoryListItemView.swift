//  Copyright © 2023 Rob Vander Sloot
//

import SwiftUI

struct CategoryListItemView: View {

    let categoryName: String

    var body: some View {
        VStack {
            HStack(alignment: .center) {
                Text(categoryName.capitalized)
                    .appBodyText().bold()

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.appTextLink)
            }

            Divider()
                .frame(height: 1)
                .overlay(.appBorder)
        }
        .padding(.top, 8)
    }
}


// MARK: - Previews

#Preview("Light") {
    VStack(spacing: 0) {
        CategoryListItemView(categoryName: "Category Name")
        CategoryListItemView(categoryName: "Category Name")
        CategoryListItemView(categoryName: "Category Name")
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    VStack(spacing: 0) {
        CategoryListItemView(categoryName: "Category Name")
        CategoryListItemView(categoryName: "Category Name")
        CategoryListItemView(categoryName: "Category Name")
    }
    .preferredColorScheme(.dark)
}
