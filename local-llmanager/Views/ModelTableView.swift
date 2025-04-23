//
//  ModelTableView.swift
//  local-llmanager
//
//  Created by Dominic McRae on 22/04/2025. // Update Date if needed
//

import SwiftUI

struct ModelTableView: View {
    // Use ObservedObject if the ViewModel might change *during* the lifetime of this row
    // Or pass closures for actions if preferred to decouple further
    @ObservedObject var viewModel: LocalLLManagerViewModel
    @Environment(\.colorScheme) var colorScheme
    let model: DisplayModelItem

    // State for confirmation dialogs
    @State private var showingStopConfirm = false
    @State private var showingRemoveConfirm = false

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(model.name)
                    .font(.headline)
                Text("ID: \(model.identifier)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Size: \(model.sizePacked) (Packed)")
                    .font(.caption)
                if model.isRunning {
                    Text("Size: \(model.sizeUnpacked) (Running)")
                        .font(.caption)
                }
                Text("Modified: \(model.modified)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                HStack {
                    Text(model.isRunning ? "Running" : "Stopped")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.primary)
                    Circle()
                        .fill(model.isRunning ? .green : .orange)
                        .frame(width: 8, height: 8)
                }
                if model.isRunning {
                    Text("Kept until: \(model.until)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Quantization: \(model.processor)")  // Example detail
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Action Buttons
                HStack {
                    if model.isRunning {
                        Button {
                            showingStopConfirm = true
                        } label: {
                            Image(systemName: "stop.circle.fill")
                                .foregroundColor(.orange)
                            Text("Stop")
                        }
//                        .buttonStyle(.plain)
                        .buttonStyle(.bordered)
                        .help("Stop Model")
                        .confirmationDialog(
                            "Stop \(model.name)?",
                            isPresented: $showingStopConfirm,
                            titleVisibility: .visible
                        ) {
                            Button("Stop Model", role: .destructive) {
                                Task {
                                    try await viewModel.stopModel(
                                        modelName: model.name
                                    )
                                }
                            }
                            Button("Cancel", role: .cancel) {}
                        }

                    } else {
                        Button {
                            // Consider adding options for keepAlive here later
                            Task {
                                try await viewModel.startModel(
                                    modelName: model.name,
                                    keepAlive: "5m"
                                )
                            }
                        } label: {
                            Image(systemName: "play.circle.fill")
                                .foregroundColor(.green)
                            Text("Start")
                        }
                        .buttonStyle(.bordered)
                        .help("Start Model")
                    }

                    Button {
                        showingRemoveConfirm = true
                    } label: {
                        Image(systemName: "trash.circle.fill")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.bordered)
                    .tint(.secondary)
                    .help("Remove Model")
                    .disabled(model.isRunning)
                    .confirmationDialog(
                        "Remove \(model.name)? This cannot be undone.",
                        isPresented: $showingRemoveConfirm,
                        titleVisibility: .visible
                    ) {
                        Button("Remove Model", role: .destructive) {
                            Task {
                                await viewModel.removeModel(
                                    modelName: model.name
                                )
                            }
                        }
                        Button("Cancel", role: .cancel) {}
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#if DEBUG
    struct ModelRowView_Previews: PreviewProvider {
        static var previews: some View {
            let mockViewModel = LocalLLManagerViewModel()
            let runningModel = DisplayModelItem(
                id: "d41d8cd98f00b204e9800998ecf8427e",
                name: "llama3:latest",
                identifier: "abc123def456",
                sizePacked: "4.1 GB",
                sizeUnpacked: "8.2 GB",
                processor: "Q4_K_M",
                until: "in 5 minutes",
                modified: "2 days ago",
                isRunning: true
            )
            let stoppedModel = DisplayModelItem(
                id: "9e107d9d372bb6826bd81d3542a419d6",
                name: "mistral:7b",
                identifier: "ghi789jkl012",
                sizePacked: "3.8 GB",
                sizeUnpacked: "N/A",
                processor: "N/A",
                until: "Not Loaded",
                modified: "1 week ago",
                isRunning: false
            )

            List {
                ModelTableView(viewModel: mockViewModel, model: runningModel)
                ModelTableView(viewModel: mockViewModel, model: stoppedModel)
            }
            .environmentObject(mockViewModel)
            .previewLayout(.sizeThatFits)

            ModelTableView(viewModel: mockViewModel, model: runningModel)
                .previewDisplayName("Running Row")
                .padding()

            ModelTableView(viewModel: mockViewModel, model: stoppedModel)
                .previewDisplayName("Stopped Row")
                .padding()
        }
    }
#endif
