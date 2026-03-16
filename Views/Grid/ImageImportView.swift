import SwiftUI
import PhotosUI

struct ImageImportView: View {
    @State private var pendingImageIDs: [String] = []
    @State private var coverImageID: String?
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var isProcessing = false
    @State private var isShowingCamera = false
    @State private var photoService = PhotoLibraryService()
    
    @State private var currentTitle: String = ""
    @State private var currentIP: String = ""
    @State private var currentPrice: String = ""
    @State private var currentCurrency: String = "CNY"
    @State private var currentQuantity: Int = 1
    @State private var currentBrand: String = ""
    @State private var currentPurchaseDate: Date = Date()
    @State private var currentHoldingStatus: String = "已持有"
    @State private var currentNotes: String = ""
    
    @State private var suggestedIPs: [String] = []
    @State private var suggestedBrands: [String] = []
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // MARK: - Top Image Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("添加图片")
                            .font(.headline)
                        Spacer()
                        PhotosPicker(
                            selection: $selectedItems,
                            maxSelectionCount: 20,
                            matching: .images
                        ) {
                            Text("全部照片")
                                .font(.subheadline)
                                .foregroundColor(.itabinderGreen)
                                .fontWeight(.medium)
                        }
                        .disabled(isProcessing)
                    }
                    .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            // Camera Button
                            Button(action: {
                                HapticManager.shared.impact(.medium)
                                isShowingCamera = true
                            }) {
                                VStack {
                                    Image(systemName: "camera.fill")
                                        .font(.title)
                                    Text("拍照")
                                        .font(.caption)
                                }
                                .frame(width: 100, height: 100)
                                .background(Color(.secondarySystemGroupedBackground))
                                .foregroundColor(.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                                )
                            }
                            
                            // Recent Photos
                            ForEach(photoService.recentAssets, id: \.localIdentifier) { asset in
                                RecentPhotoCard(asset: asset, photoService: photoService) { image in
                                    handleRecentSelection(image)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // MARK: - Pending/Selected Section
                    if !pendingImageIDs.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("已选图片 (\(pendingImageIDs.count)) - 点击设为封面")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .padding(.leading)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(pendingImageIDs, id: \.self) { id in
                                        pendingImageCard(id: id)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 8)
                    }
                }
                .padding(.vertical)
                .background(Color(.systemGroupedBackground).opacity(0.5))
                
                if isProcessing {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("正在处理图片...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)
                }
                
                // MARK: - Form Sections
                VStack(spacing: 20) {
                    Group {
                        sectionHeader("基本信息")
                        VStack(spacing: 12) {
                            customTextField("物品名称", text: $currentTitle)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                customTextField("IP 名称", text: $currentIP)
                                if !suggestedIPs.isEmpty {
                                    TagScrollRow(tags: suggestedIPs) { tag in
                                        currentIP = tag
                                    }
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                customTextField("品牌", text: $currentBrand)
                                if !suggestedBrands.isEmpty {
                                    TagScrollRow(tags: suggestedBrands) { tag in
                                        currentBrand = tag
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    
                    Group {
                        sectionHeader("交易信息")
                        VStack(spacing: 16) {
                            HStack {
                                Text("价格")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                TextField("0.00", text: $currentPrice)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .fontWeight(.bold)
                                
                                Picker("", selection: $currentCurrency) {
                                    Text("¥").tag("CNY")
                                    Text("円").tag("JPY")
                                    Text("$").tag("USD")
                                }
                                .pickerStyle(.menu)
                                .labelsHidden()
                            }
                            
                            Divider()
                            
                            Stepper("数量: \(currentQuantity)", value: $currentQuantity, in: 1...100)
                                .font(.subheadline)
                            
                            Divider()
                            
                            DatePicker("购入时间", selection: $currentPurchaseDate, displayedComponents: .date)
                                .font(.subheadline)
                            
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 10) {
                                Text("持仓状态")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Picker("持仓状态", selection: $currentHoldingStatus) {
                                    Text("待发货").tag("待发货")
                                    Text("已发货").tag("已发货")
                                    Text("已持有").tag("已持有")
                                }
                                .pickerStyle(.segmented)
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    
                    Group {
                        sectionHeader("备注")
                        TextEditor(text: $currentNotes)
                            .frame(minHeight: 100)
                            .padding(8)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding()
            }
        }
        .background(DynamicGlassBackground())
        .navigationTitle("导入物品")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("导入") {
                    finalizeImport()
                }
                .disabled(pendingImageIDs.isEmpty || isProcessing || currentTitle.isEmpty)
                .fontWeight(.bold)
                .foregroundColor(pendingImageIDs.isEmpty || isProcessing || currentTitle.isEmpty ? .secondary : .itabinderGreen)
            }
        }
        .fullScreenCover(isPresented: $isShowingCamera) {
            GuidedCameraView { image in
                handleRecentSelection(image)
            }
        }
        .onAppear {
            photoService.requestPermissionAndFetch()
            loadSuggestions()
        }
        .onChange(of: selectedItems) { _, newValue in
            Task {
                await processItems(newValue)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption.bold())
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 8)
    }
    
    private func customTextField(_ placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(placeholder)
                .font(.caption2)
                .foregroundColor(.secondary)
            TextField(placeholder, text: text)
                .textFieldStyle(.plain)
        }
    }
    
    @ViewBuilder
    private func pendingImageCard(id: String) -> some View {
        ZStack(alignment: .topTrailing) {
            AsyncThumbnailImage(itemID: id)
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .contentShape(Rectangle())
                .onTapGesture {
                    HapticManager.shared.selection()
                    withAnimation(.spring()) {
                        coverImageID = id
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(coverImageID == id ? Color.itabinderGreen : Color.clear, lineWidth: 3)
                )
            
            if coverImageID == id {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.itabinderGreen)
                    .background(Circle().fill(.white))
                    .font(.caption)
                    .offset(x: 5, y: -5)
            }
            
            Button(action: {
                HapticManager.shared.impact(.light)
                withAnimation {
                    pendingImageIDs.removeAll { $0 == id }
                    if coverImageID == id {
                        coverImageID = pendingImageIDs.first
                    }
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .red)
                    .font(.caption)
            }
            .offset(x: 5, y: 5)
        }
    }
    
    private func handleRecentSelection(_ image: UIImage) {
        isProcessing = true
        HapticManager.shared.impact(.light)
        
        Task {
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".jpg")
            if let data = image.jpegData(compressionQuality: 0.8) {
                try? data.write(to: tempURL)
                
                do {
                    let ids = try await ImageImporter.shared.batchImport(urls: [tempURL])
                    await MainActor.run {
                        withAnimation {
                            pendingImageIDs.append(contentsOf: ids)
                            if coverImageID == nil {
                                coverImageID = ids.first
                            }
                        }
                        isProcessing = false
                    }
                } catch {
                    print("Quick import failed: \(error)")
                    await MainActor.run { isProcessing = false }
                }
                
                try? FileManager.default.removeItem(at: tempURL)
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
            let ids = try await ImageImporter.shared.batchImport(urls: tempURLs)
            await MainActor.run {
                withAnimation {
                    pendingImageIDs.append(contentsOf: ids)
                    if coverImageID == nil {
                        coverImageID = ids.first
                    }
                }
                isProcessing = false
                selectedItems = []
            }
            
            // Cleanup temp files
            for url in tempURLs {
                try? FileManager.default.removeItem(at: url)
            }
        } catch {
            print("Import failed: \(error)")
            await MainActor.run { isProcessing = false }
        }
    }
    
    private func finalizeImport() {
        let priceValue = Double(currentPrice)
        let newItem = Item(
            title: currentTitle,
            ipName: currentIP,
            price: priceValue,
            currency: currentCurrency,
            quantity: currentQuantity,
            brand: currentBrand,
            purchaseDate: currentPurchaseDate,
            holdingStatus: currentHoldingStatus,
            notes: currentNotes,
            imageIDs: pendingImageIDs,
            coverImageID: coverImageID
        )
        
        modelContext.insert(newItem)
        try? modelContext.save()
        HapticManager.shared.notification(.success)
        dismiss()
    }
    
    private func loadSuggestions() {
        suggestedIPs = SuggestionService.shared.fetchFrequentIPs(in: modelContext)
        suggestedBrands = SuggestionService.shared.fetchFrequentBrands(in: modelContext)
    }
}

// MARK: - Subviews

struct PillTag: View {
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.shared.impact(.light)
            action()
        }) {
            Text(text)
                .font(.system(size: 11, weight: .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.itabinderGreen.opacity(0.1))
                .foregroundColor(.itabinderGreen)
                .clipShape(Capsule())
        }
    }
}

struct TagScrollRow: View {
    let tags: [String]
    let onSelect: (String) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    PillTag(text: tag) {
                        onSelect(tag)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

struct RecentPhotoCard: View {
    let asset: PHAsset
    let photoService: PhotoLibraryService
    let onSelect: (UIImage) -> Void
    
    @State private var image: UIImage?
    
    var body: some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .onTapGesture {
                        onSelect(image)
                    }
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .frame(width: 100, height: 100)
                    .onAppear {
                        photoService.fetchThumbnail(for: asset) { fetchedImage in
                            Task { @MainActor in
                                self.image = fetchedImage
                            }
                        }
                    }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ImageImportView()
    }
}
