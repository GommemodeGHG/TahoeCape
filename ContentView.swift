import SwiftUI

struct ContentView: View {
    @StateObject private var permissions = PermissionManager()
    @StateObject private var logger = AppLogger.shared
    @State private var selectedCape: Cape?
    @State private var capes: [Cape] = []
    @State private var isImporting = false
    
    var body: some View {
        VStack(spacing: 0) {
            if !permissions.isAccessibilityAllowed {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text("Accessibility permissions are required to apply cursors system-wide.")
                    Spacer()
                    Button("Enable") {
                        permissions.requestAccessibility()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .padding(8)
                .background(Color.yellow.opacity(0.2))
                .foregroundColor(.yellow)
            }
            
            NavigationSplitView {
                // Sidebar
                List(selection: $selectedCape) {
                    Section("Library") {
                        ForEach(capes) { cape in
                            NavigationLink(value: cape) {
                                Label(cape.name, systemImage: "paintbrush.fill")
                            }
                        }
                    }
                    
                    Section("System") {
                        Label("Default Cursors", systemImage: "arrow.cursor")
                        Label("High Contrast", systemImage: "circle.lefthalf.filled")
                    }
                }
                .navigationTitle("TahoeCape")
                .toolbar {
                    ToolbarItem {
                        Button(action: { isImporting = true }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            } detail: {
                if let cape = selectedCape {
                    CapeDetailView(cape: cape)
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "cursorarrow.and.square.on.square.dashed")
                            .font(.system(size: 60))
                            .foregroundStyle(TahoeColors.auroraGradient)
                        
                        Text("Select a Cursor Pack")
                            .font(.title2.bold())
                        
                        Text("Drag and drop a .cape file here to get started.")
                            .foregroundColor(.secondary)
                        
                        Button("Import .cape") {
                            isImporting = true
                        }
                        .buttonStyle(TahoeButtonStyle())
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(TahoeColors.glassBackground)
                }
            }
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [.item],
                allowsMultipleSelection: false
            ) { result in
                do {
                    let url = try result.get().first!
                    if url.startAccessingSecurityScopedResource() {
                        defer { url.stopAccessingSecurityScopedResource() }
                        let cape = try CapeParser.parse(at: url)
                        capes.append(cape)
                        selectedCape = cape
                        logger.log("Successfully imported: \(cape.name)")
                    }
                } catch {
                    logger.log("Import failed: \(error.localizedDescription)")
                }
            }
            
            // Logs View
            VStack(alignment: .leading) {
                Divider()
                HStack {
                    Text("System Logs")
                        .font(.caption.bold())
                    Spacer()
                    Button("Copy") {
                        let allLogs = logger.logs.joined(separator: "\n")
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(allLogs, forType: .string)
                    }
                    .buttonStyle(.plain)
                    .font(.caption)
                    
                    Button("Clear") {
                        logger.logs.removeAll()
                    }
                    .buttonStyle(.plain)
                    .font(.caption)
                }
                .padding(.horizontal)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(logger.logs, id: \.self) { log in
                            Text(log)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 100)
            }
            .background(Color.black.opacity(0.1))
        }
    }
}

struct CapeDetailView: View {
    let cape: Cape
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading) {
                        Text(cape.name)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                        
                        Text("By \(cape.author ?? "Unknown Author")")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        AppLogger.shared.log("Batch applying all cursors in \(cape.name)...")
                        for (name, cursor) in cape.cursors {
                            CursorService.shared.apply(cursor: cursor, identifier: name)
                        }
                        AppLogger.shared.log("✅ Batch application complete.")
                    }) {
                        Text("Apply All")
                    }
                    .buttonStyle(TahoeButtonStyle())
                }
                .padding(.horizontal)
                
                // Cursor Grid
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 20) {
                    ForEach(cape.cursors.sorted(by: { $0.key < $1.key }), id: \.key) { name, cursor in
                        Button(action: {
                            CursorService.shared.apply(cursor: cursor, identifier: name)
                        }) {
                            CursorCard(cursor: cursor, name: name)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
        }
        .background(TahoeColors.glassBackground.ignoresSafeArea())
    }
}
