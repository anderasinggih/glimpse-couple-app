import SwiftUI
import AVFoundation
import CoreLocation

struct FlashCameraView: View {
    @State private var model = GlimpseCameraModel()
    @State private var capturedImage: UIImage?
    @State private var statusNote: String = ""
    @State private var isUploading = false
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var isShowingError = false
    @State private var auth = AuthManager.shared
    @Environment(\.dismiss) var dismiss
    
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        let screenWidth = UIScreen.main.bounds.width
        let frameSize = screenWidth - 25
        
        ZStack {
            // LAYER 1: Background - Fixated and Full Screen
            ZStack {
                Color.deepVelvet.ignoresSafeArea()
                iOS26Background().opacity(0.4)
            }
            .drawingGroup()
            .ignoresSafeArea() // Ensure it covers status bar and bottom area
            .ignoresSafeArea(.keyboard) 
            
            // LAYER 2: The Camera/Preview Frame
            VStack {
                Spacer()
                ZStack {
                    if let image = capturedImage {
                        // PREVIEW MODE: Only show the captured image (No Camera Logic here)
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: frameSize, height: frameSize)
                            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    } else {
                        // CAMERA MODE: Only show camera when no image is captured
                        if model.permissionStatus == .authorized {
                            if model.isInitialized {
                                CameraPreview(session: model.session)
                                    .frame(width: frameSize, height: frameSize)
                                
                                if isProcessing {
                                    ZStack {
                                        Color.black.opacity(0.4)
                                        ProgressView()
                                            .tint(.white)
                                            .scaleEffect(1.5)
                                    }
                                    .frame(width: frameSize, height: frameSize)
                                }
                            } else {
                                loadingFrame(size: frameSize)
                            }
                        } else {
                            permissionView(size: frameSize)
                        }
                    }
                }
                .frame(width: frameSize, height: frameSize)
                .background(Color.black)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(LinearGradient(colors: [.white.opacity(0.2), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5)
                )
                .shadow(color: .electricPurple.opacity(0.2), radius: 30)
                Spacer()
            }
            .frame(maxWidth: .infinity)
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
        .onAppear {
            UIDevice.current.isBatteryMonitoringEnabled = true
            model.startSession()
        }
        .onDisappear {
            model.stopSession()
        }
        .alert("Upload Failed", isPresented: $isShowingError) {
            Button("OK", role: .cancel) { }
        } message: {
            if let msg = errorMessage { Text(msg) }
        }
    }
    
    private var headerSection: some View {
        ZStack {
            // Master branding is now handled by MainDashboardView shell
            
            HStack(spacing: 12) {
                Spacer()
                
                // Flash Toggle
                Button { model.toggleFlash() } label: {
                    Image(systemName: model.flashMode == .on ? "bolt.fill" : "bolt.slash.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(model.flashMode == .on ? .yellow : .white)
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                
                // Camera Switch
                Button { model.switchCamera() } label: {
                    Image(systemName: "camera.rotate")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
            }
            .padding(.trailing, 20)
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
            if auth.partner == nil || !auth.coupleActive {
                VStack(spacing: 8) {
                    Image(systemName: "person.badge.plus")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.6))
                    Text("Find your partner first")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Connect in the Profile tab to send a Glimpse.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 20)
                .background(.ultraThinMaterial)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            } else if capturedImage == nil && model.permissionStatus == .authorized {
                captureButton
            } else if let image = capturedImage {
                actionButtons(image)
            }
        }
    }
    
    private var captureButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            isProcessing = true
            model.capturePhoto { image in
                // IMMEDIATELY stop camera hardware to free up resources for typing note
                model.stopSession()
                
                // Move heavy processing to background task to prevent lag
                Task.detached(priority: .userInitiated) {
                    let processed = await processCapturedImage(image)
                    await MainActor.run {
                        self.capturedImage = processed
                        self.isProcessing = false
                    }
                }
            }
        } label: {
            ZStack {
                Circle().stroke(Color.white.opacity(0.3), lineWidth: 4).frame(width: 85, height: 85)
                Circle().fill(Color.white).frame(width: 70, height: 70)
            }
        }
        .disabled(isProcessing)
    }
    
    private func actionButtons(_ image: UIImage) -> some View {
        VStack(spacing: 15) {
            // HIGH PERFORMANCE INPUT: Isolated with unique ID to prevent re-render diffing lag
            StatusInputView(text: $statusNote)
                .focused($isInputFocused)
                .id("glimpse-input-field")
            
            Button {
                uploadPhoto(image)
            } label: {
                if isUploading {
                    ProgressView().tint(.deepVelvet)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.electricPurple)
                        .cornerRadius(18)
                        .padding(.horizontal, 30)
                } else {
                    Text("Send Glimpse")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.electricPurple)
                        .foregroundColor(.deepVelvet)
                        .cornerRadius(18)
                        .padding(.horizontal, 30)
                }
            }
            .disabled(isUploading)
            
            Button { 
                capturedImage = nil 
                statusNote = ""
                // RESTART camera session when user cancels
                model.startSession()
            } label: {
                Text("Cancel").font(.subheadline.bold()).foregroundColor(.white.opacity(0.6))
            }
        }
    }
    
    // Process on background
    private func processCapturedImage(_ image: UIImage?) async -> UIImage? {
        guard let image = image else { return nil }
        
        // 1. Resize and Fix Orientation in one go using UIGraphicsImageRenderer
        // This flattens the image so orientation is always .up (Portrait)
        let maxDim: CGFloat = 1024
        let scale = maxDim / max(image.size.width, image.size.height)
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let processed = renderer.image { context in
            // If front camera, we need to mirror it manually during drawing
            if model.isUsingFrontCamera {
                context.cgContext.translateBy(x: newSize.width, y: 0)
                context.cgContext.scaleBy(x: -1, y: 1)
            }
            
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        
        // 2. Crop the flattened image (it's already upright and mirrored if needed)
        return await cropToSquare(processed)
    }
    
    private func cropToSquare(_ image: UIImage) async -> UIImage? {
        guard let cgImage = image.cgImage else { return image }
        
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        let side = min(width, height)
        
        let x = (width - side) / 2
        let y = (height - side) / 2
        let cropRect = CGRect(x: x, y: y, width: side, height: side)
        
        guard let croppedCgImage = cgImage.cropping(to: cropRect) else { return image }
        
        // No more metadata orientation needed because UIGraphicsImageRenderer flattened it to .up
        return UIImage(cgImage: croppedCgImage)
    }
    
    private func uploadPhoto(_ image: UIImage) {
        isUploading = true
        
        // Collect extra metadata
        let lat = model.lastLocation?.coordinate.latitude
        let lon = model.lastLocation?.coordinate.longitude
        let battery = Int(UIDevice.current.batteryLevel * 100)
        
        Task {
            var address: String? = nil
            
            // PERFORM REVERSE GEOCODING
            if let lat = lat, let lon = lon {
                let location = CLLocation(latitude: lat, longitude: lon)
                let geocoder = CLGeocoder()
                
                if let placemarks = try? await geocoder.reverseGeocodeLocation(location),
                   let placemark = placemarks.first {
                    // Combine street and sub-locality/city
                    let street = placemark.thoroughfare ?? ""
                    let subLoc = placemark.subLocality ?? placemark.locality ?? ""
                    
                    if !street.isEmpty && !subLoc.isEmpty {
                        address = "\(street), \(subLoc)"
                    } else {
                        address = street.isEmpty ? subLoc : street
                    }
                }
            }
            
            do {
                try await AuthManager.shared.uploadPhoto(
                    image, 
                    latitude: lat, 
                    longitude: lon, 
                    battery: battery, 
                    note: statusNote.isEmpty ? nil : statusNote,
                    locationName: address
                )
                capturedImage = nil
                statusNote = ""
                dismiss() // Close camera after success
            } catch {
                print("Upload failed: \(error)")
                errorMessage = error.localizedDescription
                isShowingError = true
            }
            isUploading = false
        }
    }
}

