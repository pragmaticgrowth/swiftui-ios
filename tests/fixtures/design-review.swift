import SwiftUI

// Fixture for audit-swiftui-design-review static (dr-*) tells. Deliberately full of greppable
// design smells. The lint LOCATES these; the reviewer READS the screenshot + code and judges.
struct DesignSmellsView: View {
    @State private var email = ""

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 8) {
                Text("Welcome")
                    .font(.system(size: 22))            // dr-fontsize: hardcoded point size
                    .foregroundColor(.black)            // dr-hardcoded-color: no dark-mode variant

                TextField("Email", text: $email)        // dr-keyboardtype: no .keyboardType/.textContentType

                Button {
                    openMenu()
                } label: {
                    Image(systemName: "line.horizontal.3")  // dr-hamburger + dr-iconbtn-label
                }
            }

            // Floating action button — Android/Material primary-action pattern
            Button(action: add) {
                Image(systemName: "plus")               // dr-iconbtn-label: icon-only, no label
            }
            .frame(width: 56, height: 56)
            .background(Circle().fill(.blue))           // dr-fab: floating circular shadowed button
            .shadow(radius: 4)
            .padding()
        }
    }

    func openMenu() {}
    func add() {}
}
