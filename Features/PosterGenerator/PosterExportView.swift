import SwiftUI
import SwiftData

struct PosterExportView: View {
    let selectedItems: [Item]
    
    @State private var config = PosterConfiguration()
    @State private var renderedImage: UIImage?
    @State private var extractedColors: DominantColors = .fallback
    @State private var isRendering = false
    @State private var showShareSheet = false
    @State private var exportURL: URL?
    @State private var showSaveAlert = false
    @State private var saveAlertMessage = ""
    
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTitleFocused: Bool
    
    private var snapshots: [PosterItemSnapshot] {
        selectedItems.map { PosterItemSnapshot(from: $0) }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Live Preview
                    previewSection
                    
                    // Controls
                    VStack(spacing: 20) {
                        // Custom Title
                        titleEditor
                        
                        // Template Picker
                        templatePicker
                        
                        // Decoration
                        decorationPicker
                        
                        // Content Toggles
                        contentToggles
                    }
                    .padding(.horizontal, 20)
                    
                    // Export
                    exportActions
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("海报生成")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("关闭") { dismiss() }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportURL {
                    ShareSheet(activityItems: [url])
                }
            }
            .alert("保存状态", isPresented: $showSaveAlert) {
                Button("好的", role: .cancel) { }
            } message: {
                Text(saveAlertMessage)
            }
            .onAppear {
                extractedColors = PosterRenderService.shared.extractColors(from: snapshots)
                generatePreview()
            }
            .onChange(of: config.template) { _, _ in generatePreview() }
            .onChange(of: config.decoration) { _, _ in generatePreview() }
            .onChange(of: config.customTitle) { _, _ in debounceGenerate() }
            .onChange(of: config.showTitle) { _, _ in generatePreview() }
            .onChange(of: config.showIPName) { _, _ in generatePreview() }
            .onChange(of: config.showPrice) { _, _ in generatePreview() }
            .onChange(of: config.showBrand) { _, _ in generatePreview() }
            .onChange(of: config.showStatus) { _, _ in generatePreview() }
        }
    }
    
    // MARK: - Preview
    
    private var previewSection: some View {
        ZStack {
            // Shadow container
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
                .shadow(color: .black.opacity(0.12), radius: 24, y: 12)
            
            if let image = renderedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(6)
            } else if isRendering {
                ProgressView("生成中...")
                    .foregroundColor(.secondary)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 28))
                        .foregroundColor(.itabinderGreen.opacity(0.4))
                    Text("正在准备...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .aspectRatio(9.0 / 16.0, contentMode: .fit)
        .padding(.horizontal, 40)
        .padding(.top, 8)
    }
    
    // MARK: - Title Editor
    
    private var titleEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("海报标题")
            
            TextField("我的收藏", text: $config.customTitle)
                .font(.system(size: 18, weight: .semibold))
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .focused($isTitleFocused)
        }
    }
    
    // MARK: - Template Picker
    
    private var templatePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("模板风格")
            
            HStack(spacing: 10) {
                ForEach(PosterTemplate.allCases) { template in
                    Button {
                        HapticManager.shared.impact(.light)
                        config.template = template
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: template.icon)
                                .font(.system(size: 20))
                            Text(template.rawValue)
                                .font(.system(size: 12, weight: .semibold))
                            Text(template.subtitle)
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            config.template == template
                            ? Color.itabinderGreen.opacity(0.12)
                            : Color(.tertiarySystemGroupedBackground)
                        )
                        .foregroundColor(
                            config.template == template ? .itabinderGreen : .secondary
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    config.template == template ? Color.itabinderGreen : .clear,
                                    lineWidth: 1.5
                                )
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Decoration Picker
    
    private var decorationPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("装饰")
            
            HStack(spacing: 10) {
                ForEach(PosterDecoration.allCases) { deco in
                    Button {
                        HapticManager.shared.impact(.light)
                        config.decoration = deco
                    } label: {
                        Text(deco.rawValue)
                            .font(.system(size: 13, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                config.decoration == deco
                                ? Color.itabinderGreen.opacity(0.12)
                                : Color(.tertiarySystemGroupedBackground)
                            )
                            .foregroundColor(
                                config.decoration == deco ? .itabinderGreen : .secondary
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(
                                        config.decoration == deco ? Color.itabinderGreen : .clear,
                                        lineWidth: 1.5
                                    )
                            )
                    }
                }
            }
        }
    }
    
    // MARK: - Content Toggles
    
    private var contentToggles: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("显示内容")
            
            VStack(spacing: 0) {
                toggleRow("物品名称", isOn: $config.showTitle)
                Divider().padding(.leading, 16)
                toggleRow("IP 名称", isOn: $config.showIPName)
                Divider().padding(.leading, 16)
                toggleRow("价格", isOn: $config.showPrice)
                Divider().padding(.leading, 16)
                toggleRow("品牌", isOn: $config.showBrand)
                Divider().padding(.leading, 16)
                toggleRow("持有状态", isOn: $config.showStatus)
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
    
    private func toggleRow(_ title: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(title).font(.subheadline)
        }
        .tint(.itabinderGreen)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
    
    // MARK: - Export
    
    private var exportActions: some View {
        HStack(spacing: 12) {
            Button {
                HapticManager.shared.impact(.medium)
                saveToPhotos()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.down")
                    Text("保存到相册")
                }
                .font(.system(size: 15, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.itabinderGreen)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(renderedImage == nil)
            
            Button {
                HapticManager.shared.impact(.medium)
                sharePoster()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.up")
                    Text("分享")
                }
                .font(.system(size: 15, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(.tertiarySystemGroupedBackground))
                .foregroundColor(.itabinderGreen)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.itabinderGreen.opacity(0.3), lineWidth: 1)
                )
            }
            .disabled(renderedImage == nil)
        }
    }
    
    // MARK: - Helpers
    
    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.secondary)
    }
    
    @State private var generateTask: Task<Void, Never>?
    
    private func generatePreview() {
        isRendering = true
        generateTask?.cancel()
        generateTask = Task {
            let image = PosterRenderService.shared.render(items: snapshots, config: config, colors: extractedColors)
            if !Task.isCancelled {
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        renderedImage = image
                        isRendering = false
                    }
                }
            }
        }
    }
    
    private func debounceGenerate() {
        generateTask?.cancel()
        generateTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            if !Task.isCancelled {
                generatePreview()
            }
        }
    }
    
    private func saveToPhotos() {
        guard let image = renderedImage else { return }
        Task {
            do {
                try await PhotoLibraryManager.shared.saveImageToLibrary(image)
                HapticManager.shared.notification(.success)
                saveAlertMessage = "海报已成功保存到系统相册"
                showSaveAlert = true
            } catch {
                HapticManager.shared.notification(.error)
                saveAlertMessage = error.localizedDescription
                showSaveAlert = true
            }
        }
    }
    
    private func sharePoster() {
        guard let image = renderedImage else { return }
        exportURL = PosterRenderService.shared.exportToPNG(image: image)
        if exportURL != nil {
            showShareSheet = true
        }
    }
}
