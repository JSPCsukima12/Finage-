import SwiftUI

struct LaunchView: View {
    var body: some View {
        VStack {
            Spacer()
            VStack {
                Image("Logo")
                    .resizable()
                    .frame(width:200,height:200)
                Text("Finage+")
                    .bold()
                    .font(.title)
                    .foregroundStyle(.green)
            }
            Spacer()
            VStack(spacing:2) {
                Text("Created")
                Text("By")
                Text("Sho")
            }
            .font(.title2)
            .foregroundStyle(.gray)
        }
    }
}
