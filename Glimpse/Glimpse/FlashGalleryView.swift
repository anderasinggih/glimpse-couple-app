#if !WIDGET
import SwiftUI
import MapKit

struct FlashGalleryView: View {
    @Bindable var auth: AuthManager
    let initialFlashId: Int
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedFlashId: Int
    @State private var activeFlashes: [GlimpseFlash] = []
    
    init(auth: AuthManager, initialFlashId: Int) {
        self.auth = auth
        self.initialFlashId = initialFlashId
        _selectedFlashId = State(initialValue: initialFlashId)
        
        // Initialize immediately with available flashes to prevent slow loading
        _activeFlashes = State(initialValue: auth.flashes)
    }
    
    @State private var isShowingDeleteAlert = false
    @State private var isShowingSuccessAlert = false
    
    var body: some View {
        ZStack {
            // Background follows the user theme (pure black/default with dynamic orbs)
            iOS26Background().ignoresSafeArea()
            
            // 1. MAIN SWIPER AREA (ignores safe area)
            TabView(selection: $selectedFlashId) {
                ForEach(activeFlashes) { flash in
                    VStack(spacing: 0) {
                        Spacer()
                        
                        // Centered Photo with Pinch-to-Zoom (hold to release)
                        CachedImageView(urlString: formattedUrl(flash.photo_url))
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .modifier(PinchZoomModifier())
                        
                        // Name, Location, and Caption below the photo (no container, align left)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(flash.sender_name)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            if let loc = flash.location_name, !loc.isEmpty {
                                Text(loc)
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            
                            if let note = flash.status_note, !note.isEmpty {
                                Text(note)
                                    .font(.system(size: 13, design: .rounded))
                                    .foregroundColor(.white.opacity(0.9))
                                    .multilineTextAlignment(.leading)
                                    .padding(.top, 2)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Spacer()
                    }
                    .tag(flash.id)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never)) // Hide dots
            .ignoresSafeArea()
            
            // 3. OVERLAY LAYOUT (Respects Safe Area naturally to prevent offscreen elements)
            VStack {
                // Top Header Bar
                HStack(alignment: .center) {
                    // Left Back Button (Translucent Circle)
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.white.opacity(0.15))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    // Center Date/Time Capsule (using ultraThinMaterial to follow background setting)
                    if let currentFlash = activeFlashes.first(where: { $0.id == selectedFlashId }) {
                        VStack(spacing: 2) {
                            Text(formatFlashDateRelative(currentFlash.createdDate))
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text(formatFlashTimeOnly(currentFlash.createdDate))
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                        )
                    }
                    
                    Spacer()
                    
                    // Delete Button (Translucent Circle)
                    Button {
                        isShowingDeleteAlert = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.red)
                            .frame(width: 40, height: 40)
                            .background(Color.white.opacity(0.15))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10) // Small padding from top safe area limit
                
                Spacer()
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            auth.isHidingBrandingHeader = true
            filterExpiredFlashes()
        }
        .onDisappear {
            auth.isHidingBrandingHeader = false
        }
        // Native Haptic Feedback when selection changes (during drag/snap transitions)
        .onChange(of: selectedFlashId) { oldValue, newValue in
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        .alert("Delete Memory permanently?", isPresented: $isShowingDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let currentFlash = activeFlashes.first(where: { $0.id == selectedFlashId }) {
                    Task {
                        try? await auth.deleteFlashPermanently(id: currentFlash.id)
                        await MainActor.run {
                            if let index = activeFlashes.firstIndex(where: { $0.id == currentFlash.id }) {
                                activeFlashes.remove(at: index)
                            }
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            isShowingSuccessAlert = true
                        }
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently remove this flash photo from Glimpse servers and Google Drive.")
        }
        .alert("Success", isPresented: $isShowingSuccessAlert) {
            Button("OK") {
                if activeFlashes.isEmpty {
                    dismiss()
                } else {
                    if let first = activeFlashes.first {
                        selectedFlashId = first.id
                    }
                }
            }
        } message: {
            Text("Memory has been successfully deleted.")
        }
    }
    
    private func filterExpiredFlashes() {
        Task {
            var filtered: [GlimpseFlash] = []
            for flash in auth.flashes {
                if await isFlashValid(flash) {
                    filtered.append(flash)
                }
            }
            await MainActor.run {
                self.activeFlashes = filtered
                // If selected photo is deleted, select first active flash
                if !filtered.contains(where: { $0.id == selectedFlashId }), let first = filtered.first {
                    selectedFlashId = first.id
                }
            }
        }
    }
    
    private func isFlashValid(_ flash: GlimpseFlash) async -> Bool {
        let finalUrlStr = formattedUrl(flash.photo_url)
        
        let cleanName = finalUrlStr.components(separatedBy: CharacterSet.alphanumerics.inverted).joined()
        let filename = "img_cache_\(cleanName).jpg"
        
        if let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.glimpse.app") {
            let fileURL = groupURL.appendingPathComponent(filename)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                return true
            }
        }
        
        if let cachesURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            let fileURL = cachesURL.appendingPathComponent(filename)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                return true
            }
        }
        
        guard let url = URL(string: finalUrlStr) else { return false }
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        if let (_, response) = try? await URLSession.shared.data(for: request),
           let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode == 404 {
            return false
        }
        
        return true
    }
    
    private func formattedUrl(_ urlString: String) -> String {
        if urlString.hasPrefix("http") {
            return urlString
        } else {
            let cleanPath = urlString.hasPrefix("/") ? String(urlString.dropFirst()) : urlString
            let baseURL = AuthManager.shared.baseURL.replacingOccurrences(of: "/api", with: "")
            return cleanPath.contains("storage/") ? "\(baseURL)/\(cleanPath)" : "\(baseURL)/storage/\(cleanPath)"
        }
    }
    
    private func formatFlashDateRelative(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMMM yyyy"
            return formatter.string(from: date)
        }
    }
    
    private func formatFlashTimeOnly(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Pinch Zoom Modifier (Hold to Release)
struct PinchZoomModifier: ViewModifier {
    @GestureState private var scale: CGFloat = 1.0
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .simultaneousGesture(
                MagnificationGesture()
                    .updating($scale) { value, state, _ in
                        state = value
                    }
            )
    }
}
#endif
