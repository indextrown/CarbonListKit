import SwiftUI

struct ContentView: View {
  var body: some View {
    ExampleNavigationView()
      .ignoresSafeArea()
  }
}

struct ExampleNavigationView: UIViewControllerRepresentable {
  func makeUIViewController(context: Context) -> UINavigationController {
    UINavigationController(rootViewController: ExampleListViewController())
  }

  func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
  }
}

#Preview {
  ContentView()
}
