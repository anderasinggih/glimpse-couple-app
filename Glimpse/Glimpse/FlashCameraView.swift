import SwiftUI
import AVFoundation
import CoreLocation
import AudioToolbox

struct FlashCameraView: View {
    @State private var model = GlimpseCameraModel()
    @State private var capturedImage: UIImage?
    @State private var statusNote: String = ""
    @State private var isUploading = false
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var isShowingError = false
    @State private var isUploadSuccess = false
    @State private var auth = AuthManager.shared
    @Environment(\.dismiss) var dismiss
    
    @FocusState private var isInputFocused: Bool
    
    @State private var activeHintIndex = 0
    @State private var hintTimer: Timer? = nil
    
    private let cameraHints = [
        "Smile for your favorite person... 😊",
        "Send a Glimpse to your partner... 💖",
        "Capture this sweet moment... 📸",
        "Let them see your beautiful smile... ✨",
        "Thinking of you right now... 💭"
    ]
    
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
            .ignoresSafeArea()
            .ignoresSafeArea(.keyboard)
            .onTapGesture {
                isInputFocused = false
            }
            
            if capturedImage == nil {
                // --- CAMERA TAKING MODE ---
                VStack(spacing: 0) {
                    headerSection
                        .padding(.top, 10)
                        .zIndex(10)
                    
                    Spacer()
                    
                    // Camera Preview Frame
                    ZStack {
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
                    .frame(width: frameSize, height: frameSize)
                    .background(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(LinearGradient(colors: [.white.opacity(0.2), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5)
                    )
                    .shadow(color: .electricPurple.opacity(0.2), radius: 30)
                    
                    // Rotating modern intimate camera hints
                    Text(cameraHints[activeHintIndex])
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .id(activeHintIndex)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .bottom)),
                            removal: .opacity.combined(with: .move(edge: .top))
                        ))
                    
                    Spacer()
                    
                    // Camera Footer (Find Partner info or Capture Button)
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
                        .padding(.bottom, 40)
                    } else {
                        captureButton
                            .padding(.bottom, 40)
                    }
                }
            } else if let image = capturedImage {
                // --- POST-CAPTURE EDIT & UPLOAD MODE ---
                ScrollView(showsIndicators: false) {
                    ScrollViewReader { proxy in
                        VStack(spacing: 24) {
                            Spacer().frame(height: 20)
                            
                            // Compact Preview Photo (scaled to 260x260 to fit screen beautifully)
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 260, height: 260)
                                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                                        .stroke(LinearGradient(colors: [.white.opacity(0.3), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5)
                                )
                                .shadow(color: .electricPurple.opacity(0.3), radius: 15)
                                .padding(.top, 10)
                            
                            Text("Add a caption to your Glimpse")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            // Captioned note text input - INLINED FOR 100% FOCUS ACCURACY
                            VStack(alignment: .trailing, spacing: 6) {
                                TextField("Add a note...", text: $statusNote)
                                    .focused($isInputFocused)
                                    .submitLabel(.send)
                                    .onSubmit {
                                        if !isUploading {
                                            uploadPhoto(image)
                                        }
                                    }
                                    .padding(16)
                                    .background(.ultraThinMaterial)
                                    .cornerRadius(18)
                                    .foregroundColor(.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                                    .onChange(of: statusNote) { oldValue, newValue in
                                        if newValue.count > 30 {
                                            statusNote = String(newValue.prefix(30))
                                        }
                                    }
                                
                                Text("\(statusNote.count)/30")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(statusNote.count > 25 ? .red : .white.opacity(0.5))
                                    .padding(.horizontal, 8)
                            }
                            .padding(.horizontal, 30)
                            .id("glimpse-input-field")
                            
                            // Send & Retake Actions
                            VStack(spacing: 12) {
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
                                .id("send-button")
                                
                                Button {
                                    capturedImage = nil
                                    statusNote = ""
                                    model.startSession()
                                } label: {
                                    Text("Retake Photo")
                                        .font(.subheadline.bold())
                                        .foregroundColor(.white.opacity(0.6))
                                        .padding(.vertical, 8)
                                }
                            }
                            
                            Spacer().frame(height: 30)
                        }
                        .contentShape(Rectangle()) // Make the entire VStack body tappable to dismiss keyboard
                        .onTapGesture {
                            isInputFocused = false
                        }
                        .onChange(of: isInputFocused) { oldValue, newValue in
                            if newValue {
                                // AUTO-SCROLL to send button with a tiny delay to wait for keyboard height calculation
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                    withAnimation(.easeOut(duration: 0.35)) {
                                        proxy.scrollTo("send-button", anchor: .bottom)
                                    }
                                }
                            }
                        }
                    }
                }
                .ignoresSafeArea(.keyboard, edges: .bottom)
            }
            
            if isUploadSuccess {
                ZStack {
                    Color.black.opacity(0.65)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 24) {
                        ZStack {
                            Circle()
                                .fill(Color.vividMint.opacity(0.12))
                                .frame(width: 120, height: 120)
                            
                            Circle()
                                .stroke(Color.vividMint, lineWidth: 3)
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.vividMint)
                        }
                        
                        VStack(spacing: 8) {
                            Text("Flash Shared!")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("Sent to your partner")
                                .font(.system(size: 15))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .padding(32)
                    .background(.ultraThinMaterial)
                    .cornerRadius(28)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 20, y: 10)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .zIndex(999)
            }
        }
        .onAppear {
            UIDevice.current.isBatteryMonitoringEnabled = true
            model.startSession()
            startHintTimer()
        }
        .onDisappear {
            model.stopSession()
            stopHintTimer()
        }
        .onChange(of: capturedImage) { oldValue, newValue in
            if newValue != nil {
                // AUTO-FOCUS note input field with a tiny transition delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isInputFocused = true
                }
            }
        }
        .alert("Upload Failed", isPresented: $isShowingError) {
            Button("OK", role: .cancel) { }
        } message: {
            if let msg = errorMessage { Text(msg) }
        }
    }
    
    private var headerSection: some View {
        ZStack {
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
    
    private var captureButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            isProcessing = true
            model.capturePhoto { image in
                model.stopSession()
                
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
            
            // PERFORM REVERSE GEOCODING WITH A STRICT 1.0 SECOND TIMEOUT
            if let lat = lat, let lon = lon {
                let location = CLLocation(latitude: lat, longitude: lon)
                let geocoder = CLGeocoder()
                
                address = await withTaskGroup(of: String?.self) { group in
                    // Group task 1: Geocoding
                    group.addTask {
                        do {
                            let placemarks = try await geocoder.reverseGeocodeLocation(location)
                            if let placemark = placemarks.first {
                                let street = placemark.thoroughfare ?? ""
                                let subLoc = placemark.subLocality ?? placemark.locality ?? ""
                                if !street.isEmpty && !subLoc.isEmpty {
                                    return "\(street), \(subLoc)"
                                } else {
                                    return street.isEmpty ? subLoc : street
                                }
                            }
                        } catch {
                            print("Geocoding failed/canceled: \(error)")
                        }
                        return nil
                    }
                    
                    // Group task 2: Strict Timeout (1.0 second)
                    group.addTask {
                        try? await Task.sleep(nanoseconds: 1_000_000_000)
                        geocoder.cancelGeocode()
                        return nil
                    }
                    
                    // Race and pick the first completed result
                    if let result = await group.next() {
                        group.cancelAll()
                        return result
                    }
                    return nil
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
                
                // SUCCESS MICRO-INTERACTION: Haptics, Sound, & Animation
                await MainActor.run {
                    // 1. Play signature "Sent" system sound (1004)
                    AudioServicesPlaySystemSound(1004)
                    
                    // 2. Play signature success haptic vibration
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    
                    // 3. Trigger full-screen success animation state
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                        isUploadSuccess = true
                    }
                }
                
                // 4. Delay for 1.5 seconds to let the user enjoy the gorgeous success state!
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                
                await MainActor.run {
                    capturedImage = nil
                    statusNote = ""
                    isUploadSuccess = false
                    dismiss() // Close camera after success
                }
            } catch {
                print("Upload failed: \(error)")
                errorMessage = error.localizedDescription
                isShowingError = true
            }
            isUploading = false
        }
    }
    
    private func startHintTimer() {
        hintTimer?.invalidate()
        hintTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { _ in
            withAnimation {
                activeHintIndex = (activeHintIndex + 1) % cameraHints.count
            }
        }
    }
    
    private func stopHintTimer() {
        hintTimer?.invalidate()
        hintTimer = nil
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
                    if newValue.count > 30 {
                        text = String(newValue.prefix(30))
                    }
                }
            
            Text("\(text.count)/30")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(text.count > 25 ? .red : .white.opacity(0.5))
                .padding(.horizontal, 8)
        }
        .padding(.horizontal, 30)
    }
}
