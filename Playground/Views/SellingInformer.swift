import SwiftUI

struct SellingInformer: View {
    let title: String
    let buttonTitle: String
    let closeAction: () -> (Void)
    let targetAction: () -> (Void)
    
    @State var image: UIImage?

    var body: some View {
        ZStack {
            // START: View background
            Color(hex: 0x2B3647)
            // END
            // START: radial-gradient background
            RadialGradient(gradient: Gradient(colors: [Color(hex: 0xFE4A4F), Color(hex: 0xFE4A4F, alpha: 0)]),
                           center: .topLeading,
                           startRadius: 0,
                           endRadius: 356)
                .opacity(0.32)
            RadialGradient(gradient: Gradient(colors: [Color(hex: 0xCA10E1), Color(hex: 0xCA10E1, alpha: 0)]),
                           center: .bottomTrailing,
                           startRadius: 0,
                           endRadius: 212)
                .opacity(0.16)
            // END
            HStack {
                // START: Calendar icon on left
//                SellingInformerImageView(image: $image)
                LottieView()
                    .frame(width: 40, height: 40)
                    .padding([.horizontal], 20)
                // END
                // START: Content
                VStack(alignment: .leading) {
                    Text(title)
                        .font(Font.system(size: 15))
                        .lineLimit(2)
                        .foregroundColor(.white)
                        .padding([.bottom], 4)
                    Button(action: targetAction) {
                        Text(buttonTitle)
                            .font(Font.system(size: 15))
                            ._foregroundStyle(LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 136.0/255.0, blue: 8.0/255.0),
                                    Color(red: 1.0, green: 74.0/255.0, blue: 74.0/255.0),
                                    Color(red: 242.0/255.0, green: 71.0/255.0, blue: 112.0/255.0),
                                    Color(red: 190.0/255.0, green: 0.0/255.0, blue: 255.0/255.0)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing)
                            )
                    }
                }
                .padding([.vertical], 12)
                // END
                Spacer()
                // START: Close button on top right
                VStack {
                    Button(action: closeAction) {
                        Image("cross")
                            .frame(width: 16, height: 16)
                            .foregroundColor(.white)
                    }
                    .padding(8)
                    .contentShape(Rectangle().offset(CGSize(width: 8, height: 8)))
                    .onTapGesture { closeAction() }
                    Spacer()
                }
                // END
            }
        }
        .cornerRadius(12)
        .contentShape(Rectangle())
        .onTapGesture { targetAction() }
    }

}

struct SellingInformerImageView: UIViewRepresentable {
    @Binding var image: UIImage?

    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {
        uiView.image = image
    }
}

private extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: alpha
        )
    }
}

private extension View {
  func _foregroundStyle<Content: View>(_ content: Content) -> some View {
    self.overlay(content).mask(self)
  }
}


// MARK: - Preview

private struct ContentView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [.green, .blue]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)
            Spacer()
            SellingInformer(
                title: "We don’t keep data older than 30 days in your journal",
                buttonTitle: "Make my journal endless",
                closeAction: {},
                targetAction: {},
                image: UIImage(named: "calendar")
            )
                .frame(height: 90)
                .padding(8)
        }
    }

}

private struct ContentView1_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
