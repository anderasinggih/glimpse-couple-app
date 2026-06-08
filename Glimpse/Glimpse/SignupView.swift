import SwiftUI

struct SignupView: View {
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var bornDate = Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date()
    @State private var bornDateSelected = false
    @State private var gender = ""
    @State private var showDatePicker = false
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case name, email, password
    }
    
    var body: some View {
        ZStack {
            // Background tap to dismiss keyboard
            Color.adaptiveBackground
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    focusedField = nil
                }
            
            VStack(spacing: 24) {
                // Back Button Row
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.title3.bold())
                            .foregroundColor(.white)
                            .padding(12) // Wider hit area
                            .background(Color.white.opacity(0.01))
                    }
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.top, 10)
                .zIndex(10)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Join Glimpse")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    Text("Start your intimate journey today.")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
                VStack(spacing: 16) {
                    CustomTextField(icon: "person.fill", placeholder: "Full Name", text: $name, maxLength: 30)
                        .focused($focusedField, equals: .name)
                        .submitLabel(.next)
                        .onTapGesture { focusedField = .name }
                    
                    CustomTextField(icon: "envelope.fill", placeholder: "Email", text: $email, maxLength: 100)
                        .keyboardType(.emailAddress)
                        .focused($focusedField, equals: .email)
                        .submitLabel(.next)
                        .onTapGesture { focusedField = .email }
                    
                    CustomTextField(icon: "lock.fill", placeholder: "Password", text: $password, isSecure: true, maxLength: 32)
                        .focused($focusedField, equals: .password)
                        .submitLabel(.done)
                        .onTapGesture { focusedField = .password }
                    
                    // Date of Birth Row
                    Button(action: {
                        focusedField = nil
                        showDatePicker = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "calendar")
                                .foregroundColor(.white.opacity(0.6))
                                .frame(width: 20)
                            
                            Text(bornDateSelected ? bornDate.formatted(date: .long, time: .omitted) : "Date of Birth")
                                .foregroundColor(bornDateSelected ? .white : .white.opacity(0.4))
                                .font(.system(size: 15))
                            
                            Spacer()
                            
                            Text(bornDateSelected ? "Edit" : "Select")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.electricPurple)
                        }
                        .padding()
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1.2)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Gender Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Gender")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.leading, 4)
                        
                        HStack(spacing: 12) {
                            Button(action: {
                                focusedField = nil
                                gender = "male"
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: gender == "male" ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(gender == "male" ? Color(hex: "3A86FF") : .white.opacity(0.3))
                                    Text("♂ Male")
                                        .font(.system(size: 15, weight: gender == "male" ? .bold : .semibold, design: .rounded))
                                        .foregroundColor(gender == "male" ? Color(hex: "3A86FF") : .white.opacity(0.6))
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(gender == "male" ? Color(hex: "3A86FF").opacity(0.15) : Color.white.opacity(0.06))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(gender == "male" ? Color(hex: "3A86FF") : Color.white.opacity(0.12), lineWidth: 1.2)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Button(action: {
                                focusedField = nil
                                gender = "female"
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: gender == "female" ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(gender == "female" ? Color(hex: "FF4DAD") : .white.opacity(0.3))
                                    Text("♀ Female")
                                        .font(.system(size: 15, weight: gender == "female" ? .bold : .semibold, design: .rounded))
                                        .foregroundColor(gender == "female" ? Color(hex: "FF4DAD") : .white.opacity(0.6))
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(gender == "female" ? Color(hex: "FF4DAD").opacity(0.15) : Color.white.opacity(0.06))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(gender == "female" ? Color(hex: "FF4DAD") : Color.white.opacity(0.12), lineWidth: 1.2)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.top, 4)
                }
                .onSubmit {
                    if focusedField == .name { focusedField = .email }
                    else if focusedField == .email { focusedField = .password }
                    else { focusedField = nil }
                }
                .padding(.horizontal)
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                Button {
                    if validate() {
                        Task {
                            await register()
                        }
                    }
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView().tint(.deepVelvet)
                        } else {
                            Text("Create Account")
                                .fontWeight(.bold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(name.isEmpty || email.isEmpty || password.isEmpty ? Color.gray.opacity(0.3) : Color.electricPurple)
                    .foregroundColor(.deepVelvet)
                    .cornerRadius(12)
                }
                .disabled(isLoading || name.isEmpty || email.isEmpty || password.isEmpty)
                .padding(.horizontal)
                .padding(.top, 8)
                
                Spacer()
            }
            .padding(.top, 40)
        }
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showDatePicker) {
            ZStack {
                Color.adaptiveBackground.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    HStack {
                        Text("Select Date of Birth")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                        Button("Done") {
                            bornDateSelected = true
                            showDatePicker = false
                        }
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.electricPurple)
                    }
                    .padding(.horizontal)
                    .padding(.top, 24)
                    
                    DatePicker(
                        "",
                        selection: $bornDate,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .colorScheme(.dark)
                    .padding(.horizontal)
                    .onChange(of: bornDate) { _, _ in
                        bornDateSelected = true
                    }
                    
                    Spacer()
                }
            }
            .presentationDetents([.height(300)])
            .presentationDragIndicator(.visible)
        }
    }
    
    private func validate() -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard trimmedName.count >= 3 else {
            withAnimation { errorMessage = "Name must be at least 3 characters." }
            return false
        }
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        guard trimmedEmail.contains("@"), trimmedEmail.contains(".") else {
            withAnimation { errorMessage = "Please enter a valid email address." }
            return false
        }
        guard password.count >= 8 else {
            withAnimation { errorMessage = "Password must be at least 8 characters." }
            return false
        }
        guard password.count <= 32 else {
            withAnimation { errorMessage = "Password must be at most 32 characters." }
            return false
        }
        guard !gender.isEmpty else {
            withAnimation { errorMessage = "Please select your gender." }
            return false
        }
        return true
    }
    
    private func register() async {
        focusedField = nil
        isLoading = true
        errorMessage = ""

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = bornDateSelected ? formatter.string(from: bornDate) : nil

        do {
            try await AuthManager.shared.register(
                name: name.trimmingCharacters(in: .whitespaces),
                email: email.lowercased().trimmingCharacters(in: .whitespaces),
                bornDate: dateStr,
                gender: gender,
                password: password
            )
        } catch {
            withAnimation { errorMessage = error.localizedDescription }
        }
        isLoading = false
    }
}
