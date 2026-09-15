import SwiftUI

struct ContentView: View {
    var body: some View {
        WebView()
            .ignoresSafeArea()          // the page handles its own safe-area padding
            .background(Color("Ground"))
    }
}

#Preview {
    ContentView()
}
