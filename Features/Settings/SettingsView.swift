import SwiftUI

import SwiftUI

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @State private var syncManager = SyncManager.shared
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Enable iCloud Sync", isOn: $viewModel.isiCloudSyncEnabled)
                    
                    HStack {
                        Text("Status")
                        Spacer()
                        if syncManager.isSyncing {
                            ProgressView()
                                .padding(.trailing, 4)
                            Text("Syncing...")
                                .foregroundStyle(.secondary)
                        } else {
                            Text(syncManager.lastSyncDate?.formatted(date: .abbreviated, time: .shortened) ?? "Never")
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    if let error = syncManager.syncError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                } header: {
                    Text("Cloud")
                } footer: {
                    Text("Your collection metadata and thumbnails will be synced across your Apple devices.")
                }
                
                Section("Storage") {
                    HStack {
                        Text("Image Cache")
                        Spacer()
                        Text(viewModel.cacheSize)
                            .foregroundStyle(.secondary)
                    }
                    
                    Button(role: .destructive, action: viewModel.clearCache) {
                        if viewModel.isClearingCache {
                            ProgressView()
                        } else {
                            Text("Clear Image Cache")
                        }
                    }
                    .disabled(viewModel.isClearingCache)
                }
                
                Section("Export Settings") {
                    Toggle("Include Watermark", isOn: $viewModel.isWatermarkEnabled)
                        .tint(.accentColor)
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    
                    Link("GitHub Repository", destination: URL(string: "https://github.com/example/itabinder")!)
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                viewModel.updateCacheSize()
            }
        }
    }
}
