
import AVFoundation
import SwiftUI

struct ContentView: View {

    var body: some View {
        NavigationView {
            MasterView()
            DetailView()
        }.navigationViewStyle(DoubleColumnNavigationViewStyle())
    }
}



struct MasterView: View {
    var body: some View {
        Form {
            Section(header: Text("Uncategorized Demos")) {
                Section {
                    NavigationLink(destination: TableRecipeView()) { Text("Tables") }
                }
            }
        }
        .navigationBarTitle("AudioKit", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Image("audiokit-logo")
                    .resizable()
                    .frame(width: 117,
                           height: 20)
            }
        }
        .font(.system(.body, design: .rounded))
    }
}

struct DetailView: View {
    @State private var opacityValue = 0.0
    
    var body: some View {
        VStack(spacing: 0) {
            Image("audiokit-icon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: UIScreen.main.bounds.width * 0.8, height: UIScreen.main.bounds.height * 0.3)
            Image("audiokit-logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 217,
                       height: 120)
            Text("Welcome to the AudioKit Cookbook")
                .font(.system(.largeTitle, design: .rounded))
                .padding()
            Text("Please select a recipe from the left-side menu.")
                .font(.system(.body, design: .rounded))
        }
        .opacity(opacityValue)
        .onAppear {
            DispatchQueue.main
                .asyncAfter(deadline: .now() + 1) {
                    withAnimation(.easeInOut(duration: 1.0)) {
                        opacityValue = 1.0
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
