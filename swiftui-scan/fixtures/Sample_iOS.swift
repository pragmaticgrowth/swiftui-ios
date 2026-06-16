import SwiftUI
import UIKit

struct FeedView: View {
    @State private var selection: Tab = .home
    var body: some View {
        TabView(selection: $selection) {
            List { Text("row") }
                .refreshable { }
                .tabItem { Label("Home", systemImage: "house") }
        }
        .sheet(isPresented: .constant(false)) { Text("sheet") }
        .presentationDetents([.medium, .large])
    }
}

struct MapBox: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView { UIView() }
    func updateUIView(_ v: UIView, context: Context) {}
}

struct PlayerVC: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController { UIViewController() }
    func updateUIViewController(_ c: UIViewController, context: Context) {}
}
