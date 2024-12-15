import SwiftUI
import SwiftUIX

struct ContentView: View {
    @EnvironmentObject private var viewModel: WordListViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            WordListView()
                .minHeight(300)
            
            Divider()
            
            StatisticsView(data: viewModel.hourlyStatistics)
            
            Divider()
            
            SettingsView()
            
            Divider()
            
            BottomBarView()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(WordListViewModel())
} 
