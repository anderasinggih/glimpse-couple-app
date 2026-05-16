import SwiftUI
import PhotosUI

struct KabarPanel: View {
    @State private var statusText: String = ""
    @State private var isUploading = false
    @State private var showCamera = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Label("KABAR", systemImage: "bubble.left.and.exclamationmark.bubble.right.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(statusText.count)/140")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(statusText.count > 130 ? .red : .secondary)
            }
            
            // Input Area
            HStack(spacing: 12) {
                TextField("Apa kabarmu?", text: $statusText, axis: .vertical)
                    .lineLimit(1...3)
                    .padding(14)
                    .background(.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .onChange(of: statusText) { _, newValue in
                        if newValue.count > 140 {
                            statusText = String(newValue.prefix(140))
                        }
                    }
                
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    // Logic to send status would go here
                    statusText = ""
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.white)
                        .frame(width: 48, height: 48)
                        .background(
                            LinearGradient(colors: [Color.electricPurple, Color.activeCyan], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .clipShape(Circle())
                        .shadow(color: .electricPurple.opacity(0.3), radius: 10)
                }
                .disabled(statusText.isEmpty)
            }
            
            // Native-feel Flash Button
            Button {
                showCamera = true
            } label: {
                HStack(spacing: 12) {
                    if isUploading {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "camera.shutter.button.fill")
                            .symbolRenderingMode(.hierarchical)
                        Text("Capture Flash Moment")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.electricPurple)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.electricPurple.opacity(0.2), radius: 15, y: 5)
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.1), lineWidth: 0.5)
        )
        .sheet(isPresented: $showCamera) {
            CameraPlaceholderView(isUploading: $isUploading)
        }
    }
}

// Simple placeholder for camera implementation
struct CameraPlaceholderView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var isUploading: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Camera Interface")
                .font(.headline)
            
            Button("Simulate Capture & Compress") {
                simulateCapture()
            }
            .buttonStyle(.borderedProminent)
            
            Button("Cancel") { dismiss() }
        }
    }
    
    private func simulateCapture() {
        isUploading = true
        dismiss()
        
        // Simulate background compression and upload
        DispatchQueue.global(qos: .userInitiated).async {
            // Mock image
            let mockImage = UIImage(systemName: "heart.fill")!
            if let data = ImageProcessor.compressForGlimpse(image: mockImage) {
                print("Compressed data size: \(data.count / 1024) KB")
            }
            
            DispatchQueue.main.async {
                isUploading = false
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }
}

#Preview {
    ZStack {
        Color.deepVelvet.ignoresSafeArea()
        KabarPanel()
            .padding()
    }
}
