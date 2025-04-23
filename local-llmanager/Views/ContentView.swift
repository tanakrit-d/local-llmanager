import SwiftUI

////
////  ContentView.swift
////  local-llmanager
////
////  Created by Dominic McRae on 22/04/2025.
////
//
//import SwiftUI
//
//enum Tab {
//    case models
//    case downloads
//    case settings
//}
//
//struct ContentView: View {
//    @StateObject private var viewModel = LocalLLManagerViewModel()
//    @State private var selectedTab: Tab = .models
//    @Environment(\.colorScheme) var colorScheme
//
//    var body: some View {
//        ZStack {
//            LinearGradient(
//                gradient: Gradient(colors: [
//                    .accent,
//                    colorScheme == .dark ? .black : .white,
//                ]),
//                startPoint: .top,
//                endPoint: .bottom
//            ).ignoresSafeArea(edges: .all)
//                .opacity(0.1)
//
//            VStack {
//                HStack(alignment: .bottom) {
//                    Text("Local LLManager")
//                        .font(Font.largeTitle.bold())
//                        .foregroundColor(.accent)
//                    Spacer()
//                    Button {
//                        if viewModel.isServiceRunning {
//                            Task {
//                                await viewModel.stopService()
//                            }
//                        } else {
//                            viewModel.startService()
//                        }
//                    } label: {
//                        Image(
//                            systemName: viewModel.isServiceRunning ? "stop" : "play"
//                        )
//                        .bold()
//                        .foregroundColor(viewModel.isServiceRunning ? .red : .green)
//                        .padding(8)
//                    }
//                    .buttonBorderShape(.circle)
//                    .controlSize(.large)
//
//                }
//                .padding()
//                TabView(selection: $selectedTab) {
//                    ModelView(viewModel: viewModel)
//                        .tabItem {
//                            Label("Models", systemImage: "square.stack.3d.up")
//                        }
//                        .tag(Tab.models)
//
//                    DownloadsView(viewModel: viewModel)
//                        .tabItem {
//                            Label(
//                                "Downloads",
//                                systemImage: "square.and.arrow.down"
//                            )
//                        }
//                        .tag(Tab.downloads)
//
//                    SettingsView(viewModel: viewModel)
//                        .tabItem {
//                            Label("Settings", systemImage: "gearshape")
//                        }
//                        .tag(Tab.settings)
//                }
//
//                HStack {
//                    Text(
//                        !viewModel.serviceVersion.isEmpty
//                            ? "Ollama v\(viewModel.serviceVersion)" : ""
//                    )
//                    .foregroundColor(.primary)
//                    .padding([.leading, .bottom], 16)
//                    Spacer()
//                    Text(
//                        viewModel.servicePID != nil
//                            ? "PID: \(String(viewModel.servicePID!))"
//                            : ""
//                    )
//                    .foregroundColor(.primary)
//                    .padding([.trailing, .bottom], 16)
//                }
//            }
//        }
//    }
//}
//
//struct ModelView: View {
//    @ObservedObject var viewModel: LocalLLManagerViewModel
//    var body: some View {
//        ZStack {
//            Rectangle()
//                .fill(.regularMaterial)
//                .cornerRadius(20)
//                .shadow(radius: 10)
//                .padding([.leading, .bottom, .trailing], 16)
//
//            VStack {
//                HStack {
//                    Text("Available Models")
//                        .font(Font.headline)
//                        .foregroundColor(.primary)
//                        .padding(.leading, 16)
//                    Spacer()
//                    ZStack {
//                        Image(systemName: "plus")
//                            .bold()
//                            .foregroundColor(.accent)
//                            .padding(.trailing, 8)
//                    }
//                    .contentShape(Circle())
//                    .onTapGesture {
//                        Task {
//                            await viewModel.getLocalModels()
//                        }
//                    }
//                    ZStack {
//                        Image(systemName: "arrow.clockwise")
//                            .bold()
//                            .foregroundColor(.accent)
//                            .padding(.trailing, 16)
//                    }
//                    .contentShape(Circle())
//                    .onTapGesture {
//                        Task {
//                            await viewModel.getLocalModels()
//                        }
//                    }
//                }
//                .padding(.top, 16)
//                Table(viewModel.localModels) {
//                    let isLoading = viewModel.isLoading
//                    TableColumn("") { model in
//
//                        Button(action: {
//                            if viewModel.isServiceRunning {
//                                viewModel.stopModel(modelName: model.name)
//                            } else {
//                                viewModel.startModel(modelName: model.name)
//                            }
//                        }) {
//                            Group {
//                                if isLoading {
//                                    ProgressView()
//                                        .scaleEffect(0.5)
//                                } else {
//                                    Image(
//                                        systemName: model.isRunning
//                                            ? "stop.fill" : "play.fill"
//                                    )
//                                    .foregroundColor(
//                                        model.isRunning ? .gray : .green
//                                    )
//                                }
//                            }
//                        }
//                        .buttonStyle(PlainButtonStyle())
//                        .font(.system(size: 12))
//                    }
//                    .width(ideal: 16, max: 16)
//
//                    TableColumn("Name", value: \.name)
//                        .width(ideal: 128, max: .infinity)
//                    TableColumn("ID", value: \.identifier)
//                        .width(ideal: 96, max: .infinity)
//                    TableColumn("Size", value: \.sizePacked)
//                        .width(ideal: 48, max: .infinity)
//                    TableColumn("Modified", value: \.modified)
//                        .width(ideal: 96, max: .infinity)
//                    TableColumn("Processor", value: \.processor)
//                        .width(ideal: 96, max: .infinity)
//                    TableColumn("Until", value: \.until)
//                        .width(ideal: 96, max: .infinity)
//                    TableColumn("") { model in
//                        Button(action: {
//
//                            viewModel.removeModel(modelName: model.name)
//                        }) {
//                            Image(systemName: "delete.left.fill")
//                                .foregroundColor(.red)
//                        }
//                        .buttonStyle(PlainButtonStyle())
//                        .font(.system(size: 12))
//                    }
//                    .width(ideal: 16, max: .infinity)
//
//                }
//                .clipShape(RoundedRectangle(cornerRadius: 8))
//                .padding([.leading, .bottom, .trailing], 16)
//
//                if viewModel.isLoading {
//                    ProgressView("Loading...")
//                }
//            }
//            .onAppear {
//                Task {
//                    await viewModel.getLocalModels()
//                }
//            }
//            .padding([.leading, .trailing, .bottom], 16)
//        }
//    }
//}
//
//struct DownloadsView: View {
//    @ObservedObject var viewModel: LocalLLManagerViewModel
//    var body: some View {
//        VStack {
//            Text("Downloads Tab")
//                .font(.largeTitle)
//            // Additional content can go here
//        }
//    }
//}
//
//struct SettingsView: View {
//    @ObservedObject var viewModel: LocalLLManagerViewModel
//    var body: some View {
//        VStack {
//            Text("Settings Tab")
//                .font(.largeTitle)
//            // Additional content can go here
//        }
//    }
//}
//
#Preview {
    ContentView()
}

