import SwiftUI

struct EmailVerificationView: View {
    @Bindable var auth: AuthManager

    @State private var otpText = ""
    @FocusState private var isKeyboardActive: Bool

    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var successMessage = ""
    @State private var isResending = false

    @State private var countdown = 60
    @State private var timerTask: Task<Void, Never>? = nil
    @State private var canResend = false

    private let otpLength = 6

    var body: some View {
        ZStack {
            // Background — tap to dismiss keyboard
            Color.adaptiveBackground
                .ignoresSafeArea()
                .onTapGesture { isKeyboardActive = false }

            VStack(spacing: 32) {
                Spacer()

                // Icon + title
                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.electricPurple.opacity(0.15))
                            .frame(width: 100, height: 100)
                        Image(systemName: "envelope.badge.shield.half.filled")
                            .font(.system(size: 46))
                            .foregroundColor(.electricPurple)
                            .shadow(color: .electricPurple.opacity(0.5), radius: 10)
                    }

                    Text("Verify Your Email")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("We sent a 6-digit code to\n\(auth.currentUser?.email ?? "your email")")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.55))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.horizontal, 24)
                }

                // 6-box OTP display (tap anywhere on it to open keyboard)
                ZStack {
                    // Hidden actual TextField that captures input
                    TextField("", text: $otpText)
                        .keyboardType(.numberPad)
                        .focused($isKeyboardActive)
                        .frame(width: 1, height: 1)
                        .opacity(0.001)
                        .onChange(of: otpText) { _, newVal in
                            // Only digits, max 6
                            let filtered = String(newVal.filter { $0.isNumber }.prefix(otpLength))
                            if filtered != newVal { otpText = filtered }
                            if filtered.count == otpLength {
                                isKeyboardActive = false
                                Task { await verify() }
                            }
                        }

                    // Visual 6 boxes
                    HStack(spacing: 10) {
                        ForEach(0..<otpLength, id: \.self) { i in
                            let char: String = i < otpText.count
                                ? String(otpText[otpText.index(otpText.startIndex, offsetBy: i)])
                                : ""
                            let isCurrent = i == otpText.count && isKeyboardActive

                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(isCurrent ? 0.12 : 0.07))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                isCurrent
                                                    ? Color.electricPurple
                                                    : (char.isEmpty
                                                        ? Color.white.opacity(0.15)
                                                        : Color.electricPurple.opacity(0.5)),
                                                lineWidth: isCurrent ? 2 : 1.2
                                            )
                                    )
                                    .animation(.easeInOut(duration: 0.15), value: isCurrent)

                                if isCurrent {
                                    // Blinking cursor
                                    RoundedRectangle(cornerRadius: 1)
                                        .fill(Color.electricPurple)
                                        .frame(width: 2, height: 24)
                                        .opacity(isKeyboardActive ? 1 : 0)
                                        .animation(.easeInOut(duration: 0.6).repeatForever(), value: isKeyboardActive)
                                } else {
                                    Text(char)
                                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(width: 46, height: 54)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { isKeyboardActive = true }
                }
                .padding(.horizontal, 24)

                // Messages
                VStack(spacing: 6) {
                    if !errorMessage.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.circle.fill").font(.caption)
                            Text(errorMessage).font(.caption)
                        }
                        .foregroundColor(.red)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    if !successMessage.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill").font(.caption)
                            Text(successMessage).font(.caption)
                        }
                        .foregroundColor(.green)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: errorMessage)
                .animation(.easeInOut(duration: 0.2), value: successMessage)

                // Verify button
                Button {
                    Task { await verify() }
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView().tint(.deepVelvet)
                        } else {
                            Text("Verify Account")
                                .fontWeight(.bold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(otpText.count < otpLength ? Color.gray.opacity(0.25) : Color.electricPurple)
                    .foregroundColor(.deepVelvet)
                    .cornerRadius(14)
                }
                .disabled(isLoading || otpText.count < otpLength)
                .padding(.horizontal, 28)
                .animation(.easeInOut(duration: 0.15), value: otpText.count)

                // Resend + logout
                VStack(spacing: 14) {
                    if canResend {
                        Button {
                            Task { await resendCode() }
                        } label: {
                            HStack(spacing: 6) {
                                if isResending {
                                    ProgressView().scaleEffect(0.7).tint(.electricPurple)
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                Text("Resend Code")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundColor(.electricPurple)
                        }
                        .disabled(isResending)
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "clock").font(.caption)
                                .foregroundColor(.white.opacity(0.35))
                            Text("Resend in \(countdown)s")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.35))
                        }
                    }

                    Button {
                        auth.logout()
                    } label: {
                        Text("Log Out / Change Account")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                            .underline()
                    }
                }

                Spacer()
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isKeyboardActive = true
            }
            startCountdown()
        }
        .onDisappear {
            timerTask?.cancel()
        }
    }

    // MARK: - Timer
    private func startCountdown() {
        canResend = false
        countdown = 60
        timerTask?.cancel()
        timerTask = Task {
            for remaining in stride(from: 59, through: 0, by: -1) {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { return }
                await MainActor.run { countdown = remaining }
            }
            await MainActor.run { canResend = true }
        }
    }

    // MARK: - Actions
    private func verify() async {
        guard otpText.count == otpLength else { return }
        isKeyboardActive = false
        isLoading = true
        errorMessage = ""
        successMessage = ""
        do {
            try await auth.verifyEmail(otp: otpText)
        } catch {
            errorMessage = error.localizedDescription
            withAnimation { otpText = "" }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isKeyboardActive = true
            }
        }
        isLoading = false
    }

    private func resendCode() async {
        isResending = true
        errorMessage = ""
        successMessage = ""
        do {
            try await auth.resendVerification()
            successMessage = "A new code has been sent to your email."
            otpText = ""
            startCountdown()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isKeyboardActive = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isResending = false
    }
}
