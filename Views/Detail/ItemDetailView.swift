import SwiftUI
import SwiftData
import PhotosUI

struct ItemDetailView: View {
    @Bindable var item: Item
    @Environment(\.modelContext) private var modelContext
    @Environment(MainNavigationState.self) private var navState
    
    @State private var isEditing = false
    @State private var tempPrice: String = ""
    @State private var suggestedIPs: [String] = []
    @State private var suggestedBrands: [String] = []
    
    // Image Editing State
    @State private var selectedPickerItems: [PhotosPickerItem] = []
    @State private var tempImageIDs: [String] = []
    @State private var imagesToRemove: Set<String> = []
    @State private var newUIImages: [String: UIImage] = [:] // Local cache for newly picked images
    @State private var tempCoverID: String?
    @State private var processingImageIDs: Set<String> = [] // IDs of images currently being processed
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case title, ipName, brand, price, notes
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Image Section (Gallery) - Immersive Edge-to-Edge
                ZStack(alignment: .bottomTrailing) {
                    TabView {
                        let activeIDs = tempImageIDs.filter { !imagesToRemove.contains($0) }
                        
                        if !activeIDs.isEmpty {
                                ForEach(activeIDs, id: \.self) { imageID in
                                    ZStack(alignment: .topTrailing) {
                                        imageProxy(for: imageID)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 500)
                                            .clipped()
                                        
                                        if isEditing {
                                            imageEditOverlay(for: imageID)
                                        }
                                        
                                        if processingImageIDs.contains(imageID) {
                                            ZStack {
                                                Color.black.opacity(0.3)
                                                VStack(spacing: 12) {
                                                    ProgressView()
                                                        .tint(.white)
                                                    Text("AI 抠图中...")
                                                        .font(.caption.bold())
                                                        .foregroundColor(.white)
                                                }
                                            }
                                        }
                                    }
                                }
                        } else {
                            placeholderImage
                        }
                    }
                    .frame(height: 500)
                    .tabViewStyle(.page(indexDisplayMode: .always))
                    .background(Color(.systemGroupedBackground))
                    