//
//  ContentView.swift
//  local-llmanager
//
//  Created by Dominic McRae on 22/04/2025. // Update Date if needed
//

struct ContentView: View {
    // Create and hold the single instance of the ViewModel for this view hierarchy
    @StateObject private var viewModel = LocalLLManagerViewModel()
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    .accent,
                    colorScheme == .dark ? .black : .white,
                ]),
                startPoint: .top,
                endPoint: .bottom
            ).ignoresSafeArea(edges: .all)
                .opacity(0.1)

            VStack(alignment: .leading, spacing: 0) {  // Use spacing 0 and add padding manually for control
                // MARK: - Service Status Header
                ServiceStatusHeader(viewModel: viewModel)
                    .padding([.horizontal, .top])  // Padding around the header

                //                Divider()

                // MARK: - Model List
                ModelListView(viewModel: viewModel)

                // MARK: - Footer (Optional - maybe version info again or status bar)
                FooterView(viewModel: viewModel)
                    .padding([.horizontal, .bottom])

            }
            // Apply alert modifier at the top level
            .alert(
                "Error",
                isPresented: $viewModel.showingErrorAlert,
                actions: {
                    Button("OK", role: .cancel) {
                        viewModel.errorMessage = nil  // Clear the error message when dismissed
                    }
                },
                message: {
                    Text(viewModel.errorMessage ?? "An unknown error occurred.")
                }
            )
            // Set a frame for the window if desired (especially for macOS)
            .frame(
                minWidth: 500,
                idealWidth: 600,
                minHeight: 400,
                idealHeight: 500
            )
        }
    }
}

