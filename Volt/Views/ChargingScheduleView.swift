import SwiftUI

struct ChargingScheduleView: View {
    @ObservedObject var voltStore: VoltStore
    @State private var showingAddSheet = false

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Charging Schedules")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Button(action: { showingAddSheet = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Add")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Theme.primaryBlue)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }

            if voltStore.schedules.isEmpty {
                emptyState
            } else {
                ForEach(voltStore.schedules) { schedule in
                    ScheduleRowView(
                        schedule: schedule,
                        onToggle: { voltStore.toggleSchedule(schedule) },
                        onDelete: { voltStore.deleteSchedule(schedule.id) }
                    )
                }
            }
        }
        .padding(16)
        .sheet(isPresented: $showingAddSheet) {
            AddScheduleSheet(voltStore: voltStore, isPresented: $showingAddSheet)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "clock.badge")
                .font(.system(size: 24))
                .foregroundColor(Theme.textSecondary)
            Text("No schedules yet")
                .font(.system(size: 13))
                .foregroundColor(Theme.textSecondary)
            Text("Add a schedule to automatically manage charging")
                .font(.system(size: 11))
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}

// MARK: - Schedule Row View

struct ScheduleRowView: View {
    let schedule: ChargingSchedule
    let onToggle: () -> Void
    let onDelete: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 12) {
            // Toggle
            Toggle("", isOn: Binding(
                get: { schedule.isEnabled },
                set: { _ in onToggle() }
            ))
            .toggleStyle(.switch)
            .controlSize(.small)

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(schedule.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(schedule.isEnabled ? Theme.textPrimary : Theme.textSecondary)

                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                    Text("\(schedule.startTimeString) – \(schedule.endTimeString)")
                        .font(.system(size: 11))
                    Text("·")
                        .foregroundColor(Theme.textSecondary)
                    Text("Limit: \(schedule.chargeLimit)%")
                        .font(.system(size: 11))
                }
                .foregroundColor(schedule.isEnabled ? Theme.textSecondary : Theme.textSecondary.opacity(0.6))

                Text(schedule.daysString)
                    .font(.system(size: 10))
                    .foregroundColor(schedule.isEnabled ? Theme.primaryBlue : Theme.textSecondary.opacity(0.5))
            }

            Spacer()

            // Status indicator
            if schedule.isActiveNow() {
                Text("ACTIVE")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Theme.accentGreen)
                    .cornerRadius(4)
            }

            // Delete button
            if isHovering {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.accentRed)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(Theme.secondaryBg)
        .cornerRadius(8)
        .opacity(schedule.isEnabled ? 1 : 0.7)
        .onHover { hovering in isHovering = hovering }
    }
}

// MARK: - Add Schedule Sheet

struct AddScheduleSheet: View {
    @ObservedObject var voltStore: VoltStore
    @Binding var isPresented: Bool

    @State private var name = "Night Charge"
    @State private var startHour = 23
    @State private var startMinute = 0
    @State private var endHour = 7
    @State private var endMinute = 0
    @State private var chargeLimit = 80
    @State private var selectedDays: Set<Int> = [1, 2, 3, 4, 5, 6, 7]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("New Charging Schedule")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(16)

            Divider()

            ScrollView {
                VStack(spacing: 16) {
                    // Name
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Name")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Theme.textSecondary)
                        TextField("Schedule name", text: $name)
                            .textFieldStyle(.roundedBorder)
                    }

                    // Time range
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Time Window")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Theme.textSecondary)

                        HStack(spacing: 16) {
                            // Start time
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Start")
                                    .font(.system(size: 10))
                                    .foregroundColor(Theme.textSecondary)
                                HStack {
                                    Picker("", selection: $startHour) {
                                        ForEach(0..<24, id: \.self) { hour in
                                            Text(String(format: "%02d", hour)).tag(hour)
                                        }
                                    }
                                    .labelsHidden()
                                    .frame(width: 60)
                                    Text(":")
                                    Picker("", selection: $startMinute) {
                                        ForEach([0, 15, 30, 45], id: \.self) { min in
                                            Text(String(format: "%02d", min)).tag(min)
                                        }
                                    }
                                    .labelsHidden()
                                    .frame(width: 60)
                                }
                            }

                            Text("–")
                                .foregroundColor(Theme.textSecondary)

                            // End time
                            VStack(alignment: .leading, spacing: 4) {
                                Text("End")
                                    .font(.system(size: 10))
                                    .foregroundColor(Theme.textSecondary)
                                HStack {
                                    Picker("", selection: $endHour) {
                                        ForEach(0..<24, id: \.self) { hour in
                                            Text(String(format: "%02d", hour)).tag(hour)
                                        }
                                    }
                                    .labelsHidden()
                                    .frame(width: 60)
                                    Text(":")
                                    Picker("", selection: $endMinute) {
                                        ForEach([0, 15, 30, 45], id: \.self) { min in
                                            Text(String(format: "%02d", min)).tag(min)
                                        }
                                    }
                                    .labelsHidden()
                                    .frame(width: 60)
                                }
                            }
                        }
                    }

                    // Days
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Days")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Theme.textSecondary)
                        HStack(spacing: 6) {
                            ForEach([("S", 1), ("M", 2), ("T", 3), ("W", 4), ("T", 5), ("F", 6), ("S", 7)], id: \.1) { label, day in
                                Button {
                                    if selectedDays.contains(day) {
                                        selectedDays.remove(day)
                                    } else {
                                        selectedDays.insert(day)
                                    }
                                } label: {
                                    Text(label)
                                        .font(.system(size: 11, weight: .medium))
                                        .frame(width: 32, height: 32)
                                        .background(selectedDays.contains(day) ? Theme.primaryBlue : Theme.secondaryBg)
                                        .foregroundColor(selectedDays.contains(day) ? .white : Theme.textSecondary)
                                        .cornerRadius(6)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Charge limit
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Charge Limit")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Theme.textSecondary)
                            Spacer()
                            Text("\(chargeLimit)%")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(Theme.primaryBlue)
                        }
                        Slider(value: Binding(
                            get: { Double(chargeLimit) },
                            set: { chargeLimit = Int($0) }
                        ), in: 50...100, step: 5)
                    }
                }
                .padding(16)
            }

            Divider()

            // Buttons
            HStack {
                Spacer()
                Button("Cancel") { isPresented = false }
                    .buttonStyle(.bordered)
                Button("Add Schedule") {
                    addSchedule()
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(16)
        }
        .frame(width: 380, height: 420)
    }

    private func addSchedule() {
        let schedule = ChargingSchedule(
            name: name,
            startHour: startHour,
            startMinute: startMinute,
            endHour: endHour,
            endMinute: endMinute,
            days: selectedDays,
            chargeLimit: chargeLimit,
            isEnabled: true
        )
        voltStore.addSchedule(schedule)
    }
}
