import SwiftUI
import UIKit

struct ImageExportView: View {
    @State private var selectedLayout: CollageLayout = .oneByThree
    @State private var renderedImage: UIImage?
    @State private var isRendering = false
    @State private var showShareSheet = false
    @State private var exportURL: URL?
    
    // In a real app, these would be selected items from the collection
    private let sampleImages = [
        UIImage(systemName: "star.fill")!,
        UIImage(systemName: "heart.fill")!,
        UIImage(systemName: "moon.fill")!,
        UIImage(systemName: "sun.max.fill")!
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            Picker("Layout", selection: $selectedLayout) {
                Text("1 x 3").tag(CollageLayout.oneByThree)
                Text("2 x 2").tag(CollageLayout.twoByTwo)
            }
            .pickerStyle(.segmented)
            .padding()
            
            // Preview
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .shadow(radius: 5)
                
                if let image = renderedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding()
                } else if isRendering {
                    ProgressView("Generating Collage...")
                } else {
                    VStack {
                        Image(systemName: "sparkles")
                            .font(.largeTitle)
                            .foregroundColor(.itabinderGreen)
                        Text("点击“预览”生成痛板")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .padding()
            
            Button(action: {
                HapticManager.shared.impact(.light)
                generateCollage()
            }) {
                Text(renderedImage == nil ? "生成预览" : "重新生成")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.itabinderGreen)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .disabled(isRendering)
            
            if renderedImage != nil {
                HStack(spacing: 12) {
                    Button(action: {
                        HapticManager.shared.impact(.medium)
                        exportCollage()
                    }) {
                        Label("生成痛板海报", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.itabinderGreen)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        HapticManager.shared.impact(.medium)
                        saveToPhotos()
                    }) {
                        Label("保存到相册", systemImage: "square.and.arrow.down")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .navigationTitle("Collage")
        .sheet(isPresented: $showShareSheet) {
            if let url = exportURL {
                ShareSheet(activityItems: [url])
            }
        }
        .alert("Export", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    private func generateCollage() {
        isRendering = true
        Task {
            let imagesToUse = selectedLayout == .oneByThree ? Array(sampleImages.prefix(3)) : sampleImages
            renderedImage = CollageExportService.shared.renderCollage(images: imagesToUse, layout: selectedLayout)
            isRendering = false
        }
    }
    
    private func saveToPhotos() {
        guard let image = renderedImage else { return }
        Task {
            do {
                try await PhotoLibraryManager.shared.saveImageToLibrary(image)
                alertMessage = "Successfully saved to Photos!"
                showAlert = true
            } catch {
                alertMessage = error.localizedDescription
                showAlert = true
            }
        }
    }
    
    private func exportCollage() {
        guard let image = renderedImage else { return }
        exportURL = CollageExportService.shared.exportToPNG(image: image)
        if exportURL != nil {
            showShareSheet = true
        }
    }
}