// MARK: - Sub-Views for ContentView Structure

struct ServiceStatusHeader: View {
    @ObservedObject var viewModel: LocalLLManagerViewModel

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Local LLManager")
                    .font(Font.largeTitle.bold())
                    .foregroundColor(.accent)
                HStack {
                    Text(
                        viewModel.isServiceRunning
                            ? "Running (PID: \(String(viewModel.servicePID!)))"
                            : "Ollama Stopped"
                    )
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    Circle()
                        .fill(
                            viewModel.isServiceRunning ? Color.green : Color.red
                        )
                        .frame(width: 6, height: 6)
                }
                Text("Version: \(viewModel.serviceVersion)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()  // Push buttons to the right

            // Loading Indicator for Service Actions
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(0.8)
                    .padding(.horizontal, 5)
            }

            // Start/Stop Button
            Button {
                Task {
                    if viewModel.isServiceRunning {
                        await viewModel.stopService()
                    } else {
                        await viewModel.startService()
                    }
                }
            } label: {
                Image(systemName: viewModel.isServiceRunning ? "stop" : "play"
                                              )
                Text(
                    viewModel.isServiceRunning
                        ? "Stop Service" : "Start Service"
                )
            }
            .disabled(viewModel.isLoading)  // Disable while start/stop is in progress

            // Manual Refresh Button
            Button {
                Task { await viewModel.manualRefresh() }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .help("Refresh Status and Models")
            .disabled(viewModel.isLoading || viewModel.isLoadingModels)  // Disable during any loading

        }
        .padding(.bottom)  // Padding below the header
    }
}

struct ModelListView: View {
    @ObservedObject var viewModel: LocalLLManagerViewModel