                    if isEditing {
                        PhotosPicker(selection: $selectedPickerItems, matching: .images) {
                            labelWithIcon(title: "接更多回库", icon: "plus.circle.fill")
                        }
                        .padding()
                        .onChange(of: selectedPickerItems) { _, _ in
                            handlePickerSelection()
                        }
                    }
                }
                .listRowInsets(EdgeInsets())
                
                // Content Section - HIG Padded
                VStack(alignment: .leading, spacing: 24) {
                    // Title Area
                    VStack(alignment: .leading, spacing: 10) {
                        if isEditing {
                            TextField("物品名称", text: $item.title)
                                .font(.system(size: 28, weight: .bold))
                                .textFieldStyle(.plain)
                                .focused($focusedField, equals: .title)
                        } else {
                            Text(item.title)
                                .font(.system(size: 28, weight: .bold))
                                .lineSpacing(4)
                        }
                    }
                    
                    VStack(spacing: 24) {
                        // Standardized Info Section
                        VStack(spacing: 0) {
                            infoContent
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: Color.primary.opacity(0.04), radius: 10, x: 0, y: 5)
                    
                        // Notes Section
                        VStack(alignment: .leading, spacing: 14) {
                            Text("备注 / Tags")
                                .font(.headline)
                                .padding(.leading, 4)
                            
                            notesContent
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical)
        }
        .navigationTitle("物品详情")
        .navigationBarTitleDisplayMode(.inline)
        .background(DynamicGlassBackground())
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(isEditing ? "完成" : "编辑") {
                    if isEditing {
                        finalizeEditing()
                    } else {
                        startEditing()
                    }
                    HapticManager.shared.impact(.medium)
                    withAnimation { isEditing.toggle() }
                }
                .fontWeight(.bold)
                .foregroundColor(isEditing ? .itabinderGreen : .primary)
            }
        }
        .onAppear {
            navState.isTabBarVisible = false
        }
        .onDisappear {
            navState.isTabBarVisible = true
        }
        .fullScreenCover(isPresented: $showingRefinement) {
            refinementSheet
        }
    }
    
    // MARK: - Restore Missing Helpers
    
    private var holdingStatusBadge: some View {
        Text(item.holdingStatus)
            .font(.caption.bold())
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(statusColor.opacity(0.15))
            .foregroundColor(statusColor)
            .clipShape(Capsule())
    }
    
    private var statusColor: Color {
        switch item.holdingStatus {
        case "待发货": return .orange
        case "已发货": return .blue
        case "已持有": return .itabinderGreen
        default: return .secondary
        }
    }
    
    private var currencySymbol: String {
        switch item.currency.uppercased() {
        case "CNY": return "¥"
        case "JPY": return "円"
        case "USD": return "$"
        default: return ""
        }
    }
    
    private func startEditing() {
        tempPrice = item.price != nil ? String(format: "%.2f", item.price!) : ""
        tempImageIDs = item.imageIDs
        tempCoverID = item.coverImageID
        imagesToRemove.removeAll()
        newUIImages.removeAll()
        loadSuggestions()
    }
    
    private func finalizeEditing() {
        // 1. Update Price
        if let priceValue = Double(tempPrice) {
            item.price = priceValue
        }
        
        // 2. Handle Image Deletions
        for id in imagesToRemove {
            if let index = item.imageIDs.firstIndex(of: id) {
                item.imageIDs.remove(at: index)
                ImageStorageManager.shared.deleteFolder(for: id)
            }
        }
        
        // 3. Handle Image Additions
        for (id, image) in newUIImages {
            if !imagesToRemove.contains(id) {
                if let data = image.jpegData(compressionQuality: 0.8) {
                    _ = try? ImageStorageManager.shared.save(data: data, for: id, type: .display)
                    item.imageIDs.append(id)
                }
            }
        }
        
        // 4. Update Cover
        item.coverImageID = tempCoverID
        
        _ = try? modelContext.save()
    }
    
    private func loadSuggestions() {
        suggestedIPs = SuggestionService.shared.fetchFrequentIPs(in: modelContext)
        suggestedBrands = SuggestionService.shared.fetchFrequentBrands(in: modelContext)
    }
    
    // MARK: - Extracted UI Components
    
    @ViewBuilder
    private var infoContent: some View {
        if isEditing {
            EditableInfoRow(label: "IP 名称", text: $item.ipName, suggestions: suggestedIPs, focused: $focusedField, field: .ipName)
            Divider().padding(.vertical, 8)
            EditableInfoRow(label: "品牌", text: $item.brand, suggestions: suggestedBrands, focused: $focusedField, field: .brand)
            Divider().padding(.vertical, 8)
            
            HStack {
                Text("价格")
                    .foregroundStyle(.secondary)
                Spacer()
                TextField("0.00", text: $tempPrice)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .fontWeight(.bold)
                    .foregroundColor(.itabinderGreen)
                    .focused($focusedField, equals: .price)
                
                Picker("", selection: $item.currency) {
                    Text("¥").tag("CNY")
                    Text("円").tag("JPY")
                    Text("$").tag("USD")
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }
            .padding(.vertical, 4)
            
            Divider().padding(.vertical, 8)
            Stepper("持有数量: \(item.quantity)", value: $item.quantity, in: 1...999)
                .padding(.vertical, 4)
            Divider().padding(.vertical, 8)
            DatePicker("购入时间", selection: $item.purchaseDate, displayedComponents: .date)
                .padding(.vertical, 4)
            Divider().padding(.vertical, 8)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("当前状态")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                Picker("状态", selection: $item.holdingStatus) {
                    Text("待发货").tag("待发货")
                    Text("已发货").tag("已发货")
                    Text("已持有").tag("已持有")
                }
                .pickerStyle(.segmented)
            }
            .padding(.vertical, 4)
        } else {
            InfoRow(label: "IP 名称", value: item.ipName.isEmpty ? "未填写" : item.ipName)
            Divider().padding(.vertical, 8)
            InfoRow(label: "品牌", value: item.brand.isEmpty ? "未填写" : item.brand)
            Divider().padding(.vertical, 8)
            
            HStack {
                Text("预估价格")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(currencySymbol + String(format: "%.2f", item.price ?? 0.0))
                    .fontWeight(.bold)
                    .foregroundColor(.itabinderGreen)
            }
            .padding(.vertical, 4)
            
            Divider().padding(.vertical, 8)
            InfoRow(label: "持有数量", value: "\(item.quantity)")
            Divider().padding(.vertical, 8)
            InfoRow(label: "购入时间", value: item.purchaseDate.formatted(date: .long, time: .omitted))
            Divider().padding(.vertical, 8)
            
            HStack {
                Text("当前状态")
                    .foregroundStyle(.secondary)
                Spacer()
                holdingStatusBadge
            }
            .padding(.vertical, 4)
        }
    }
    
    @ViewBuilder
    private var notesContent: some View {
        if isEditing {
            TextEditor(text: $item.notes)
                .frame(minHeight: 120)
                .padding(8)
                .focused($focusedField, equals: .notes)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.itabinderGreen.opacity(0.1), lineWidth: 1)
                )
        } else {
            Text(item.notes.isEmpty ? "暂无备注内容" : item.notes)
                .font(.body)
                .foregroundColor(.secondary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    @ViewBuilder
    private func imageProxy(for imageID: String) -> some View {
        if let localImage = newUIImages[imageID] {
            Image(uiImage: localImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            AsyncDisplayImage(itemID: imageID)
                .aspectRatio(contentMode: .fill)
        }
    }
    
    // MARK: - Image Edit Helpers
    
    @ViewBuilder
    private func imageEditOverlay(for imageID: String) -> some View {
        VStack {
            HStack {
                Button(action: {
                    HapticManager.shared.impact(.light)
                    if tempCoverID == imageID {
                        tempCoverID = nil
                    } else {
                        tempCoverID = imageID
                    }
                }) {
                    Image(systemName: tempCoverID == imageID ? "star.fill" : "star")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(tempCoverID == imageID ? .yellow : .white)
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                
                Button(action: {
                    performBackgroundRemoval(for: imageID)
                }) {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .disabled(processingImageIDs.contains(imageID))
                
                Spacer()
                
                Button(action: {
                    HapticManager.shared.impact(.medium)
                    _ = withAnimation {
                        imagesToRemove.insert(imageID)
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
            }
            .padding(12)
            Spacer()
            
            if tempCoverID == imageID {
                Text("封面图")
                    .font(.caption2.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.itabinderGreen)
                    .clipShape(Capsule())
                    .padding(.bottom, 30)
            }
        }
    }
    
    private var placeholderImage: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 40))
                .foregroundColor(.itabinderGreen.opacity(0.3))
            Text("展柜空空如也")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    private func labelWithIcon(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
            Text(title)
        }
        .font(.subheadline.bold())
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .foregroundColor(.itabinderGreen)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    private func handlePickerSelection() {
        Task {
            for item in selectedPickerItems {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    let newID = UUID().uuidString
                    await MainActor.run {
                        newUIImages[newID] = uiImage
                        tempImageIDs.append(newID)
                    }
                }
            }
            await MainActor.run {
                selectedPickerItems = []
            }
        }
    }

    @State private var showingRefinement = false
    @State private var refinementImageID: String?
    @State private var refinementOriginalImage: UIImage?
    @State private var refinementAIMask: CIImage?

    private func performBackgroundRemoval(for imageID: String) {
        guard !processingImageIDs.contains(imageID) else { return }
        
        let sourceImage: UIImage?
        if let local = newUIImages[imageID] {
            sourceImage = local
        } else {
            sourceImage = ImageStorageManager.shared.load(for: imageID, type: .display)
        }
        
        guard let imageToProcess = sourceImage else { return }
        
        HapticManager.shared.impact(.medium)
        _ = withAnimation { processingImageIDs.insert(imageID) }
        
        Task {
            do {
                // Normalize orientation for reliable CV processing (Phase 3/4)
                guard let normalizedImage = imageToProcess.normalized() else { return }
                
                // Generate AI mask (Phase 2) using normalized image
                let aiMask = try await SemanticLiftingEngine.shared.generateHighResAIMask(from: normalizedImage)
                
                await MainActor.run {
                    _ = withAnimation { processingImageIDs.remove(imageID) }
                    
                    // Store for refinement
                    refinementImageID = imageID
                    refinementOriginalImage = normalizedImage
                    refinementAIMask = aiMask
                    showingRefinement = true
                }
            } catch {
                // Fallback to simple removal if refinement setup fails
                do {
                    if let processed = try await BackgroundRemovalService.shared.removeBackground(from: imageToProcess) {
                        await MainActor.run {
                            withAnimation {
                                newUIImages[imageID] = processed
                                processingImageIDs.remove(imageID)
                            }
                            HapticManager.shared.notification(.success)
                        }
                    }
                } catch {
                    await MainActor.run {
                        _ = withAnimation { processingImageIDs.remove(imageID) }
                        HapticManager.shared.notification(.error)
                    }
                }
            }
        }
    }
    
    private var refinementSheet: some View {
        Group {
            if let origImage = refinementOriginalImage,
               let mask = refinementAIMask,
               let imgID = refinementImageID {
                RefinementView(originalImage: origImage, aiMask: mask) { refinedImage in
                    withAnimation {
                        newUIImages[imgID] = refinedImage
                    }
                    HapticManager.shared.notification(.success)
                }
            }
        }
    }
}

struct EditableInfoRow: View {
    let label: String
    @Binding var text: String
    let suggestions: [String]
    var focused: FocusState<ItemDetailView.Field?>.Binding
    let field: ItemDetailView.Field
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .foregroundStyle(.secondary)
                Spacer()
                TextField("请输入...", text: $text)
                    .multilineTextAlignment(.trailing)
                    .focused(focused, equals: field)
            }
            .padding(.vertical, 4)
            
            if !suggestions.isEmpty {
                TagScrollRow(tags: suggestions) { tag in
                    text = tag
                }
            }
        }
    }
}

// MARK: - Helpers

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .padding(.vertical, 4)
    }
}

/// A simple flow layout for tags
struct FlowLayout: Layout {
    var spacing: CGFloat
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.offsets[index].x, y: bounds.minY + result.offsets[index].y), proposal: .unspecified)
        }
    }
    
    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, offsets: [CGPoint]) {
        var offsets: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var maxRowHeight: CGFloat = 0
        var totalWidth: CGFloat = 0
        
        let maxWidth = proposal.width ?? .infinity
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += maxRowHeight + spacing
                maxRowHeight = 0
            }
            
            offsets.append(CGPoint(x: currentX, y: currentY))
            currentX += size.width + spacing
            maxRowHeight = max(maxRowHeight, size.height)
            totalWidth = max(totalWidth, currentX)
        }
        
        return (CGSize(width: totalWidth, height: currentY + maxRowHeight), offsets)
    }
}
