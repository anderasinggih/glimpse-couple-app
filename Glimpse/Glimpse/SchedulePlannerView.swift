import SwiftUI
import EventKit
import UserNotifications

// MARK: - Alarm / Calendar Manager
class AlarmManager {
    static let shared = AlarmManager()
    private let eventStore = EKEventStore()
    
    func requestAccessAndAddEvent(title: String, date: Date, reminderMinutes: Int, note: String, completion: @escaping (Bool, String) -> Void) {
        eventStore.requestFullAccessToEvents { granted, error in
            if granted && error == nil {
                do {
                    // Check duplicate first
                    let predicate = self.eventStore.predicateForEvents(withStart: date.addingTimeInterval(-3600), end: date.addingTimeInterval(3600), calendars: nil)
                    let existingEvents = self.eventStore.events(matching: predicate)
                    let eventTitle = "Glimpse Date: \(title)"
                    
                    if existingEvents.contains(where: { $0.title == eventTitle }) {
                        // Play gentle alert haptic feedback
                        DispatchQueue.main.async {
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.warning)
                        }
                        completion(true, "Already added to your Apple Calendar! 📅")
                        return
                    }
                    
                    let success = try self.createCalendarEvent(title: title, date: date, reminderMinutes: reminderMinutes, note: note)
                    if success {
                        completion(true, "Successfully added to your Apple Calendar with alarm!")
                    } else {
                        completion(false, "Failed to create event.")
                    }
                } catch {
                    completion(false, error.localizedDescription)
                }
            } else {
                completion(false, "Calendar permission denied. Please allow it in settings.")
            }
        }
    }
    
    private func createCalendarEvent(title: String, date: Date, reminderMinutes: Int, note: String) throws -> Bool {
        let event = EKEvent(eventStore: eventStore)
        event.title = "Glimpse Date: \(title)"
        event.startDate = date
        event.endDate = date.addingTimeInterval(7200) // Default 2 hours kencan length
        event.notes = note
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        // Add Native Alert Alarm (Triggered reminderMinutes before kencan)
        let alarm = EKAlarm(relativeOffset: TimeInterval(-reminderMinutes * 60))
        event.addAlarm(alarm)
        
        try eventStore.save(event, span: .thisEvent)
        
        // Haptic feedback
        DispatchQueue.main.async {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
        return true
    }
}

// MARK: - Schedule Planner Main View
struct SchedulePlannerView: View {
    @Bindable var auth = AuthManager.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var activeTab = 0 // 0: Plan, 1: Upcoming, 2: History
    
    // Form States
    @State private var title = ""
    @State private var selectedDate = Date().addingTimeInterval(86400) // Default tomorrow
    @State private var reminderMinutes = 20
    @State private var note = ""
    @State private var isSubmitting = false
    
    // Lists States
    @State private var schedulesList: [GlimpseSchedule] = []
    @State private var isLoadingSchedules = false
    
    // Status Alert States
    @State private var statusMessage = ""
    @State private var showStatusAlert = false
    @State private var isSuccessAlert = true
    
    let reminderOptions = [5, 10, 20, 30, 45, 60]
    
