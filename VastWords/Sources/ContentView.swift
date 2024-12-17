import SwiftUI
import SwiftUIX

struct ContentView: View {
    @EnvironmentObject private var viewModel: WordListViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            WordListView()
                .minHeight(300)
            
            Divider()
            
            StatisticsView()
            
            Divider()
            
            SettingsView()
            
            Divider()
            
//            LimitationsView()
//            
//            Divider()
            
            BottomBarView()
        }
        .focusable(false)
    }
}

#Preview {
    ContentView()
        .environmentObject(WordListViewModel(repository: .shared))
} 
