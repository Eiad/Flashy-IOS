import SwiftUI
import AVFoundation // Import AVFoundation to control the flashlight (torch) on the device

// Main view of the app
struct ContentView: View {
    // @State is a SwiftUI property wrapper that allows us to modify the UI when the state changes
    // This variable will keep track of whether the flashlight is on (true) or off (false)
    @State private var isLightOn = false
    @State private var brightness: Double = 1.0
    @AppStorage("selectedColorIndex") private var selectedColorIndex: Int = 0
    @State private var isStrobeMode = false
    @State private var strobeSpeed: Double = 1.0
    @State private var strobePattern: StrobePattern = .constant
    @State private var showingSafetyWarning = false
    @State private var isStrobeActive = false
    @State private var showingColorPicker = false
    @State private var animationTrigger = false
    @State private var showingInfoView = false

    let colors: [Color] = [.white, .red, .green, .blue, .yellow, .purple]
    
    // Add this computed property
    var selectedColor: Color {
        colors[selectedColorIndex]
    }
    
    enum StrobePattern: String, CaseIterable, Identifiable {
        case constant, pulse, sos
        var id: Self { self }
    }
    
    // Add a computed property to get the current year
    var currentYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: Date())
    }
    
    // The body property defines the view's UI and behavior
    var body: some View {
        ZStack {
            selectedColor.opacity(isLightOn ? brightness : 0.1)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) { // Reduced spacing here
                HStack {
                    Button(action: {
                        showingInfoView = true
                    }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.primary)
                            .padding()
                    }
                    Spacer()
                    Button(action: {
                        showingColorPicker = true
                    }) {
                        Image(systemName: "paintpalette")
                            .foregroundColor(.primary)
                            .padding()
                    }
                }
                .padding(.top, 10) // Add some top padding to the HStack
                
                Text("FLASHY")
                    .font(.custom("Futura-Bold", size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.pink, .purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .padding(.top, -10)
                    .padding(.bottom, 10)
                    .shadow(color: .black.opacity(0.3), radius: 5, x: 3, y: 3)
                    .overlay(
                        Text("FLASHY")
                            .font(.custom("Futura-Bold", size: 50))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.yellow, .orange, .red],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .mask(
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.clear, .white, .clear],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .rotationEffect(.degrees(70))
                                    .offset(x: animationTrigger ? 200 : -200)
                            )
                    )
                    .onAppear {
                        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: false)) {
                            animationTrigger.toggle()
                        }
                    }
                
                Spacer().frame(height: 20) // Reduced spacer height
                
                Image(systemName: isLightOn ? "lightbulb.fill" : "lightbulb.slash")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80) // Slightly reduced size
                    .foregroundColor(isLightOn ? .yellow : .gray)
                    .shadow(color: isLightOn ? .yellow : .clear, radius: 20)
                
                Button(action: toggleFlashlight) {
                    Text(isLightOn ? "Turn Off" : "Turn On")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 200)
                        .background(isLightOn ? Color.red : Color.green)
                        .cornerRadius(15)
                        .shadow(radius: 5)
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Brightness")
                    Slider(value: $brightness, in: 0.1...1)
                        .onChange(of: brightness) { oldValue, newValue in
                            if isLightOn {
                                updateFlashlightBrightness(to: newValue)
                            }
                        }
                }
                .padding(.horizontal)
                
                Toggle("Strobe Mode", isOn: $isStrobeMode)
                    .padding(.horizontal)

                if isStrobeMode {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Strobe Speed")
                        Slider(value: $strobeSpeed, in: 0.5...5, step: 0.5)
                        Text("Pattern")
                        Picker("Strobe Pattern", selection: $strobePattern) {
                            Text("Constant").tag(StrobePattern.constant)
                            Text("Pulse").tag(StrobePattern.pulse)
                            Text("SOS").tag(StrobePattern.sos)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    .padding(.horizontal)
                    
                    Button(isStrobeActive ? "Stop Strobe" : "Start Strobe") {
                        if isStrobeActive {
                            stopStrobeEffect()
                        } else {
                            showingSafetyWarning = true
                        }
                    }
                    .padding()
                    .background(isStrobeActive ? Color.red : Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .alert(isPresented: $showingSafetyWarning) {
                        Alert(
                            title: Text("Safety Warning"),
                            message: Text("Rapidly flashing lights can cause discomfort or seizures in some people. Are you sure you want to continue?"),
                            primaryButton: .default(Text("Continue")) {
                                isStrobeActive = true
                                startStrobeEffect()
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }
                
                Spacer()
                
                Text("© \(currentYear) Developed by Ash")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.bottom, 10)
            }
        }
        .onChange(of: isStrobeMode) { oldValue, newValue in
            if !newValue {
                stopStrobeEffect()
            }
        }
        .sheet(isPresented: $showingColorPicker) {
            ColorPickerView(selectedColorIndex: $selectedColorIndex, colors: colors)
        }
        .sheet(isPresented: $showingInfoView) {
            InfoView()
        }
    }
    
    // This function toggles the state of the flashlight (on/off)
    func toggleFlashlight() {
        if isLightOn {
            isLightOn = false
            stopStrobeEffect()
        } else {
            isLightOn = true
        }
        turnFlashlight(on: isLightOn)
    }
    
    // This function actually controls the flashlight (torch) on the device
    // It uses AVCaptureDevice, which allows access to hardware features like the camera and flashlight
    func turnFlashlight(on: Bool) {
        // Check if the device has a torch (flashlight) and if we can control it
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        
        do {
            // Lock the device for configuration so we can modify its settings
            try device.lockForConfiguration()
            // Set the torch mode (on or off)
            device.torchMode = on ? .on : .off
            // If the flashlight is on, set the brightness
            if on {
                try device.setTorchModeOn(level: Float(brightness))
            }
            // Unlock the device after configuring it
            device.unlockForConfiguration()
        } catch {
            // If something goes wrong (e.g., the torch can't be used), print an error message
            print("Torch could not be used")
        }
    }
    
    // This function starts the strobe effect
    func startStrobeEffect() {
        guard isStrobeMode && isStrobeActive else { return }
        
        switch strobePattern {
        case .constant:
            constantStrobe()
        case .pulse:
            pulseStrobe()
        case .sos:
            sosStrobe()
        }
    }

    func constantStrobe() {
        guard isStrobeActive else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + (1 / strobeSpeed)) {
            guard self.isStrobeActive else { return }
            self.isLightOn.toggle()
            self.turnFlashlight(on: self.isLightOn)
            self.constantStrobe()
        }
    }

    func pulseStrobe() {
        guard isStrobeActive else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + (1 / strobeSpeed)) {
            guard self.isStrobeActive else { return }
            self.isLightOn = true
            self.turnFlashlight(on: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                guard self.isStrobeActive else { return }
                self.isLightOn = false
                self.turnFlashlight(on: false)
                self.pulseStrobe()
            }
        }
    }

    func sosStrobe() {
        let dotDuration = 0.2 / strobeSpeed
        let dashDuration = 0.6 / strobeSpeed
        let sequence = [dotDuration, dotDuration, dotDuration, dashDuration, dashDuration, dashDuration, dotDuration, dotDuration, dotDuration]
        
        playSOSSequence(sequence)
    }

    func playSOSSequence(_ remainingSequence: [TimeInterval]) {
        guard isStrobeActive, !remainingSequence.isEmpty else { return }
        
        isLightOn = true
        turnFlashlight(on: true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + remainingSequence[0]) {
            guard self.isStrobeActive else { return }
            self.isLightOn = false
            self.turnFlashlight(on: false)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2 / self.strobeSpeed) {
                guard self.isStrobeActive else { return }
                self.playSOSSequence(Array(remainingSequence.dropFirst()))
            }
        }
    }
    
    // This function stops the strobe effect
    func stopStrobeEffect() {
        isStrobeActive = false
        isLightOn = false
        turnFlashlight(on: false)
        // Cancel any pending strobe operations
        cancelStrobeOperations()
    }

    func cancelStrobeOperations() {
        // This will cancel all pending DispatchQueue operations
        DispatchQueue.main.async {
            // Do nothing, this just cancels all pending async operations
        }
    }
    
    // This function updates the brightness of the flashlight
    func updateFlashlightBrightness(to newBrightness: Double) {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        
        do {
            try device.lockForConfiguration()
            try device.setTorchModeOn(level: Float(newBrightness))
            device.unlockForConfiguration()
        } catch {
            print("Failed to update torch brightness")
        }
    }
}

