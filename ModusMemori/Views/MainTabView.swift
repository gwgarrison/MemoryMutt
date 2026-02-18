import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var selectedTab: Tab = .home
    
    enum Tab: String, CaseIterable {
        case home = "Home"
        case decks = "Decks"
        case study = "Study"
        case statistics = "Statistics"
        case settings = "Settings"
        
        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .decks: return "rectangle.stack.fill"
            case .study: return "book.fill"
            case .statistics: return "chart.bar.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label(Tab.home.rawValue, systemImage: Tab.home.icon)
                }
                .tag(Tab.home)
            
            DecksView()
                .tabItem {
                    Label(Tab.decks.rawValue, systemImage: Tab.decks.icon)
                }
                .tag(Tab.decks)
            
            StudyView()
                .tabItem {
                    Label(Tab.study.rawValue, systemImage: Tab.study.icon)
                }
                .tag(Tab.study)
            
            StatisticsView()
                .tabItem {
                    Label(Tab.statistics.rawValue, systemImage: Tab.statistics.icon)
                }
                .tag(Tab.statistics)
            
            SettingsView()
                .tabItem {
                    Label(Tab.settings.rawValue, systemImage: Tab.settings.icon)
                }
                .tag(Tab.settings)
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [Deck.self, Card.self, StudySession.self, Review.self], inMemory: true)
}
