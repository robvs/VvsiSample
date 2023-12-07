//  Copyright © 2023 Rob Vander Sloot
//

import SwiftUI

struct HomeView: View {

    var body: some View {
        VStack(alignment: .leading) {
            header()
        }
        .padding(.horizontal)
    }
}


// MARK: - Subviews

private extension HomeView {

    func header() -> some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading) {
                Text("Chuck Norris Jokes")
                    .appTitle1()

                Spacer()

                HStack {
                    Spacer()
                    Text("Powered by")
                        .appBodyTextSmall()
                }
            }

            Image("chucknorris_logo")
                .scale(height: 50)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}


// MARK: - Previews

#Preview("Light") {
    HomeView()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    HomeView()
        .preferredColorScheme(.dark)
}