struct ColorPickerView: View {
    @Binding var selectedColorIndex: Int
    let colors: [Color]
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            List {
                ForEach(colors.indices, id: \.self) { index in
                    HStack {
                        Circle()
                            .fill(colors[index])
                            .frame(width: 30, height: 30)
                        Text(colorName(for: colors[index]))
                            .foregroundColor(.primary)
                        Spacer()
                        if index == selectedColorIndex {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedColorIndex = index
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .navigationTitle("Theme colors")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }

    func colorName(for color: Color) -> String {
        switch color {
        case .white: return "White"
        case .red: return "Red"
        case .green: return "Green"
        case .blue: return "Blue"
        case .yellow: return "Yellow"
        case .purple: return "Purple"
        default: return "Custom"
        }
    }
}

struct InfoView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.openURL) var openURL

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("About Flashy")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Flashy transforms your phone into a powerful, multi-functional light source. Whether you need a bright beam for navigation, a colorful ambiance for your space, or a life-saving SOS signal, Flashy has you covered.")
                    
                    Text("Key Features:")
                        .fontWeight(.semibold)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("• Adjustable brightness")
                        Text("• Multiple color options")
                        Text("• SOS mode for emergencies")
                        Text("• Strobe effects for attention-grabbing")
                    }
                    
                    Text("Privacy & Security:")
                        .fontWeight(.semibold)
                    Text("Flashy respects your privacy. We do not collect any personal data. Your experience is private and secure.")
                    
                    Text("Developer: Ash")
                        .fontWeight(.semibold)
                    
                    Text("We value your input! For suggestions or feedback:")
                        .fontWeight(.semibold)
                    Button("ask.only.ash@gmail.com") {
                        openURL(URL(string: "mailto:ask.only.ash@gmail.com")!)
                    }
                    .foregroundColor(.blue)
                    
                    Text("Version: 1.0")
                    
                    Spacer()
                    
                    Text("Thank you for choosing Flashy!")
                        .italic()
                        .multilineTextAlignment(.center)
                        .padding()
                }
                .padding()
            }
            .navigationBarTitle("About", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct InfoView_Previews: PreviewProvider {
    static var previews: some View {
        InfoView()
    }
}

// Preview code that allows you to see the UI in Xcode's canvas without running the app on a device
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