@Observable
class GlimpseCameraModel: NSObject, AVCapturePhotoCaptureDelegate, CLLocationManagerDelegate {
    var session = AVCaptureSession()
    var isInitialized = false
    var permissionStatus: AVAuthorizationStatus = .notDetermined
    var isUsingFrontCamera = true // Tracking for flipping logic
    
    var flashMode: AVCaptureDevice.FlashMode = .off
    
    // Location tracking
    private let locationManager = CLLocationManager()
    var lastLocation: CLLocation?
    
    private let output = AVCapturePhotoOutput()
    private var completion: ((UIImage?) -> Void)?
    private let sessionQueue = DispatchQueue(label: "com.glimpse.camera.sessionQueue")
    
    override init() {
        super.init()
        // DO NOTHING HERE - Keep it light to prevent startup lag
    }
    
    private func setupLocation() {
        if lastLocation == nil {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastLocation = locations.last
    }
    
    func checkPermissions() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                self.permissionStatus = granted ? .authorized : .denied
                if granted { self.startSession() }
            }
        }
    }
    
    func startSession() {
        // First access to permission and location happens here (LAZY)
        if self.permissionStatus == .notDetermined {
            self.permissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
        }
        self.setupLocation()
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.permissionStatus == .authorized {
                if !self.isInitialized {
                    self.setupCamera()
                }
                if !self.session.isRunning {
                    self.session.startRunning()
                }
            }
        }
    }
    
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
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
    
    func toggleFlash() {
        flashMode = (flashMode == .on) ? .off : .on
    }
    
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        self.completion = completion
        
        // Use default settings but optimized for instant capture
        let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        
        // 1. ABSOLUTE SPEED: Tell iOS to forget about quality and just snap NOW
        settings.photoQualityPrioritization = .speed
        
        // 2. DISABLE EXTRAS: No high-res, no HDR, no heavy processing
        if output.isHighResolutionCaptureEnabled {
            settings.isHighResolutionPhotoEnabled = false
        }
        
        // 3. FLASH SYNC
        if output.supportedFlashModes.contains(flashMode) {
            settings.flashMode = flashMode
        }
        
        sessionQueue.async {
            self.output.capturePhoto(with: settings, delegate: self)
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation() else {
            completion?(nil)
            return
        }
        
        // Decoding high-res image data on background thread to prevent Main Thread stutter
        Task.detached(priority: .userInitiated) {
            let image = UIImage(data: data)
            await MainActor.run {
                self.completion?(image)
            }
        }
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

// Separate component to isolate state updates and prevent lag
struct StatusInputView: View {
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 6) {
            TextField("Add a note...", text: $text)
                .padding(16)
                .background(.ultraThinMaterial)
                .cornerRadius(18)
                .foregroundColor(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .onChange(of: text) { oldValue, newValue in
                    if newValue.count > 140 {
                        text = String(newValue.prefix(140))
                    }
                }
            
            Text("\(text.count)/140")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(text.count > 130 ? .red : .white.opacity(0.5))
                .padding(.horizontal, 8)
        }
        .padding(.horizontal, 30)
    }
}
