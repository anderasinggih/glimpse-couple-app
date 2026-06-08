import SwiftUI

#if !WIDGET
struct ChatBubbleView: View {
    @ObservedObject var audioPlayerManager = AudioPlayManager.shared
    @AppStorage("glimpse_chat_text_size") var chatTextSize: Double = 14.0
    
    let msg: ChatMessage
    let isPending: Bool
    @Bindable var auth: AuthManager
    let activeRoomThemeColor: Color
    @Binding var highlightedMessageId: Int?
    let latestSeenId: Int?
    let scrollProxy: ScrollViewProxy?
    
    let newlySentMessageIds: Set<Int>
    let newlyReceivedMessageIds: Set<Int>
    let starredMessageIds: Set<Int>
    let pinnedMessageIds: Set<Int>
    let getGlowProperties: (ChatMessage, Bool, Bool) -> ChatView.BubbleGlowProperties
    
    let onReply: () -> Void

    let onPin: () -> Void
    let onStar: () -> Void
    let onCopy: () -> Void
    
    private func formatMessageTime(_ rawDate: String?) -> String {
        guard let d = rawDate else { return "" }
        if let parsed = ChatDateFormatter.isoFormatterWithMS.date(from: d) ?? ChatDateFormatter.isoFormatter.date(from: d) ?? ChatDateFormatter.dbFormatter.date(from: d) {
            return ChatDateFormatter.timeOutputFormatter.string(from: parsed)
        }
        return ""
    }
    private func bubbleBackground(isMe: Bool) -> Color {
        if isMe {
            return activeRoomThemeColor.opacity(0.26)
        } else {
            return Color.white.opacity(0.08)
        }
    }

    private static var waveformCache: [String: [CGFloat]] = [:]
    
    private func getDeterministicWaveform(messageId: Int, totalBars: Int) -> [CGFloat] {
        let cacheKey = "\(messageId)_\(totalBars)"
        if let cached = Self.waveformCache[cacheKey] {
            return cached
        }
        
        var heights: [CGFloat] = []
        let seed = messageId
        for idx in 0..<totalBars {
            let factor = Double(idx) / Double(totalBars)
            let w1 = sin(factor * Double.pi * 3.5 + Double(seed % 7))
            let w2 = cos(factor * Double.pi * 7.5 - Double(seed % 11))
            let w3 = sin(factor * Double.pi * 14.0 + Double(seed % 3))
            let combined = abs(w1 * 0.5 + w2 * 0.3 + w3 * 0.1)
            let height = 4.0 + (combined * 14.0) // range [4, 18]
            heights.append(CGFloat(height))
        }
        Self.waveformCache[cacheKey] = heights
        return heights
    }

