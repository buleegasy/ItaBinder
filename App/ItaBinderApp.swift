import SwiftUI
import SwiftData

@main
struct ItaBinderApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            Collection.self,
            Tag.self,
            AssetMetadata.self
        ])
        
        // CloudKit configuration
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitContainerIdentifier: "iCloud.com.example.ItaBinder" // Replace with real ID
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            CollectionsView()
        }
        .modelContainer(sharedModelContainer)
    }
}
