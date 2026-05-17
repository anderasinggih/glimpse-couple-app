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
    @State private var isScreenFlashing = false
    @State private var animateCheckmark = false
    @State private var showNoInternetAlert = false
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
            // LAYER 1: Background - Fixated and Full Screen (Bright white screen flash filler ONLY during selfie snap!)
            ZStack {
                if isScreenFlashing {
                    Color.white.ignoresSafeArea()
                } else {
                    Color.deepVelvet.ignoresSafeArea()
                    iOS26Background().opacity(0.4)
                }
            }
            .animation(.easeInOut(duration: 0.15), value: isScreenFlashing)
            .ignoresSafeArea()
            .ignoresSafeArea(.keyboard)
            .onTapGesture {
                isInputFocused = false
            }
            
            if capturedImage == nil {
                // --- CAMERA TAKING MODE ---
                VStack(spacing: 0) {
                    Spacer().frame(height: 20)
                    
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
                    .shadow(color: Color.black.opacity(0.35), radius: 15, x: 0, y: 8)
                    
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
                        HStack(spacing: 36) {
                            // Flash Toggle
                            Button { model.toggleFlash() } label: {
                                Image(systemName: model.flashMode == .on ? "bolt.fill" : "bolt.slash.fill")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(model.flashMode == .on ? .yellow : .white)
                                    .frame(width: 50, height: 50)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle().stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                            }
                            
                            captureButton
                            
                            // Camera Switch
                            Button { model.switchCamera() } label: {
                                Image(systemName: "camera.rotate")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 50, height: 50)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle().stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                            }
                        }
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
                            
                            // Retake Photo Button placed high up for superb keyboard safety
                            Button {
                                capturedImage = nil
                                statusNote = ""
                                model.startSession()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .font(.system(size: 12, weight: .bold))
                                    Text("Retake Photo")
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                }
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(20)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Text("Add a caption to your Glimpse")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            // Captioned note text input & Send button side-by-side!
                            VStack(alignment: .trailing, spacing: 6) {
                                HStack(spacing: 12) {
                                    TextField("Add a note...", text: $statusNote)
                                        .focused($isInputFocused)
                                        .submitLabel(.send)
                                        .onSubmit {
                                            uploadPhoto(image)
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
                                    
                                    Button {
                                        uploadPhoto(image)
                                    } label: {
                                        Text("Send")
                                            .font(.system(size: 15, weight: .bold, design: .rounded))
                                            .foregroundColor(.deepVelvet)
                                            .padding(.horizontal, 24)
                                            .padding(.vertical, 16)
                                            .background(Color.electricPurple)
                                            .cornerRadius(18)
                                            .shadow(color: .electricPurple.opacity(0.3), radius: 8)
                                    }
                                }
                                
                                Text("\(statusNote.count)/30")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(statusNote.count > 25 ? .red : .white.opacity(0.5))
                                    .padding(.horizontal, 8)
                            }
                            .padding(.horizontal, 30)
                            .id("glimpse-input-field")
                            

                            
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
                                .scaleEffect(animateCheckmark ? 1.0 : 0.4)
                            
                            Circle()
                                .stroke(Color.vividMint, lineWidth: 3)
                                .frame(width: 80, height: 80)
                                .scaleEffect(animateCheckmark ? 1.0 : 0.6)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.vividMint)
                                .scaleEffect(animateCheckmark ? 1.0 : 0.2)
                                .rotationEffect(.degrees(animateCheckmark ? 0 : -45))
                        }
                        
                        VStack(spacing: 8) {
                            Text("Flash Shared!")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .opacity(animateCheckmark ? 1.0 : 0.0)
                                .offset(y: animateCheckmark ? 0 : 10)
                            
                            Text("Sent to your partner")
                                .font(.system(size: 15))
                                .foregroundColor(.white.opacity(0.6))
                                .opacity(animateCheckmark ? 1.0 : 0.0)
                                .offset(y: animateCheckmark ? 0 : 10)
                        }
                    }
                    .padding(32)
                    .background(.ultraThinMaterial)
                    .cornerRadius(28)
                    .scaleEffect(animateCheckmark ? 1.0 : 0.85)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 20, y: 10)
                }
                .transition(.opacity)
                .zIndex(999)
                .task {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.75, blendDuration: 0)) {
                        animateCheckmark = true
                    }
                }
                .onDisappear {
                    animateCheckmark = false
                }
            }
        }
        .alert("No Internet Connection", isPresented: $showNoInternetAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("No Internet Connection Failed. Please connect to the internet and try again.")
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
                // AUTO-FOCUS note input field with a tiny transition delay (100ms is visual instant!)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
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
    
    // Removed headerSection and placed camera controls in the bottom HStack next to shutter
    
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
            
            // Trigger quick screen flash if mode is ON!
            if model.flashMode == .on {
                withAnimation(.easeIn(duration: 0.05)) {
                    isScreenFlashing = true
                }
            }
            
            model.capturePhoto { image in
                model.stopSession()
                
                // Turn off screen flash after snap
                if model.flashMode == .on {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        withAnimation(.easeOut(duration: 0.15)) {
                            isScreenFlashing = false
                        }
                    }
                }
                
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
        // Collect extra metadata
        let lat = model.lastLocation?.coordinate.latitude
        let lon = model.lastLocation?.coordinate.longitude
        let battery = Int(UIDevice.current.batteryLevel * 100)
        let note = statusNote.isEmpty ? nil : statusNote
        
        // 1. Save to outbox queue immediately (secure local storage!)
        AuthManager.shared.savePendingFlash(image: image, latitude: lat, longitude: lon, battery: battery, note: note, locationName: nil)
        
        // 2. Check connection status for different UX flows
        guard NetworkMonitor.shared.isConnected else {
            // Offline path: Play warning haptic and show no-internet alert
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
            showNoInternetAlert = true
            
            // Cleanup and close camera
            capturedImage = nil
            statusNote = ""
            dismiss()
            return
        }
        
        // 3. Online path: Optimistic Success pop-up animation instantly!
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            isUploadSuccess = true
        }
        
        // 4. Play sent sound (1004) and haptic success vibration
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            AudioServicesPlaySystemSound(1004) // Mail Sent crisp "klek" sound!
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
        
        // 5. Dismiss camera after 1.5 seconds so they can see the glorious feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            capturedImage = nil
            statusNote = ""
            isUploadSuccess = false
            dismiss()
        }
        
        // 6. Process the Outbox queue to start uploading in the background
        AuthManager.shared.processPendingFlashes()
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
