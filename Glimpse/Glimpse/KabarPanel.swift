import SwiftUI
import PhotosUI

struct KabarPanel: View {
    @State private var statusText: String = ""
    @State private var isUploading = false
    @State private var showCamera = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Header (Compact)
            HStack {
                Label("KABAR", systemImage: "sparkles")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.electricPurple)
                Spacer()
                Text("\(statusText.count)/140")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(statusText.count > 130 ? .red : .secondary)
            }
            
            // Compact Input Area
            HStack(spacing: 10) {
                TextField("Apa kabarmu?", text: $statusText)
                    .font(.system(size: 13))
                    .padding(10)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .onChange(of: statusText) { _, newValue in
                        if newValue.count > 140 { statusText = String(newValue.prefix(140)) }
                    }
                
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    statusText = ""
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.white)
                        .frame(width: 36, height: 36)
                        .background(Color.electricPurple)
                        .clipShape(Circle())
                }
                .disabled(statusText.isEmpty)
            }
            
            // Glass Flash Button (Compact)
            Button {
                showCamera = true
            } label: {
                HStack(spacing: 8) {
                    if isUploading {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 12))
                        Text("Flash Moment")
                            .font(.system(size: 13, weight: .bold))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(colors: [Color.electricPurple, Color.royalPurple], startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: Color.electricPurple.opacity(0.2), radius: 8, y: 4)
            }
        }
        .padding(14)
        .glassmorphic()
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
