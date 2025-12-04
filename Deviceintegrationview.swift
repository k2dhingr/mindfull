import SwiftUI
import HealthKit

// MARK: - Device Integration View
// Shows connected devices and future biosensor support

struct DeviceIntegrationView: View {
    @EnvironmentObject var healthManager: HealthDataManager
    @State private var connectedDevices: [ConnectedDevice] = []
    @State private var showAddDevice = false
    @State private var isScanning = false
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.2, blue: 0.3),
                    Color(red: 0.15, green: 0.25, blue: 0.35)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Connected Devices
                    connectedDevicesSection
                    
                    // Supported Devices
                    supportedDevicesSection
                    
                    // Coming Soon
                    comingSoonSection
                    
                    // Privacy Note
                    privacyNote
                }
                .padding(20)
            }
        }
        .navigationTitle("Devices")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            loadConnectedDevices()
        }
        .sheet(isPresented: $showAddDevice) {
            AddDeviceSheet(isScanning: $isScanning)
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(red: 0.4, green: 0.8, blue: 0.6).opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "applewatch.and.arrow.forward")
                    .font(.system(size: 36))
                    .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
            }
            
            Text("Connected Devices")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            Text("Sync health data from your wearables and biosensors")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }
    
    // MARK: - Connected Devices
    
    private var connectedDevicesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Active Connections")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: { showAddDevice = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
                }
            }
            
            if connectedDevices.isEmpty {
                // No devices connected
                HStack(spacing: 16) {
                    Image(systemName: "antenna.radiowaves.left.and.right.slash")
                        .font(.system(size: 32))
                        .foregroundColor(.white.opacity(0.4))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("No devices connected")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text("Tap + to add a device")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    Spacer()
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.white.opacity(0.1), lineWidth: 1)
                        )
                )
            } else {
                ForEach(connectedDevices) { device in
                    ConnectedDeviceCard(device: device)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Supported Devices
    
    private var supportedDevicesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Supported Devices")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            // Apple Watch
            SupportedDeviceRow(
                icon: "applewatch",
                name: "Apple Watch",
                description: "Heart rate, HRV, sleep, activity, ECG, blood oxygen",
                status: .supported,
                color: .pink
            )
            
            // Oura Ring
            SupportedDeviceRow(
                icon: "circle.circle",
                name: "Oura Ring",
                description: "Sleep stages, readiness, activity via HealthKit",
                status: .supported,
                color: .purple
            )
            
            // Whoop
            SupportedDeviceRow(
                icon: "waveform.path.ecg",
                name: "WHOOP",
                description: "Strain, recovery, sleep performance via HealthKit",
                status: .supported,
                color: .green
            )
            
            // Garmin
            SupportedDeviceRow(
                icon: "figure.run",
                name: "Garmin",
                description: "Workouts, heart rate, sleep via Garmin Connect",
                status: .supported,
                color: .blue
            )
            
            // Fitbit
            SupportedDeviceRow(
                icon: "heart.fill",
                name: "Fitbit",
                description: "Steps, heart rate, sleep via HealthKit sync",
                status: .supported,
                color: .cyan
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Coming Soon (Biosensors)
    
    private var comingSoonSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Coming Soon")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("BETA")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color(red: 0.4, green: 0.8, blue: 0.6))
                    )
            }
            
            // Freestyle Libre
            SupportedDeviceRow(
                icon: "drop.fill",
                name: "FreeStyle Libre",
                description: "Continuous glucose monitoring (CGM)",
                status: .comingSoon,
                color: .yellow
            )
            
            // Dexcom
            SupportedDeviceRow(
                icon: "waveform.path",
                name: "Dexcom G7",
                description: "Real-time glucose readings & trends",
                status: .comingSoon,
                color: .orange
            )
            
            // Pulse Oximeter
            SupportedDeviceRow(
                icon: "lungs.fill",
                name: "Pulse Oximeters",
                description: "SpO2, pulse rate (Masimo, Nonin, etc.)",
                status: .comingSoon,
                color: .red
            )
            
            // Blood Pressure
            SupportedDeviceRow(
                icon: "heart.text.square.fill",
                name: "Blood Pressure Monitors",
                description: "Omron, Withings, QardioArm integration",
                status: .comingSoon,
                color: .pink
            )
            
            // Smart Scale
            SupportedDeviceRow(
                icon: "scalemass.fill",
                name: "Smart Scales",
                description: "Weight, body composition, BMI tracking",
                status: .comingSoon,
                color: .indigo
            )
            
            // Continuous Temp
            SupportedDeviceRow(
                icon: "thermometer.medium",
                name: "Temp Sensors",
                description: "Oura, ŌURA, TempDrop continuous temperature",
                status: .comingSoon,
                color: .mint
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Privacy Note
    
    private var privacyNote: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 24))
                .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Privacy First")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("All device data is processed on-device by our AI. Your health information never leaves your phone.")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.4, green: 0.8, blue: 0.6).opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(red: 0.4, green: 0.8, blue: 0.6).opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.bottom, 40)
    }
    
    // MARK: - Load Devices
    
    private func loadConnectedDevices() {
        // Query HealthKit for source devices
        let healthStore = HKHealthStore()
        
        // Check if Apple Watch is paired
        if HKHealthStore.isHealthDataAvailable() {
            // In a real app, you'd query HKSourceQuery to find connected devices
            // For demo, we'll show Apple Watch if health data exists
            
            let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
            let query = HKSourceQuery(sampleType: stepType, samplePredicate: nil) { _, sources, _ in
                DispatchQueue.main.async {
                    if let sources = sources {
                        for source in sources {
                            if source.name.contains("Watch") || source.bundleIdentifier.contains("watch") {
                                let device = ConnectedDevice(
                                    name: "Apple Watch",
                                    type: .appleWatch,
                                    lastSync: Date(),
                                    batteryLevel: nil,
                                    isConnected: true
                                )
                                if !connectedDevices.contains(where: { $0.name == device.name }) {
                                    connectedDevices.append(device)
                                }
                            }
                        }
                    }
                }
            }
            healthStore.execute(query)
        }
    }
}

