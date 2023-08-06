import SwiftUI

let puafPagesOptions = [16, 32, 64, 128, 256, 512, 1024, 2048]
let puafMethodOptions = ["physpuppet", "smith"]
let kreadMethodOptions = ["kqueue_workloop_ctl", "sem_open"]
let kwriteMethodOptions = ["dup", "sem_open"]

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
    @Published var isAnyTweakEnabled = false

    init() {
        self.tweaks = [
            Tweak(valueKey: "HideDock", label: "Hide Dock", inActiveIcon: "eye", activeIcon: "eye.slash"),
            Tweak(valueKey: "hidehomebar", label: "Hide Home Bar", inActiveIcon: "rectangle.grid.1x2", activeIcon: "rectangle.grid.1x2.fill"),
            Tweak(valueKey: "enableresset", label: "Enable iPhone 14 Pro Resolution", inActiveIcon: "iphone.gen3.circle", activeIcon: "iphone.gen3.circle.fill"),
            Tweak(valueKey: "enableCustomFont", label: "Enable Custom Font", inActiveIcon: "a.circle", activeIcon: "a.circle.fill"),
            Tweak(valueKey: "enableCCTweaks", label: "Enable CC Custom Icons", inActiveIcon: "switch.2", activeIcon: "switch.2"),
            Tweak(valueKey: "enableLSTweaks", label: "Enable Lockscreen Custom Icons", inActiveIcon: "lock", activeIcon: "lock.fill")
        ]

        self.checkIsAnyTweakEnabled(true)
    }

    func checkIsAnyTweakEnabled(_ value: Bool) {
        self.isAnyTweakEnabled = !self.tweaks.filter { $0.isEnabled }.isEmpty
    }
}

class KFDSettings: ObservableObject {
    @Published var puafPages: Int {
        didSet {
            UserDefaults.standard.set(puafPages, forKey: "puafPages")
        }
    }

    @Published var puafMethod: Int {
        didSet {
            UserDefaults.standard.set(puafPages, forKey: "puafMethod")
        }
    }

    @Published var kreadMethod: Int {
        didSet {
            UserDefaults.standard.set(puafPages, forKey: "kreadMethod")
        }
    }

    @Published var kwriteMethod: Int {
        didSet {
            UserDefaults.standard.set(puafPages, forKey: "kwriteMethod")
        }
    }

    init(puafPages: Int = 2048, puafMethod: Int = 1, kreadMethod: Int = 1, kwriteMethod: Int = 1) {
        self.puafPages = UserDefaults.standard.value(forKey: "puafPages") as? Int ?? puafPages
        self.puafMethod = UserDefaults.standard.value(forKey: "puafMethod") as? Int ?? puafMethod
        self.kreadMethod = UserDefaults.standard.value(forKey: "kreadMethod") as? Int ?? kreadMethod
        self.kwriteMethod = UserDefaults.standard.value(forKey: "kwriteMethod") as? Int ?? kwriteMethod
    }
}

struct ContentView: View {
    @State private var kfd: UInt64 = 0

    @StateObject var tweakSettings = TweaksSettings()
    @StateObject var kfdSettings = KFDSettings()

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

                Section(header: Text("Payload Settings")) {
                    Picker("puaf pages:", selection: $kfdSettings.puafPages) {
                        ForEach(puafPagesOptions, id: \.self) { pages in
                            Text(String(pages))
                        }
                    }.compositingGroup()
                        .clipped()
                        .pickerStyle(SegmentedPickerStyle())
                        .disabled(kfd != 0)

                    Picker("puaf method:", selection: $kfdSettings.puafMethod) {
                        ForEach(0..<puafMethodOptions.count, id: \.self) { index in
                            Text(puafMethodOptions[index])
                        }
                    }.pickerStyle(SegmentedPickerStyle())
                        .disabled(kfd != 0)
                }

                Section(header: Text("Kernel Settings")) {
                    Picker("kread method:", selection: $kfdSettings.kreadMethod) {
                        ForEach(0..<kreadMethodOptions.count, id: \.self) { index in
                            Text(kreadMethodOptions[index])
                        }
                    }.pickerStyle(SegmentedPickerStyle())
                        .disabled(kfd != 0)

                    Picker("kwrite method:", selection: $kfdSettings.kwriteMethod) {
                        ForEach(0..<kwriteMethodOptions.count, id: \.self) { index in
                            Text(kwriteMethodOptions[index])
                        }
                    }.pickerStyle(SegmentedPickerStyle())
                        .disabled(kfd != 0)
                }
            }
                .toolbar {
                Button("Apply", action: enableTweaks)

            }
                .animation(.linear, value: tweakSettings.isAnyTweakEnabled)
                .navigationBarTitle("Pois0nKFD", displayMode: .automatic)
        }
            .environmentObject(tweakSettings)


    }

    private func enableTweaks() {

        // Save state
        for tweak in tweakSettings.tweaks {
            UserDefaults.standard.setValue(tweak.isEnabled, forKey: tweak.valueKey)
        }

        kfd = do_kopen(UInt64(kfdSettings.puafPages), UInt64(kfdSettings.puafMethod), UInt64(kfdSettings.kreadMethod), UInt64(kfdSettings.kwriteMethod))

        // Get the list of enabled tweaks based on the current state of toggles
        let tweaks = tweakSettings.tweaks
            .filter { $0.isEnabled }
            .map { $0.valueKey }

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

private struct TweakToggleView: View {
    @StateObject var tweak: Tweak

    @EnvironmentObject var tweaksSetting: TweaksSettings

    var body: some View {
        Toggle(isOn: $tweak.isEnabled) {
            HStack(spacing: 20) {
                Image(systemName: tweak.isEnabled ? tweak.activeIcon : tweak.inActiveIcon)
                Text(tweak.label)
            }
        }
            .onChange(of: tweak.isEnabled, perform: tweaksSetting.checkIsAnyTweakEnabled)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
