import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) var dismiss

    @State private var email = ""
    @State private var otpText = ""
    @State private var newPassword = ""

    @State private var step: Int = 1
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var successMessage = ""

    @FocusState private var emailFocused: Bool
    @FocusState private var otpKeyboardActive: Bool
    @FocusState private var passwordFocused: Bool

    private let otpLength = 6

    var body: some View {
        ZStack {
            // Background tap — dismiss keyboard
            Color.adaptiveBackground
                .ignoresSafeArea()
                .onTapGesture {
                    emailFocused = false
                    otpKeyboardActive = false
                    passwordFocused = false
                }

            VStack(spacing: 0) {
                // Header
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.body.bold())
                            .foregroundColor(.white.opacity(0.6))
                            .padding(10)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        // Title
                        VStack(alignment: .leading, spacing: 8) {
                            Text(step == 1 ? "Reset Password" : "Enter Code")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text(step == 1
                                 ? "Enter your email and we'll send a 6-digit reset code."
                                 : "Enter the 6-digit code sent to \(email) and set your new password.")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.55))
                                .lineSpacing(4)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 8)

                        // Step 1: Email
                        if step == 1 {
                            CustomTextField(
                                icon: "envelope.fill",
                                placeholder: "Email Address",
                                text: $email,
                                maxLength: 100
                            )
                            .keyboardType(.emailAddress)
                            .focused($emailFocused)
                            .padding(.horizontal)
                        }

                        // Step 2: OTP + new password
                        if step == 2 {
                            VStack(spacing: 20) {
                                VStack(spacing: 10) {
                                    Text("Verification Code")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.5))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 4)

                                    // 6-box OTP using hidden TextField
                                    ZStack {
                                        // Hidden TextField capturing all input
                                        TextField("", text: $otpText)
                                            .keyboardType(.numberPad)
                                            .focused($otpKeyboardActive)
                                            .frame(width: 1, height: 1)
                                            .opacity(0.001)
                                            .onChange(of: otpText) { _, newVal in
                                                let filtered = String(newVal.filter { $0.isNumber }.prefix(otpLength))
                                                if filtered != newVal { otpText = filtered }
                                            }

                                        // Visual boxes
                                        HStack(spacing: 10) {
                                            ForEach(0..<otpLength, id: \.self) { i in
                                                let char: String = i < otpText.count
                                                    ? String(otpText[otpText.index(otpText.startIndex, offsetBy: i)])
                                                    : ""
                                                let isCurrent = i == otpText.count && otpKeyboardActive

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
                                                        RoundedRectangle(cornerRadius: 1)
                                                            .fill(Color.electricPurple)
                                                            .frame(width: 2, height: 24)
                                                            .opacity(otpKeyboardActive ? 1 : 0)
                                                            .animation(.easeInOut(duration: 0.6).repeatForever(), value: otpKeyboardActive)
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
                                        .onTapGesture {
                                            passwordFocused = false
                                            otpKeyboardActive = true
                                        }
                                    }
                                }
                                .padding(.horizontal)

                                CustomTextField(
                                    icon: "lock.fill",
                                    placeholder: "New Password (min. 8 chars)",
                                    text: $newPassword,
                                    isSecure: true,
                                    maxLength: 32
                                )
                                .focused($passwordFocused)
                                .onTapGesture {
                                    otpKeyboardActive = false
                                    passwordFocused = true
                                }
                                .padding(.horizontal)
                            }
                        }

                        // Messages
                        VStack(spacing: 6) {
                            if !errorMessage.isEmpty {
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.circle.fill").font(.caption)
                                    Text(errorMessage).font(.caption)
                                }
                                .foregroundColor(.red)
                                .padding(.horizontal)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                            if !successMessage.isEmpty {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill").font(.caption)
                                    Text(successMessage).font(.caption)
                                }
                                .foregroundColor(.green)
                                .padding(.horizontal)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        .animation(.easeInOut(duration: 0.2), value: errorMessage)
                        .animation(.easeInOut(duration: 0.2), value: successMessage)

                        // Action button
                        Button {
                            if step == 1 { Task { await sendCode() } }
                            else { Task { await resetPassword() } }
                        } label: {
                            HStack {
                                if isLoading {
                                    ProgressView().tint(.deepVelvet)
                                } else {
                                    Text(step == 1 ? "Send Reset Code" : "Reset Password")
                                        .fontWeight(.bold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(isActionDisabled ? Color.gray.opacity(0.25) : Color.electricPurple)
                            .foregroundColor(.deepVelvet)
                            .cornerRadius(14)
                        }
                        .disabled(isLoading || isActionDisabled)
                        .padding(.horizontal)

                        // Back
                        if step == 2 {
                            Button {
                                withAnimation(.easeInOut) {
                                    step = 1
                                    errorMessage = ""
                                    successMessage = ""
                                    otpText = ""
                                    newPassword = ""
                                }
                            } label: {
                                Text("← Back to Email")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.electricPurple)
                            }
                            .padding(.top, 4)
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                emailFocused = true
            }
        }
    }

    private var isActionDisabled: Bool {
        if step == 1 { return email.isEmpty }
        return otpText.count < otpLength || newPassword.count < 8
    }

    // MARK: - Actions
    private func sendCode() async {
        emailFocused = false
        let trimmedEmail = email.lowercased().trimmingCharacters(in: .whitespaces)
        guard !trimmedEmail.isEmpty, trimmedEmail.contains("@"), trimmedEmail.contains(".") else {
            withAnimation { errorMessage = "Please enter a valid email address." }
            return
        }
        isLoading = true
        errorMessage = ""
        successMessage = ""
        do {
            try await AuthManager.shared.forgotPassword(email: trimmedEmail)
            withAnimation {
                step = 2
                successMessage = "Code sent! Check your inbox."
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                otpKeyboardActive = true
            }
        } catch {
            withAnimation { errorMessage = error.localizedDescription }
        }
        isLoading = false
    }

    private func resetPassword() async {
        guard otpText.count == otpLength, newPassword.count >= 8 else { return }
        otpKeyboardActive = false
        passwordFocused = false
        isLoading = true
        errorMessage = ""
        successMessage = ""
        do {
            try await AuthManager.shared.resetPassword(
                email: email.lowercased().trimmingCharacters(in: .whitespaces),
                otp: otpText,
                newPassword: newPassword
            )
            successMessage = "Password reset successfully!"
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            dismiss()
        } catch {
            withAnimation {
                errorMessage = error.localizedDescription
                otpText = ""
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                otpKeyboardActive = true
            }
        }
        isLoading = false
    }
}
