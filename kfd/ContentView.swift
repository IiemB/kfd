import SwiftUI

class Tweak: ObservableObject, Identifiable {
    var id: String

    let valueKey, label, inActiveIcon, activeIcon: String

    @Published var isEnabled = false

    init(valueKey: String, label: String, inActiveIcon: String, activeIcon: String) {
        self.id = valueKey

        self.valueKey = valueKey
        self.label = label
        self.inActiveIcon = inActiveIcon
        self.activeIcon = activeIcon
        self.isEnabled = UserDefaults.standard.bool(forKey: valueKey)
    }
}

class TweaksSettings: ObservableObject {

    @Published var tweaks: [Tweak]

    init() {
        self.tweaks = [
            Tweak(valueKey: "HideDock", label: "Hide Dock", inActiveIcon: "eye", activeIcon: "eye.slash"),
            Tweak(valueKey: "hidehomebar", label: "Hide Home Bar", inActiveIcon: "eye", activeIcon: "eye.slash"),
            Tweak(valueKey: "enableHideNotifs", label: "Hide notification and media player background", inActiveIcon: "eye", activeIcon: "eye.slash"),
            Tweak(valueKey: "mutecam", label: "Mute camera", inActiveIcon: "speaker.wave.2", activeIcon: "speaker.slash"),
            Tweak(valueKey: "enableresset", label: "Enable iPhone 14 Pro Resolution", inActiveIcon: "iphone.gen3.circle", activeIcon: "iphone.gen3.circle.fill"),
            Tweak(valueKey: "enableCustomFont", label: "Enable Custom Font", inActiveIcon: "a.circle", activeIcon: "a.circle.fill"),
            Tweak(valueKey: "enableCCTweaks", label: "Enable CC Custom Icons", inActiveIcon: "switch.2", activeIcon: "switch.2"),
            Tweak(valueKey: "enableLSTweaks", label: "Enable Lockscreen Custom Icons", inActiveIcon: "lock", activeIcon: "lock.fill"),
        ]
    }

}

struct ContentView: View {
    @State private var kfd: UInt64 = 0

    @StateObject var tweakSettings = TweaksSettings()

    @State private var puafPages = 2048
    @State private var puafMethod = 1
    @State private var kreadMethod = 1
    @State private var kwriteMethod = 1

    var puafPagesOptions = [16, 32, 64, 128, 256, 512, 1024, 2048]
    var puafMethodOptions = ["physpuppet", "smith"]
    var kreadMethodOptions = ["kqueue_workloop_ctl", "sem_open"]
    var kwriteMethodOptions = ["dup", "sem_open"]

    @State private var isSettingsPopoverPresented = false // Track the visibility of the settings popup

    var body: some View {
        NavigationView {
            List {

                if kfd != 0 {
                    Section(header: Text("Status")) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Success!")
                                .font(.headline)
                                .foregroundColor(.green)
                            Text("View output in Xcode")
                                .foregroundColor(.gray)
                        }
                    }
                }

                Section("Tweaks") {
                    ForEach(tweakSettings.tweaks) { tweak in
                        TweakToggleView(tweak: tweak)
                    }
                }

                Button("Confirm") {
                    kfd = do_kopen(UInt64(puafPages), UInt64(puafMethod), UInt64(kreadMethod), UInt64(kwriteMethod))

                    let tweaks = enabledTweaks()

                    // Convert the Swift array of strings to a C-style array of char*
                    var cTweaks: [UnsafeMutablePointer<CChar>?] = tweaks.map { strdup($0) } // Use strdup to allocate memory for C-style strings

                    // Add a null pointer at the end to signal the end of the array
                    cTweaks.append(nil)

                    // Pass the C-style array to do_fun along with the count of tweaks
                    let _ = cTweaks.withUnsafeMutableBufferPointer { buffer in
                        do_fun(buffer.baseAddress, Int32(buffer.count - 1))
                    }

                    // Deallocate the C-style strings after use to avoid memory leaks
                    cTweaks.forEach { free($0) }
                }
            }
                .navigationBarTitle("Pois0nKFD", displayMode: .inline)
                .navigationBarItems(trailing: settingsButton)
                .popover(isPresented: $isSettingsPopoverPresented, arrowEdge: .bottom) { settingsPopover }
        }
    }



    // Settings Button in the Navigation Bar
    private var settingsButton: some View {
        Button(action: {
            isSettingsPopoverPresented.toggle() // Toggle the settings popover
        }) {
            Image(systemName: "gearshape")
                .imageScale(.large)
        }
    }

    // Payload Settings Popover
    private var settingsPopover: some View {
        VStack {
            Section(header: Text("Payload Settings")) {
                Picker("puaf pages:", selection: $puafPages) {
                    ForEach(puafPagesOptions, id: \.self) { pages in
                        Text(String(pages))
                    }
                }.pickerStyle(SegmentedPickerStyle())
                    .disabled(kfd != 0)

                Picker("puaf method:", selection: $puafMethod) {
                    ForEach(0..<puafMethodOptions.count, id: \.self) { index in
                        Text(puafMethodOptions[index])
                    }
                }.pickerStyle(SegmentedPickerStyle())
                    .disabled(kfd != 0)
            }

            Section(header: Text("Kernel Settings")) {
                Picker("kread method:", selection: $kreadMethod) {
                    ForEach(0..<kreadMethodOptions.count, id: \.self) { index in
                        Text(kreadMethodOptions[index])
                    }
                }.pickerStyle(SegmentedPickerStyle())
                    .disabled(kfd != 0)

                Picker("kwrite method:", selection: $kwriteMethod) {
                    ForEach(0..<kwriteMethodOptions.count, id: \.self) { index in
                        Text(kwriteMethodOptions[index])
                    }
                }.pickerStyle(SegmentedPickerStyle())
                    .disabled(kfd != 0)
            }

            Button("Apply Settings") {
                // Do something when the user applies the settings
                isSettingsPopoverPresented = false // Close the popover after applying settings
            }
        }
            .padding()
    }

    // Get the list of enabled tweaks based on the current state of toggles
    private func enabledTweaks() -> [String] {

        let enabledTweaks: [String] = tweakSettings.tweaks
            .filter { $0.isEnabled }
            .map { $0.valueKey }

        return enabledTweaks
    }
}

private struct TweakToggleView: View {
    @StateObject var tweak: Tweak

    var body: some View {
        Toggle(isOn: $tweak.isEnabled) {
            HStack(spacing: 20) {
                Image(systemName: tweak.isEnabled ? tweak.activeIcon : tweak.inActiveIcon)
                    .font(.system(size: 24)) // Increase the icon size
                    .foregroundColor(tweak.isEnabled ? .green : .red) // Change icon color based on the enabled state
                Text(tweak.label)
                    .font(.headline) // Apply a headline font to the label
                    .foregroundColor(.primary) // Use the primary color for the label
            }
        }
        .onChange(of: tweak.isEnabled) { newValue in
            UserDefaults.standard.setValue(newValue, forKey: tweak.valueKey)
        }
    }
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