// MARK: - Connected Device Model

struct ConnectedDevice: Identifiable {
    let id = UUID()
    let name: String
    let type: DeviceType
    let lastSync: Date
    let batteryLevel: Int?
    let isConnected: Bool
    
    enum DeviceType {
        case appleWatch
        case ouraRing
        case whoop
        case garmin
        case fitbit
        case glucoseMonitor
        case pulseOximeter
        case bloodPressure
        case scale
        
        var icon: String {
            switch self {
            case .appleWatch: return "applewatch"
            case .ouraRing: return "circle.circle"
            case .whoop: return "waveform.path.ecg"
            case .garmin: return "figure.run"
            case .fitbit: return "heart.fill"
            case .glucoseMonitor: return "drop.fill"
            case .pulseOximeter: return "lungs.fill"
            case .bloodPressure: return "heart.text.square.fill"
            case .scale: return "scalemass.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .appleWatch: return .pink
            case .ouraRing: return .purple
            case .whoop: return .green
            case .garmin: return .blue
            case .fitbit: return .cyan
            case .glucoseMonitor: return .yellow
            case .pulseOximeter: return .red
            case .bloodPressure: return .pink
            case .scale: return .indigo
            }
        }
    }
    
    var lastSyncText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastSync, relativeTo: Date())
    }
}

// MARK: - Connected Device Card

struct ConnectedDeviceCard: View {
    let device: ConnectedDevice
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(device.type.color.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: device.type.icon)
                    .font(.system(size: 24))
                    .foregroundColor(device.type.color)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(device.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Circle()
                        .fill(device.isConnected ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                }
                
                Text("Last sync: \(device.lastSyncText)")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            // Battery (if available)
            if let battery = device.batteryLevel {
                HStack(spacing: 4) {
                    Image(systemName: batteryIcon(for: battery))
                        .font(.system(size: 16))
                    Text("\(battery)%")
                        .font(.system(size: 13))
                }
                .foregroundColor(batteryColor(for: battery))
            }
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.4))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.08))
        )
    }
    
    private func batteryIcon(for level: Int) -> String {
        switch level {
        case 0..<20: return "battery.0"
        case 20..<50: return "battery.25"
        case 50..<75: return "battery.50"
        case 75..<100: return "battery.75"
        default: return "battery.100"
        }
    }
    
    private func batteryColor(for level: Int) -> Color {
        switch level {
        case 0..<20: return .red
        case 20..<50: return .orange
        default: return .green
        }
    }
}

// MARK: - Supported Device Row

enum DeviceStatus {
    case supported
    case comingSoon
    case beta
}

struct SupportedDeviceRow: View {
    let icon: String
    let name: String
    let description: String
    let status: DeviceStatus
    let color: Color
    
    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                    
                    if status == .comingSoon {
                        Text("SOON")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(.white.opacity(0.2))
                            )
                    }
                }
                
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Status indicator
            if status == .supported {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Device Sheet

struct AddDeviceSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var isScanning: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.1, green: 0.2, blue: 0.3).ignoresSafeArea()
                
                VStack(spacing: 32) {
                    // Scanning animation
                    ZStack {
                        ForEach(0..<3) { i in
                            Circle()
                                .stroke(Color(red: 0.4, green: 0.8, blue: 0.6).opacity(0.3), lineWidth: 2)
                                .frame(width: CGFloat(100 + i * 50), height: CGFloat(100 + i * 50))
                                .scaleEffect(isScanning ? 1.2 : 1.0)
                                .opacity(isScanning ? 0 : 1)
                                .animation(
                                    .easeInOut(duration: 1.5)
                                    .repeatForever(autoreverses: false)
                                    .delay(Double(i) * 0.3),
                                    value: isScanning
                                )
                        }
                        
                        Circle()
                            .fill(Color(red: 0.4, green: 0.8, blue: 0.6).opacity(0.2))
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 40))
                            .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
                    }
                    .frame(height: 220)
                    
                    VStack(spacing: 12) {
                        Text(isScanning ? "Scanning for devices..." : "Add a Device")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Make sure your device is nearby and Bluetooth is enabled")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    
                    // Scan button
                    Button(action: {
                        withAnimation {
                            isScanning.toggle()
                        }
                    }) {
                        Text(isScanning ? "Stop Scanning" : "Start Scanning")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                RoundedRectangle(cornerRadius: 27)
                                    .fill(Color(red: 0.4, green: 0.8, blue: 0.6))
                            )
                    }
                    .padding(.horizontal, 40)
                    
                    // HealthKit sync option
                    VStack(spacing: 16) {
                        Text("Or sync via Apple Health")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.5))
                        
                        Button(action: {
                            // Open Health app
                            if let url = URL(string: "x-apple-health://") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.red)
                                Text("Open Apple Health")
                            }
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(.white.opacity(0.1))
                            )
                        }
                    }
                    
                    Spacer()
                }
                .padding(.top, 40)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.6))
                }
            }
        }
        .onAppear {
            isScanning = true
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        DeviceIntegrationView()
            .environmentObject(HealthDataManager())
    }
}

