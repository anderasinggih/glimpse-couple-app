import SwiftUI
import PhotosUI

struct KabarPanel: View {
    @State private var statusText: String = ""
    @State private var isUploading = false
    @State private var showCamera = false
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("KABAR")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(statusText.count)/140")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(statusText.count > 130 ? .red : .secondary)
            }
            
            HStack(spacing: 10) {
                TextField("Apa kabarmu?", text: $statusText)
                    .padding(10)
                    .font(.system(size: 14))
                    .background(Color.adaptiveBackground.opacity(0.5))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.secondary.opacity(0.15)))
                    .onChange(of: statusText) { oldValue, newValue in
                        if newValue.count > 140 {
                            statusText = String(newValue.prefix(140))
                        }
                    }
                
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.adaptiveAccent)
                        .clipShape(Circle())
                }
                .disabled(statusText.isEmpty)
            }
            
            Button {
                showCamera = true
            } label: {
                HStack {
                    if isUploading {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "camera.shutter.button.fill")
                            .font(.system(size: 14))
                        Text("Flash Photo")
                            .font(.system(size: 14, weight: .bold))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(colors: [.electricPurple, .royalPurple], startPoint: .leading, endPoint: .trailing)
                )
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(color: .electricPurple.opacity(0.2), radius: 8, y: 4)
            }
        }
        .padding(16)
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