    private func audioChatBubble(msg: ChatMessage, isMe: Bool, isPending: Bool, timeStr: String, corners: UIRectCorner) -> some View {
        let isExpired = msg.audio_expired == true && !AudioPlayManager.shared.hasLocalCache(for: msg.id)
        let isPlayingThis = audioPlayerManager.playingMessageId == msg.id
        let duration = msg.audio_duration ?? 0.0
        
        let displayDuration: TimeInterval = isPlayingThis ? audioPlayerManager.currentTime : duration
        let durationText = formatDuration(displayDuration)
        let glow = getGlowProperties(msg, isMe, highlightedMessageId == msg.id)
        
        let screenWidth = UIScreen.main.bounds.width
        let bubbleWidth = screenWidth * 0.70
        let playButtonWidth: CGFloat = 34
        let spacing: CGFloat = 10
        let padding: CGFloat = 28 // 14 padding on left and right inside bubble
        let waveformWidth = bubbleWidth - playButtonWidth - spacing - padding
        let totalBars = Int(waveformWidth / 4.0) // each bar is 2.5 width + 1.5 spacing
        
        return HStack(spacing: spacing) {
            Button(action: {
                if !isExpired {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    let audioUrl = "\(auth.baseURL)/glimpse/chat/audio/\(msg.id)"
                    audioPlayerManager.playAudio(messageId: msg.id, urlString: audioUrl, message: msg)
                }
            }) {
                ZStack {
                    Circle()
                        .fill(isExpired ? Color.white.opacity(0.08) : (isPlayingThis ? activeRoomThemeColor.opacity(0.2) : Color.white.opacity(0.12)))
                        .frame(width: playButtonWidth, height: playButtonWidth)
                    
                    Image(systemName: isExpired ? "mic.slash" : (isPlayingThis && audioPlayerManager.isPlaying ? "pause.fill" : "play.fill"))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(isExpired ? Color.white.opacity(0.3) : (isPlayingThis ? activeRoomThemeColor : Color.white))
                }
            }
            .disabled(isExpired)
            
            VStack(alignment: .leading, spacing: 4) {
                if isExpired {
                    Text("Voice Note (Expired)")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.4))
                } else {
                    Canvas { context, size in
                        let progress = isPlayingThis && duration > 0 ? CGFloat(audioPlayerManager.currentTime / duration) : 0.0
                        let barHeights = getDeterministicWaveform(messageId: msg.id, totalBars: totalBars)
                        
                        let barWidth: CGFloat = 2.5
                        let barSpacing: CGFloat = 1.5
                        let cornerRadius: CGFloat = 1.0
                        
                        for idx in 0..<totalBars {
                            let barHeight = idx < barHeights.count ? barHeights[idx] : 8.0
                            let isFilled = CGFloat(idx) / CGFloat(totalBars) <= progress
                            
                            let x = CGFloat(idx) * (barWidth + barSpacing)
                            let y = (size.height - barHeight) / 2.0
                            
                            let rect = CGRect(x: x, y: y, width: barWidth, height: barHeight)
                            let path = Path(roundedRect: rect, cornerRadius: cornerRadius)
                            
                            context.fill(path, with: .color(isFilled ? activeRoomThemeColor : Color.white.opacity(0.2)))
                        }
                    }
                    .frame(width: waveformWidth, height: 20)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                guard !isExpired else { return }
                                if audioPlayerManager.playingMessageId == msg.id {
                                    let x = value.location.x
                                    let percentage = max(0.0, min(1.0, x / waveformWidth))
                                    let targetTime = percentage * duration
                                    audioPlayerManager.seek(to: targetTime)
                                }
                            }
                            .onEnded { value in
                                guard !isExpired else { return }
                                let x = value.location.x
                                let percentage = max(0.0, min(1.0, x / waveformWidth))
                                let targetTime = percentage * duration
                                
                                let audioUrl = "\(auth.baseURL)/glimpse/chat/audio/\(msg.id)"
                                if audioPlayerManager.playingMessageId != msg.id {
                                    audioPlayerManager.playAudio(messageId: msg.id, urlString: audioUrl, message: msg)
                                }
                                audioPlayerManager.seek(to: targetTime)
                            }
                    )
                }
                
                HStack(spacing: 6) {
                    Text(isExpired ? "--:--" : durationText)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(isExpired ? Color.white.opacity(0.3) : Color.white.opacity(0.6))
                    
                    if isPlayingThis {
                        Button(action: {
                            let currentSpeed = audioPlayerManager.playbackSpeed
                            let nextSpeed: Float = currentSpeed == 1.0 ? 1.5 : (currentSpeed == 1.5 ? 2.0 : 1.0)
                            audioPlayerManager.setSpeed(nextSpeed)
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }) {
                            let speedText = audioPlayerManager.playbackSpeed == 1.5 ? "1.5x" : (audioPlayerManager.playbackSpeed == 2.0 ? "2x" : "1x")
                            Text(speedText)
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(activeRoomThemeColor)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(activeRoomThemeColor.opacity(0.15))
                                .cornerRadius(5)
                        }
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 3) {
                        Text(timeStr)
                            .font(.system(size: 10, weight: .regular))
                            .foregroundColor(Color.white.opacity(0.4))
                        
                        if isPending {
                            PendingLoadingView(color: isMe ? activeRoomThemeColor.opacity(0.65) : .white.opacity(0.4))
                        }
                    }
                }
            }
            .frame(width: waveformWidth)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(highlightedMessageId == msg.id ? activeRoomThemeColor.opacity(0.35) : (isExpired ? Color.white.opacity(0.04) : bubbleBackground(isMe: isMe)))
        .clipShape(RoundedCorner(radius: 12, corners: corners))
        .overlay(
            RoundedCorner(radius: 12, corners: corners)
                .stroke(glow.strokeColor, lineWidth: glow.strokeWidth)
        )
        .scaleEffect(glow.scale)
        .shadow(color: glow.glowColor, radius: glow.glowRadius, y: 2)
        .animation(.spring(response: 0.35, dampingFraction: 0.72), value: newlySentMessageIds.contains(msg.id))
        .animation(.spring(response: 0.35, dampingFraction: 0.72), value: newlyReceivedMessageIds.contains(msg.id))
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let mins = Int(duration) / 60
        let secs = Int(duration) % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    @ViewBuilder
    private func flashAttachmentBubble(msg: ChatMessage, isMe: Bool, timeStr: String, corners: UIRectCorner) -> some View {
        let glow = getGlowProperties(msg, isMe, false)
        let bodyText = msg.replyInfo?.actualMessage ?? msg.message
        let parts = bodyText.components(separatedBy: "|")
        
        let photoUrl = parts.count > 1 ? parts[1] : ""
        let caption = parts.count > 2 ? parts[2] : ""
        let location = parts.count > 3 ? parts[3] : ""
        let hasRichData = !photoUrl.isEmpty
        
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "camera.shutter.button.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(activeRoomThemeColor)
                Text(hasRichData ? "Flash Photo" : "Sent a Flash!")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                if !timeStr.isEmpty && !hasRichData {
                    Text(timeStr)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(isMe ? activeRoomThemeColor.opacity(0.65) : .white.opacity(0.4))
                }
            }
            
            if hasRichData {
                let fullUrl = photoUrl.starts(with: "http") ? photoUrl : "\(auth.baseURL)\(photoUrl.starts(with: "/") ? "" : "/")\(photoUrl)"
                CachedImageView(urlString: fullUrl)
                    .frame(width: 220, height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.top, 2)
            }    
                if !caption.isEmpty || !location.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        if !caption.isEmpty {
                            Text(caption)
                                .font(.system(size: 12, design: .rounded))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        
                        if !location.isEmpty {
                            HStack(spacing: 3) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 8))
                                    .foregroundColor(activeRoomThemeColor)
                                Text(location)
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                }
            }
            
            HStack {
                Text(hasRichData ? "Tap to view full Flash" : "Tap to view on Dashboard")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                Spacer(minLength: 8)
                if !timeStr.isEmpty && hasRichData {
                    Text(timeStr)
                        .font(.system(size: 7.5, weight: .medium))
                        .foregroundColor(isMe ? activeRoomThemeColor.opacity(0.65) : .white.opacity(0.4))
                }
            }
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 9)
        .frame(width: hasRichData ? 242 : 175)
        .background(
            isMe ? activeRoomThemeColor.opacity(0.18) : Color.white.opacity(0.12)
        )
        .clipShape(RoundedCorner(radius: 18, corners: corners))
        .overlay(
            RoundedCorner(radius: 18, corners: corners)
                .stroke(glow.strokeColor, lineWidth: glow.strokeWidth)
        )
        .scaleEffect(glow.scale)
        .shadow(color: glow.glowColor, radius: glow.glowRadius, y: 3)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                auth.selectedTab = 0
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.72), value: newlySentMessageIds.contains(msg.id))
        .animation(.spring(response: 0.35, dampingFraction: 0.72), value: newlyReceivedMessageIds.contains(msg.id))
    }

    @ViewBuilder
    private func kencanInvitationBubble(msg: ChatMessage, isMe: Bool, timeStr: String, corners: UIRectCorner) -> some View {
        let glow = getGlowProperties(msg, isMe, false)
        
        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(activeRoomThemeColor)
                Text("New Kencan Invite!")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
            
            let cleanMsg = msg.message.replacingOccurrences(of: "[KENCAN_INVITATION] ", with: "")
            Text(cleanMsg)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.85))
                .multilineTextAlignment(.leading)
            
            HStack {
                Text("Tap to respond & set Alarm")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(activeRoomThemeColor)
                Spacer(minLength: 8)
                if !timeStr.isEmpty {
                    Text(timeStr)
                        .font(.system(size: 7.5, weight: .medium))
                        .foregroundColor(isMe ? activeRoomThemeColor.opacity(0.65) : .white.opacity(0.4))
                }
            }
            .padding(.top, 2)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .frame(width: 220)
        .background(
            isMe ? activeRoomThemeColor.opacity(0.18) : Color.white.opacity(0.12)
        )
        .clipShape(RoundedCorner(radius: 18, corners: corners))
        .overlay(
            RoundedCorner(radius: 18, corners: corners)
                .stroke(glow.strokeColor, lineWidth: glow.strokeWidth)
        )
        .scaleEffect(glow.scale)
        .shadow(color: glow.glowColor, radius: glow.glowRadius, y: 3)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                auth.showScheduleSheet = true
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.72), value: newlySentMessageIds.contains(msg.id))
        .animation(.spring(response: 0.35, dampingFraction: 0.72), value: newlyReceivedMessageIds.contains(msg.id))
    }

    @ViewBuilder
    private func standardTextChatBubble(msg: ChatMessage, isMe: Bool, isPending: Bool, timeStr: String, corners: UIRectCorner, scrollProxy: ScrollViewProxy?, isHighlighted: Bool) -> some View {
        let glow = getGlowProperties(msg, isMe, isHighlighted)
        let displayText = msg.replyInfo?.actualMessage ?? msg.message
        let isShort = displayText.count < 35 && !displayText.contains("\n") && msg.replyInfo == nil && !displayText.containsURL
        
        return Group {
            if isShort {
                HStack(alignment: .bottom, spacing: 8) {
                    LinkedTextView(text: displayText, fontSize: chatTextSize, foregroundColor: .white)
                        .multilineTextAlignment(.leading)
                    
                    HStack(spacing: 3) {
                        if starredMessageIds.contains(msg.id) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 8.0))
                                .foregroundColor(.yellow)
                        }
                        
                        if !timeStr.isEmpty {
                            Text(timeStr)
                                .font(.system(size: 8.0, weight: .medium))
                                .foregroundColor(isMe ? activeRoomThemeColor.opacity(0.65) : .white.opacity(0.4))
                        }
                        
                        if isPending {
                            PendingLoadingView(color: isMe ? activeRoomThemeColor.opacity(0.65) : .white.opacity(0.4))
                        }
                    }
                    .padding(.bottom, 0.5)
                }
            } else {
                VStack(alignment: .trailing, spacing: 4) {
                    if let reply = msg.replyInfo {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(reply.senderName)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(activeRoomThemeColor)
                            Text(formatReplyPreview(text: reply.parentMessage))
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.65))
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(.vertical, 5)
                        .padding(.horizontal, 8)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(6)
                        .overlay(
                            HStack {
                                Rectangle()
                                    .fill(activeRoomThemeColor)
                                    .frame(width: 3)
                                Spacer()
                            }
                        )
                        .padding(.bottom, 2)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if let proxy = scrollProxy {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                withAnimation(.easeInOut(duration: 0.45)) {
                                    proxy.scrollTo(reply.parentId, anchor: .center)
                                }
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    highlightedMessageId = reply.parentId
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                    withAnimation(.easeOut(duration: 0.5)) {
                                        if highlightedMessageId == reply.parentId {
                                            highlightedMessageId = nil
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    LinkedTextView(text: displayText, fontSize: chatTextSize, foregroundColor: .white)
                        .multilineTextAlignment(.leading)

                    // Link preview card
                    if let url = displayText.firstURL {
                        ChatLinkPreviewCard(url: url, themeColor: activeRoomThemeColor)
                            .padding(.top, 2)
                    }
                    
                    HStack(spacing: 3) {
                        if starredMessageIds.contains(msg.id) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 8.0))
                                .foregroundColor(.yellow)
                        }
                        
                        if !timeStr.isEmpty {
                            Text(timeStr)
                                .font(.system(size: 8.0, weight: .medium))
                                .foregroundColor(isMe ? activeRoomThemeColor.opacity(0.65) : .white.opacity(0.4))
                        }
                        
                        if isPending {
                            PendingLoadingView(color: isMe ? activeRoomThemeColor.opacity(0.65) : .white.opacity(0.4))
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5.5)
        .background(isHighlighted ? activeRoomThemeColor.opacity(0.35) : bubbleBackground(isMe: isMe))
        .clipShape(RoundedCorner(radius: 12, corners: corners))
        .overlay(
            RoundedCorner(radius: 12, corners: corners)
                .stroke(glow.strokeColor, lineWidth: glow.strokeWidth)
        )
        .scaleEffect(glow.scale)
        .shadow(color: glow.glowColor, radius: glow.glowRadius, y: 2)
        .animation(.spring(response: 0.35, dampingFraction: 0.72), value: newlySentMessageIds.contains(msg.id))
        .animation(.spring(response: 0.35, dampingFraction: 0.72), value: newlyReceivedMessageIds.contains(msg.id))
    }
    
    // WHATSAPP STYLE CHAT BUBBLES WITH INDIVIDUAL TIME STAMPS & SWIPE TO REPLY
    private func chatBubble(msg: ChatMessage, isPending: Bool = false, scrollProxy: ScrollViewProxy? = nil, latestSeenId: Int?) -> some View {
        let isMe = msg.sender_id == auth.currentUser?.id
        let isHighlighted = highlightedMessageId == msg.id
        let corners: UIRectCorner = isMe ? [.topLeft, .topRight, .bottomLeft] : [.topLeft, .topRight, .bottomRight]
        let timeStr = formatMessageTime(msg.created_at)
        
        return VStack(alignment: .trailing, spacing: 2) {
            HStack {
                if isMe {
                    Spacer()
                }
                
                SwipeableBubbleView(msg: msg, isMe: isMe, themeColor: activeRoomThemeColor, onReplyTriggered: onReply) {
                    Group {
                        let bodyText = msg.replyInfo?.actualMessage ?? msg.message
                        if msg.is_audio == true {
                            audioChatBubble(msg: msg, isMe: isMe, isPending: isPending, timeStr: timeStr, corners: corners)
                        } else if bodyText.contains("[FLASH_ATTACHMENT]") {
                            flashAttachmentBubble(msg: msg, isMe: isMe, timeStr: timeStr, corners: corners)
                        } else if bodyText.contains("[KENCAN_INVITATION]") {
                            kencanInvitationBubble(msg: msg, isMe: isMe, timeStr: timeStr, corners: corners)
                        } else {
                            standardTextChatBubble(msg: msg, isMe: isMe, isPending: isPending, timeStr: timeStr, corners: corners, scrollProxy: scrollProxy, isHighlighted: isHighlighted)
                        }
                    }
                    .frame(maxWidth: UIScreen.main.bounds.width * (msg.is_audio == true ? 0.72 : 0.78), alignment: isMe ? .trailing : .leading)
                }
                .contextMenu {
                    Button {
                        onStar()
                    } label: {
                        Label(starredMessageIds.contains(msg.id) ? "Unstar" : "Star", systemImage: starredMessageIds.contains(msg.id) ? "star.slash" : "star")
                    }

                    Button {
                        onPin()
                    } label: {
                        Label(pinnedMessageIds.contains(msg.id) ? "Unpin" : "Pin", systemImage: pinnedMessageIds.contains(msg.id) ? "pin.slash" : "pin")
                    }

                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                            onReply()
                        }
                    } label: {
                        Label("Reply", systemImage: "arrowshape.turn.up.left")
                    }

                    Button {
                        onCopy()
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                }
                
                if !isMe {
                    Spacer()
                }
            }
            
            let isLatestSeen = isMe && msg.id == latestSeenId
            
            if isLatestSeen {
                HStack(spacing: 3.5) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 8))
                    Text("Seen")
                        .font(.system(size: 9.5, weight: .semibold))
                }
                .foregroundColor(activeRoomThemeColor.opacity(0.85))
                .padding(.trailing, 6)
                .padding(.top, 1)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .id(msg.id)
    }
    
    var body: some View {
        chatBubble(msg: msg, isPending: isPending, scrollProxy: scrollProxy, latestSeenId: latestSeenId)
    }
}

#endif