    var body: some View {
        ZStack {
            Color.adaptiveBackground.ignoresSafeArea()
                .onTapGesture {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            
            VStack(spacing: 0) {
                // Header Bar
                HStack {
                    Button {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(8)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text("Couple Schedules")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Empty spacer to center the title
                    Color.clear.frame(width: 32, height: 32)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.black.opacity(0.15))
                
                // Tabs Selector
                HStack(spacing: 14) {
                    TabButton(title: "Plan Date", icon: "calendar.badge.plus", isActive: activeTab == 0) {
                        activeTab = 0
                    }
                    TabButton(title: "Upcoming", icon: "clock.fill", isActive: activeTab == 1) {
                        activeTab = 1
                    }
                    TabButton(title: "History", icon: "archivebox.fill", isActive: activeTab == 2) {
                        activeTab = 2
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.08))
                
                // Content TabView
                ZStack {
                    if activeTab == 0 {
                        planFormView
                    } else if activeTab == 1 {
                        upcomingListView
                    } else {
                        historyListView
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            // Premium Overlay Toast Notification
            if showStatusAlert {
                VStack {
                    HStack(spacing: 12) {
                        Image(systemName: isSuccessAlert ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(isSuccessAlert ? .activeCyan : .orange)
                        
                        Text(statusMessage)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.black.opacity(0.85))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSuccessAlert ? Color.activeCyan.opacity(0.4) : Color.orange.opacity(0.4), lineWidth: 1.5)
                    )
                    .shadow(color: Color.black.opacity(0.4), radius: 10, y: 5)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(99)
            }
        }
        .task {
            await loadSchedules()
        }
    }
    
    // MARK: - Subviews
    
    // Tab Button Helper
    private func TabButton(title: String, icon: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                    Text(title)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                }
                .foregroundColor(isActive ? .activeCyan : .white.opacity(0.4))
                
                // Indicator line matching exactly the text/icon width
                Rectangle()
                    .fill(isActive ? .activeCyan : Color.clear)
                    .frame(height: 3)
                    .cornerRadius(1.5)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // Tab 0: Plan Form View
    private var planFormView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                
                // Form Card
                VStack(alignment: .leading, spacing: 18) {
                    
                    // Title Input
                    VStack(alignment: .leading, spacing: 6) {
                        Text("What are we doing?")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.4))
                        
                        TextField("e.g. Dinner date at a cozy restaurant", text: $title)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    }
                    
                    // Date & Time Picker
                    VStack(alignment: .leading, spacing: 6) {
                        Text("When")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.4))
                        
                        DatePicker("", selection: $selectedDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .colorScheme(.dark)
                            .background(Color.white.opacity(0.02))
                            .cornerRadius(12)
                    }
                    
                    // Reminder Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Alarm reminder")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.4))
                        
                        HStack(spacing: 8) {
                            ForEach(reminderOptions, id: \.self) { minutes in
                                Button {
                                    reminderMinutes = minutes
                                } label: {
                                    Text("\(minutes)m")
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundColor(reminderMinutes == minutes ? .deepVelvet : .white)
                                        .padding(.vertical, 8)
                                        .frame(maxWidth: .infinity)
                                        .background(reminderMinutes == minutes ? Color.activeCyan : Color.white.opacity(0.08))
                                        .cornerRadius(10)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    
                    // Notes / Description
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Notes (optional)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.4))
                        
                        TextField("e.g. Don't forget to wear your favorite jacket, love!", text: $note)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    }
                    
                }
                .padding(20)
                .background(Color.white.opacity(0.04))
                .cornerRadius(24)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                
                // Submit Button
                Button {
                    Task {
                        await submitSchedule()
                    }
                } label: {
                    HStack {
                        if isSubmitting {
                            ProgressView()
                                .tint(.deepVelvet)
                                .scaleEffect(0.9)
                        } else {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 14))
                            Text("Send Invitation")
                        }
                    }
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(title.trimmingCharacters(in: .whitespaces).isEmpty ? .white.opacity(0.3) : .deepVelvet)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(title.trimmingCharacters(in: .whitespaces).isEmpty ? Color.white.opacity(0.1) : Color.activeCyan)
                    .cornerRadius(16)
                    .shadow(color: title.trimmingCharacters(in: .whitespaces).isEmpty ? Color.clear : Color.activeCyan.opacity(0.3), radius: 10)
                }
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || isSubmitting)
                .buttonStyle(PlainButtonStyle())
                .padding(.bottom, 30)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
        .background(
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
        )
    }
    
    // Tab 1: Upcoming ListView
    private var upcomingListView: some View {
        ZStack {
            if isLoadingSchedules {
                ProgressView().tint(.electricPurple)
            } else {
                let upcoming = schedulesList.filter { $0.scheduledDate >= Date() && $0.status != "declined" }
                
                if upcoming.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "calendar")
                            .font(.system(size: 48))
                            .foregroundColor(.white.opacity(0.25))
                        Text("No upcoming dates planned.")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.5))
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 14) {
                            ForEach(upcoming) { schedule in
                                ScheduleRow(schedule: schedule)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    }
                }
            }
        }
    }
    
    // Tab 2: History ListView
    private var historyListView: some View {
        ZStack {
            if isLoadingSchedules {
                ProgressView().tint(.electricPurple)
            } else {
                let history = schedulesList.filter { $0.scheduledDate < Date() || $0.status == "declined" }
                
                if history.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "archivebox")
                            .font(.system(size: 48))
                            .foregroundColor(.white.opacity(0.25))
                        Text("No kencan history yet. Let's make some memories!")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 14) {
                            ForEach(history) { schedule in
                                ScheduleRow(schedule: schedule, isPast: true)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    }
                }
            }
        }
    }
    
    // MARK: - Schedule Row Component
    private func ScheduleRow(schedule: GlimpseSchedule, isPast: Bool = false) -> some View {
        let isCreator = schedule.creator_id == (auth.currentUser?.id ?? 0)
        let alarmTime = schedule.scheduledDate.addingTimeInterval(TimeInterval(-schedule.reminder_minutes * 60))
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(schedule.title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(schedule.scheduledDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.activeCyan)
                    
                    if !schedule.status.isEmpty {
                        // Badge Status
                        HStack(spacing: 4) {
                            Image(systemName: schedule.status == "accepted" ? "heart.fill" : (schedule.status == "declined" ? "xmark.circle.fill" : "hourglass"))
                                .font(.system(size: 9))
                            Text(schedule.status.capitalized)
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(schedule.status == "accepted" ? .pink : (schedule.status == "declined" ? .red : .orange))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(schedule.status == "accepted" ? Color.pink.opacity(0.1) : (schedule.status == "declined" ? Color.red.opacity(0.1) : Color.orange.opacity(0.1)))
                        .cornerRadius(6)
                        .padding(.top, 2)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    if isCreator {
                        Button {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            Task {
                                await deleteSchedule(id: schedule.id)
                            }
                        } label: {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.red.opacity(0.85))
                                .padding(8)
                                .background(Color.red.opacity(0.12))
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // Big Calendar Icon indicator
                    VStack(spacing: 2) {
                        Text(schedule.scheduledDate.formatted(.dateTime.day()))
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        Text(schedule.scheduledDate.formatted(.dateTime.month(.abbreviated)))
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(10)
                }
            }
            
            // Reminder info
            HStack(spacing: 6) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 10))
                Text("Alarm: \(schedule.reminder_minutes)m before (\(alarmTime.formatted(date: .omitted, time: .shortened)))")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
            }
            .foregroundColor(.white.opacity(0.5))
            
            // Pending RSVP Buttons for partner
            if !isPast && schedule.status == "pending" && !isCreator {
                HStack(spacing: 12) {
                    Button {
                        Task { await respondToSchedule(id: schedule.id, accept: true) }
                    } label: {
                        Text("Accept Date")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.deepVelvet)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.activeCyan)
                            .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button {
                        Task { await respondToSchedule(id: schedule.id, accept: false) }
                    } label: {
                        Text("Decline")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.top, 4)
            }
            
            // Set Alarm Button for accepted schedules
            if !isPast && schedule.status == "accepted" {
                Button {
                    let date = schedule.scheduledDate
                    AlarmManager.shared.requestAccessAndAddEvent(
                        title: schedule.title,
                        date: date,
                        reminderMinutes: schedule.reminder_minutes,
                        note: "Scheduled with Glimpse"
                    ) { success, msg in
                        DispatchQueue.main.async {
                            isSuccessAlert = success
                            statusMessage = msg
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                                showStatusAlert = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                withAnimation {
                                    showStatusAlert = false
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "alarm.fill")
                            .font(.system(size: 12))
                        Text("Set iPhone Alarm & Calendar alert")
                    }
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.top, 4)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(isPast ? 0.02 : 0.05))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(isPast ? Color.clear : Color.white.opacity(0.08), lineWidth: 1)
        )
    }
    
    // MARK: - Logic Operations
    private func loadSchedules() async {
        isLoadingSchedules = true
        do {
            schedulesList = try await auth.fetchSchedules()
        } catch {
            print("❌ Failed to load schedules: \(error)")
        }
        isLoadingSchedules = false
    }
    
    private func submitSchedule() async {
        isSubmitting = true
        do {
            try await auth.createSchedule(title: title, date: selectedDate, reminderMinutes: reminderMinutes)
            
            // Success Trigger
            title = ""
            note = ""
            isSuccessAlert = true
            statusMessage = "Date invitation sent successfully! 🚀"
            
            withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                showStatusAlert = true
            }
            
            // Reload list and switch tab to Upcoming
            await loadSchedules()
            withAnimation {
                activeTab = 1
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation {
                    showStatusAlert = false
                }
            }
        } catch {
            isSuccessAlert = false
            statusMessage = error.localizedDescription
            withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                showStatusAlert = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation {
                    showStatusAlert = false
                }
            }
        }
        isSubmitting = false
    }
    
    private func respondToSchedule(id: Int, accept: Bool) async {
        do {
            try await auth.respondToSchedule(id: id, accept: accept)
            isSuccessAlert = true
            statusMessage = accept ? "Date Accepted! Set your alarm now." : "Date invitation declined."
            
            withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                showStatusAlert = true
            }
            
            await loadSchedules()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation {
                    showStatusAlert = false
                }
            }
        } catch {
            isSuccessAlert = false
            statusMessage = error.localizedDescription
            withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                showStatusAlert = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation {
                    showStatusAlert = false
                }
            }
        }
    }
    
    private func deleteSchedule(id: Int) async {
        do {
            try await auth.deleteSchedule(id: id)
            isSuccessAlert = true
            statusMessage = "Schedule invitation deleted! 🗑️"
            
            withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                showStatusAlert = true
            }
            
            await loadSchedules()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation {
                    showStatusAlert = false
                }
            }
        } catch {
            isSuccessAlert = false
            statusMessage = error.localizedDescription
            withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                showStatusAlert = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation {
                    showStatusAlert = false
                }
            }
        }
    }
}
