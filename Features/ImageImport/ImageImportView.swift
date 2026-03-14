import SwiftUI
import PhotosUI

struct ImageImportView: View {
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var isProcessing = false
    @State private var importCount = 0
    
    var body: some View {
        VStack(spacing: 20) {
            PhotosPicker(
                selection: $selectedItems,
                maxSelectionCount: 10,
                matching: .images
            ) {
                Label("Select Images to Import", systemName: "photo.on.rectangle.angled")
                    .font(.headline)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(isProcessing)
            
            if isProcessing {
                ProgressView("Optimizing Images...")
            }
            
            if importCount > 0 {
                Text("Successfully imported \(importCount) images")
                    .foregroundColor(.green)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Import")
        .onChange(of: selectedItems) { _, newValue in
            Task {
                await processItems(newValue)
            }
        }
    }
    
    private func processItems(_ items: [PhotosPickerItem]) async {
        guard !items.isEmpty else { return }
        
        isProcessing = true
        var tempURLs: [URL] = []
        
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self) {
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
                try? data.write(to: tempURL)
                tempURLs.append(tempURL)
            }
        }
        
        do {
            let results = try await ImageImportService.shared.batchImport(urls: tempURLs)
            importCount = results.count
            
            // Cleanup temp files
            for url in tempURLs {
                try? FileManager.default.removeItem(at: url)
            }
        } catch {
            print("Import failed: \(error)")
        }
        
        isProcessing = false
        selectedItems = []
    }
}

#Preview {
    NavigationStack {
        ImageImportView()
    }
}
