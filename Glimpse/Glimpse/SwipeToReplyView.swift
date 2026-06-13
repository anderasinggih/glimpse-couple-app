#if !WIDGET
import SwiftUI

struct SwipeableBubbleView<Content: View>: View {
    let msg: ChatMessage
    let isMe: Bool
    let themeColor: Color
    let onReplyTriggered: () -> Void
    let content: Content
    
    @State private var localSwipeOffset: CGFloat = 0
    @State private var isSwiping = false
    
    init(msg: ChatMessage, isMe: Bool, themeColor: Color, onReplyTriggered: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.msg = msg
        self.isMe = isMe
        self.themeColor = themeColor
        self.onReplyTriggered = onReplyTriggered
        self.content = content()
    }
    
    var body: some View {
        HStack(spacing: 0) {
            if isMe {
                // MY bubble: slides LEFT (localSwipeOffset < 0) towards the center of the screen
                ZStack(alignment: .trailing) {
                    if localSwipeOffset < -5 {
                        Image(systemName: "arrow.uturn.left.circle.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(themeColor)
                            .shadow(color: themeColor.opacity(0.35), radius: 6)
                            .opacity(min(1.0, Double(abs(localSwipeOffset) / 45.0)))
                            .scaleEffect(min(1.0, 0.5 + 0.5 * (abs(localSwipeOffset) / 50.0)))
                            .offset(x: 28 + (localSwipeOffset * 0.12))
                    }
                    
                    content
                        .offset(x: localSwipeOffset)
                }
                .gesture(
                    DragGesture(minimumDistance: 25, coordinateSpace: .local)
                        .onChanged { value in
                            // Ignore drags starting within the left-edge back-swipe zone (38pt) to let interactivePopGesture trigger
                            guard value.startLocation.x > 38 else { return }
                            // Avoid stealing vertical scroll
                            guard abs(value.translation.width) > abs(value.translation.height) * 1.5 else { return }
                            let width = value.translation.width
                            guard width < 0 else { return }
                            isSwiping = true
                            let limit: CGFloat = -60
                            if width < limit {
                                let excess = width - limit
                                localSwipeOffset = limit + excess * 0.35
                            } else {
                                localSwipeOffset = width
                            }
                        }
                        .onEnded { value in
                            defer {
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                                    localSwipeOffset = 0
                                }
                                isSwiping = false
                            }
                            guard value.startLocation.x > 38 else { return }
                            // Avoid registering reply if gesture was mostly vertical
                            guard abs(value.translation.width) > abs(value.translation.height) * 1.5 else { return }
                            if value.translation.width < -35 {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                onReplyTriggered()
                            }
                        }
                )
            } else {
                // PARTNER bubble: slides RIGHT (localSwipeOffset > 0) towards the center of the screen
                ZStack(alignment: .leading) {
                    if localSwipeOffset > 5 {
                        Image(systemName: "arrow.uturn.left.circle.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(themeColor)
                            .shadow(color: themeColor.opacity(0.35), radius: 6)
                            .opacity(min(1.0, Double(localSwipeOffset / 45.0)))
                            .scaleEffect(min(1.0, 0.5 + 0.5 * (localSwipeOffset / 50.0)))
                            .offset(x: -28 + (localSwipeOffset * 0.12))
                    }
                    
                    content
                        .offset(x: localSwipeOffset)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 25, coordinateSpace: .local)
                        .onChanged { value in
                            // Ignore drags starting within the left-edge back-swipe zone (38pt) to let interactivePopGesture trigger
                            guard value.startLocation.x > 38 else { return }
                            // Avoid stealing vertical scroll
                            guard abs(value.translation.width) > abs(value.translation.height) * 1.5 else { return }
                            let width = value.translation.width
                            guard width > 0 else { return }
                            isSwiping = true
                            let limit: CGFloat = 60
                            if width > limit {
                                let excess = width - limit
                                localSwipeOffset = limit + excess * 0.35
                            } else {
                                localSwipeOffset = width
                            }
                        }
                        .onEnded { value in
                            defer {
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                                    localSwipeOffset = 0
                                }
                                isSwiping = false
                            }
                            guard value.startLocation.x > 38 else { return }
                            // Avoid registering reply if gesture was mostly vertical
                            guard abs(value.translation.width) > abs(value.translation.height) * 1.5 else { return }
                            if value.translation.width > 35 {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                onReplyTriggered()
                            }
                        }
                )
            }
        }
    }
}

struct PendingLoadingView: View {
    @State private var rotationAngle: Double = 0.0
    var color: Color
    
    var body: some View {
        Circle()
            .trim(from: 0.1, to: 0.9)
            .stroke(color, style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
            .frame(width: 8, height: 8)
            .rotationEffect(Angle(degrees: rotationAngle))
            .onAppear {
                withAnimation(Animation.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                    rotationAngle = 360.0
                }
            }
    }
}

extension UINavigationController: UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

struct ChatDateFormatter {
    static let isoFormatterWithMS: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    
    static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()
    
    static let dbFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f
    }()
    
    static let timeOutputFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        f.timeZone = TimeZone.current
        return f
    }()
    
    static let dayOutputFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMMM yyyy"
        f.timeZone = TimeZone.current
        return f
    }()
}

// Formatter to hide raw payload data in reply previews
func formatReplyPreview(text: String) -> String {
    if text.contains("[FLASH_ATTACHMENT]") {
        return "📸 Sent a Flash Photo"
    }
    if text.contains("[VOICE_MESSAGE]") || text.contains("[VOICE_NOTE]") {
        return "🎤 Voice Note"
    }
    return text
}

#endif
