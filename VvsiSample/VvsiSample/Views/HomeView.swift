//  Copyright © 2023 Rob Vander Sloot
//

import SwiftUI

struct HomeView: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header()

            Divider()

            randomJoke()

            Divider()

            Spacer()
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

    func randomJoke() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Random Joke")
                    .appTitle2()

                Spacer()

                Image(systemName: "arrow.clockwise")
                    .foregroundStyle(.appTextLink)
                    .padding(4)
                    .onTapGesture {

                    }
            }

            Text("Chuck Norris can kill you with a headshot using a shotgun from across the map on call of duty.")
                .appBodyText()
                .italic()
                .padding(.horizontal, 16)
        }
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
