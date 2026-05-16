import SwiftUI
import AVFoundation

struct FlashCameraView: View {
    @State private var model = GlimpseCameraModel()
    @State private var capturedImage: UIImage?
    @State private var isUploading = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let frameSize = screenWidth - 25
            
            ZStack {
                // LAYER 1: Background
                Color.deepVelvet.ignoresSafeArea()
                iOS26Background().opacity(0.4)
                
                // LAYER 2: The Camera Frame (Absolute Center)
                ZStack {
                    if model.permissionStatus == .authorized {
                        if model.isInitialized {
                            CameraPreview(session: model.session)
                                .aspectRatio(1, contentMode: .fill)
                                .opacity(capturedImage == nil ? 1 : 0)
                            
                            if let image = capturedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            }
                        } else {
                            loadingFrame(size: screenWidth - 32)
                        }
                    } else {
                        permissionView(size: screenWidth - 32)
                    }
                }
                .aspectRatio(1, contentMode: .fit)
                .background(Color.black)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(LinearGradient(colors: [.white.opacity(0.2), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5)
                )
                .shadow(color: .electricPurple.opacity(0.2), radius: 30)
                .padding(.horizontal, 16)
                .offset(y: -10)
                
                // LAYER 3: UI Overlays
                headerSection
                    .zIndex(10)
                    .frame(maxHeight: .infinity, alignment: .top)
                
                VStack {
                    Spacer()
                    footerSection
                        .padding(.bottom, 20)
                }
            }
        }
    }
    
    private var headerSection: some View {
        ZStack {
            BrandingHeader()
            
            HStack {
                Spacer()
                Button { model.switchCamera() } label: {
                    Image(systemName: "camera.rotate")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .padding(.trailing, 20)
            }
        }
    }
    
    private func loadingFrame(size: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 28)
            .fill(Color.white.opacity(0.05))
            .frame(width: size, height: size)
            .overlay(ProgressView().tint(.white))
    }
    
    private func permissionView(size: CGFloat) -> some View {
        VStack(spacing: 15) {
            Image(systemName: "camera.fill").font(.title).foregroundColor(.electricPurple)
            Text("Camera Access").font(.headline).foregroundColor(.white)
            Button("Allow") { model.checkPermissions() }
                .padding(.horizontal, 25).padding(.vertical, 10)
                .background(Color.electricPurple).foregroundColor(.deepVelvet).cornerRadius(10)
        }
    }
    
    private var footerSection: some View {
        Group {
            if capturedImage == nil && model.permissionStatus == .authorized {
                captureButton
            } else if let image = capturedImage {
                actionButtons(image)
            }
        }
    }
    
    private var captureButton: some View {
        Button {
            model.capturePhoto { image in
                // Process and crop the image
                self.capturedImage = processCapturedImage(image)
            }
        } label: {
            ZStack {
                Circle().stroke(Color.white.opacity(0.3), lineWidth: 4).frame(width: 85, height: 85)
                Circle().fill(Color.white).frame(width: 70, height: 70)
            }
        }
    }
    
    private func actionButtons(_ image: UIImage) -> some View {
        VStack(spacing: 15) {
            Button {
                uploadPhoto(image)
            } label: {
                Text("Send to Partner")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.electricPurple)
                    .foregroundColor(.deepVelvet)
                    .cornerRadius(18)
                    .padding(.horizontal, 30)
            }
            .disabled(isUploading)
            
            Button { capturedImage = nil } label: {
                Text("Retake Photo").font(.subheadline.bold()).foregroundColor(.white.opacity(0.6))
            }
        }
    }
    
    // NEW: Robust image processing (Crop + Mirror check)
    private func processCapturedImage(_ image: UIImage?) -> UIImage? {
        guard let image = image else { return nil }
        
        // 1. Flip if it's the front camera to match the preview
        var finalImage = image
        if model.isUsingFrontCamera {
            if let cgImage = image.cgImage {
                finalImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: .leftMirrored)
            }
        }
        
        // 2. Crop to Square
        let imageSize = finalImage.size
        let side = min(imageSize.width, imageSize.height)
        let x = (imageSize.width - side) / 2
        let y = (imageSize.height - side) / 2
        let cropRect = CGRect(x: x, y: y, width: side, height: side)
        
        guard let cgImage = finalImage.cgImage?.cropping(to: cropRect) else { return finalImage }
        return UIImage(cgImage: cgImage, scale: finalImage.scale, orientation: finalImage.imageOrientation)
    }
    
    private func uploadPhoto(_ image: UIImage) {
        isUploading = true
        Task {
            do {
                try await AuthManager.shared.uploadPhoto(image)
                capturedImage = nil
            } catch {
                print("Upload failed: \(error)")
            }
            isUploading = false
        }
    }
}

@Observable
class GlimpseCameraModel: NSObject, AVCapturePhotoCaptureDelegate {
    var session = AVCaptureSession()
    var isInitialized = false
    var permissionStatus: AVAuthorizationStatus = .notDetermined
    var isUsingFrontCamera = true // Tracking for flipping logic
    
    private let output = AVCapturePhotoOutput()
    private var completion: ((UIImage?) -> Void)?
    private let sessionQueue = DispatchQueue(label: "com.glimpse.camera.sessionQueue")
    
    override init() {
        super.init()
        permissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
        if permissionStatus == .authorized { setupCamera() }
    }
    
    func checkPermissions() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                self.permissionStatus = granted ? .authorized : .denied
                if granted { self.setupCamera() }
            }
        }
    }
    
    private func setupCamera() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.session.beginConfiguration()
            self.session.sessionPreset = .photo
            
            let discoverySession = AVCaptureDevice.DiscoverySession(
                deviceTypes: [.builtInWideAngleCamera],
                mediaType: .video,
                position: .front
            )
            
            guard let device = discoverySession.devices.first,
                  let input = try? AVCaptureDeviceInput(device: device) else { return }
            
            if self.session.canAddInput(input) { self.session.addInput(input) }
            if self.session.canAddOutput(self.output) { self.session.addOutput(self.output) }
            
            self.session.commitConfiguration()
            self.session.startRunning()
            
            DispatchQueue.main.async { self.isInitialized = true }
        }
    }
    
    func switchCamera() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.session.beginConfiguration()
            guard let currentInput = self.session.inputs.first as? AVCaptureDeviceInput else { return }
            self.session.removeInput(currentInput)
            
            let newPosition: AVCaptureDevice.Position = currentInput.device.position == .back ? .front : .back
            self.isUsingFrontCamera = (newPosition == .front)
            
            guard let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition),
                  let newInput = try? AVCaptureDeviceInput(device: newDevice) else { return }
            
            if self.session.canAddInput(newInput) { self.session.addInput(newInput) }
            self.session.commitConfiguration()
        }
    }
    
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        self.completion = completion
        let settings = AVCapturePhotoSettings()
        sessionQueue.async { self.output.capturePhoto(with: settings, delegate: self) }
    }
    
    @MainActor
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else {
            completion?(nil)
            return
        }
        DispatchQueue.main.async { self.completion?(image) }
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> PreviewContainerView {
        let view = PreviewContainerView()
        view.session = session
        return view
    }
    
    func updateUIView(_ uiView: PreviewContainerView, context: Context) {}
}

class PreviewContainerView: UIView {
    var session: AVCaptureSession? {
        get { previewLayer.session }
        set { previewLayer.session = newValue }
    }
    
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
    
    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayer()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayer()
    }
    
    private func setupLayer() {
        previewLayer.videoGravity = .resizeAspectFill
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds
    }
}