    var body: some View {
        ZStack {
//            Rectangle()
//                .fill(.regularMaterial)
//                .cornerRadius(20)
//                .shadow(radius: 10)
//                .padding([.top, .leading, .trailing, .bottom], 16)
            Group {  // Use Group to handle conditional content
                if !viewModel.isServiceRunning {
                    VStack {
                        Spacer()
                        Text("Ollama service is not running.")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("Start the service to manage models.")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)  // Expand to fill space

                } else if viewModel.isLoadingModels
                    && viewModel.displayModels.isEmpty
                {
                    // Show loading indicator only if initially loading and list is empty
                    VStack {
                        Spacer()
                        ProgressView("Loading Models...")
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                } else if viewModel.displayModels.isEmpty {
                    // Service is running, not loading, but list is empty
                    VStack {
                        Spacer()
                        Text("No local models found.")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text(
                            "Pull models using 'ollama pull <model_name>' in your terminal."
                        )
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        .multilineTextAlignment(.center)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                } else {
                    // Display the list of models
                    List {
                        // Section Header with Loading Indicator
                        Section {
                            ForEach(viewModel.displayModels) { model in
                                ModelTableView(
                                    viewModel: viewModel,
                                    model: model
                                )
                            }
                        } header: {
                            HStack {
                                Text(
                                    "Available Models (\(viewModel.displayModels.count))"
                                )
                                Spacer()
                                if viewModel.isLoadingModels {
                                    ProgressView().scaleEffect(0.5)  // Small indicator for background refresh
                                }
                            }
                        }
                    }
                    // Use .listStyle(.inset) or .plain based on preference (macOS/iOS)
//                    .listStyle(.inset(alternatesRowBackgrounds: true))  // Good default for macOS
//                    .background(Color.clear)
//                    .scrollContentBackground(.hidden)
                    .refreshable {  // Works on iOS 15+, macOS 12+
                        print("List refresh triggered")
                        await viewModel.manualRefresh()
                    }
                }
            }
        }
    }
}

struct FooterView: View {
    @ObservedObject var viewModel: LocalLLManagerViewModel

    var body: some View {
        HStack {
            if let lastRefresh = viewModel.lastRefresh {
                Text("Last Refresh: ") + Text(lastRefresh, style: .time)
            } else {
                Text("Last Refresh: N/A")
            }
            Spacer()
            if viewModel.errorMessage != nil {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                    .help(viewModel.errorMessage!)
            }
        }
        .padding(.top, 12)
        .font(.caption)
        .foregroundColor(.gray)
    }
}

// MARK: - Preview

//#if DEBUG
//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//         // Create mock data for preview
//        let mockViewModel = LocalLLManagerViewModel()
//        let runningModel = DisplayModelItem(
//            id: UUID(uuidString: "550e8400-e29b-41d4-a716-446655440000")!,
//              name: "llama3:latest",
//              identifier: "abc123def456",
//              sizePacked: "4.1 GB",
//              sizeUnpacked: "8.2 GB",
//              processor: "Q4_K_M",
//              until: "in 5 minutes",
//              modified: "2 days ago",
//              isRunning: true
//         )
//         let stoppedModel = DisplayModelItem(
//              id: UUID(uuidString: "550e8400-e29b-41d4-a716-446655440000")!,
//              name: "mistral:7b",
//              identifier: "ghi789jkl012",
//              sizePacked: "3.8 GB",
//              sizeUnpacked: "N/A",
//              processor: "N/A",
//              until: "Not Loaded",
//              modified: "1 week ago",
//              isRunning: false
//         )
//
//         // --- Preview Scenarios ---
//
//         // 1. Service Running with Models
//          let runningViewModel = LocalLLManagerViewModel()
//         runningViewModel.isServiceRunning = true
//         runningViewModel.servicePID = 12345
//         runningViewModel.serviceVersion = "0.1.30"
//         runningViewModel.displayModels = [runningModel, stoppedModel] // Manually set display models for preview
//
//         ContentView()
//              .environmentObject(runningViewModel) // Inject if needed by subviews, though direct passing is used here
//              .previewDisplayName("Service Running")
//
//
//         // 2. Service Stopped
//         let stoppedViewModel = LocalLLManagerViewModel()
//         stoppedViewModel.isServiceRunning = false
//         stoppedViewModel.serviceVersion = "N/A"
//
//         ContentView()
//              .environmentObject(stoppedViewModel)
//              .previewDisplayName("Service Stopped")
//
//
//         // 3. Loading Models
//         let loadingViewModel = LocalLLManagerViewModel()
//         loadingViewModel.isServiceRunning = true
//         loadingViewModel.servicePID = 12345
//         loadingViewModel.serviceVersion = "0.1.30"
//         loadingViewModel.isLoadingModels = true // Simulate loading
//
//         ContentView()
//              .environmentObject(loadingViewModel)
//              .previewDisplayName("Loading Models")
//
//
//          // 4. Service Running, No Models
//           let noModelsViewModel = LocalLLManagerViewModel()
//          noModelsViewModel.isServiceRunning = true
//          noModelsViewModel.servicePID = 12345
//          noModelsViewModel.serviceVersion = "0.1.30"
//          noModelsViewModel.displayModels = [] // Empty list
//
//          ContentView()
//               .environmentObject(noModelsViewModel)
//               .previewDisplayName("Running - No Models")
//
//          // 5. Error State
//           let errorViewModel = LocalLLManagerViewModel()
//           errorViewModel.isServiceRunning = true // Or false
//           errorViewModel.errorMessage = "API Error: Failed to connect to localhost:11434"
//
//            ContentView()
//                .environmentObject(errorViewModel)
//                .previewDisplayName("Error State")
//
//
//    }
//}
//#endif
