import SwiftUI
class Tweak: ObservableObject, Identifiable {
    var id: String
    @Published var selectedFont: String?
    let valueKey, label, inActiveIcon, activeIcon: String
    @Published var secondaryValue: String // Change the type to String for the secondaryValue property

    @Published var isEnabled = false
    private let documentsURL: URL

    init(valueKey: String, label: String, inActiveIcon: String, activeIcon: String, selectedFont: String? = nil, secondaryValue: String) {
        self.id = valueKey
        self.valueKey = valueKey
        self.label = label
        self.inActiveIcon = inActiveIcon
        self.activeIcon = activeIcon
        self.isEnabled = UserDefaults.standard.bool(forKey: valueKey)
        self.selectedFont = selectedFont
        self.secondaryValue = secondaryValue
        self.documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    func updateSecondaryValue(selectedFont: String?) {
        guard let selectedFont = selectedFont else {
            secondaryValue = "" // Set to an empty string if selectedFont is nil
            return
        }
        let fontURL = documentsURL.appendingPathComponent("posi0nKFD").appendingPathComponent(selectedFont + ".ttf")
        secondaryValue = fontURL.path
    }
    
}
private func withCStyleArray<T>(_ array: [T], _ body: (UnsafeMutablePointer<T>?) -> Void) {
    var mutableArray = array
    mutableArray.append(array[0]) // Add an extra element to ensure the array is not empty
    mutableArray.withUnsafeMutableBufferPointer { buffer in
        buffer.baseAddress.map(body)
    }
}
        class TweaksSettings: ObservableObject {

    @Published var tweaks: [Tweak]

    init() {
        self.tweaks = [
            Tweak(valueKey: "HideDock", label: "Hide Dock", inActiveIcon: "eye", activeIcon: "eye.slash", secondaryValue: "SomeSecondaryValue2"),
            Tweak(valueKey: "hidehomebar", label: "Hide Home Bar", inActiveIcon: "eye", activeIcon: "eye.slash", secondaryValue: "SomeSecondaryValue2"),
            Tweak(valueKey: "enableHideNotifs", label: "Hide notification and media player background", inActiveIcon: "eye", activeIcon: "eye.slash", secondaryValue: "SomeSecondaryValue2"),
            Tweak(valueKey: "mutecam", label: "Mute camera", inActiveIcon: "speaker.wave.2", activeIcon: "speaker.slash", secondaryValue: "SomeSecondaryValue2"),
            Tweak(valueKey: "enableresset", label: "Enable iPhone 14 Pro Resolution", inActiveIcon: "iphone.gen3.circle", activeIcon: "iphone.gen3.circle.fill", secondaryValue: "SomeSecondaryValue2"),
            Tweak(valueKey: "enableCustomFont", label: "Enable Custom Font", inActiveIcon: "a.circle", activeIcon: "a.circle.fill", secondaryValue: "test"),
            Tweak(valueKey: "enableCCTweaks", label: "Enable CC Custom Icons", inActiveIcon: "switch.2", activeIcon: "switch.2", secondaryValue: "SomeSecondaryValue2"),
            Tweak(valueKey: "enableLSTweaks", label: "Enable Lockscreen Custom Icons", inActiveIcon: "lock", activeIcon: "lock.fill", secondaryValue: "SomeSecondaryValue2"),
        ]
    }
}
private var installedFonts: [String] {
    let fileManager = FileManager.default
    do {
        // Get the URL for the app's "Documents" directory
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        // Get the list of all files in the document directory
        let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)

        // Filter the list to only include font files with the extension ".ttf" or ".otf"
        let fontFileURLs = fileURLs.filter { $0.pathExtension == "ttf" || $0.pathExtension == "otf" }

        // Get the file names (without extensions) from the URLs and return them as an array of strings
        return fontFileURLs.map { $0.deletingPathExtension().lastPathComponent }
    } catch {
        print("Error fetching installed fonts: \(error)")
        return []
    }
}
struct ContentView: View {
    
    @State private var kfd: UInt64 = 0
    @State private var selectedFont: String = ""
    @State private var isSecondViewPresented = false // Track the visibility of the second view
    @StateObject var tweakSettings = TweaksSettings()
    @State private var installedFontsURLs: [URL] = []
    @State private var puafPages = 2048
    @State private var puafMethod = 1
    @State private var kreadMethod = 1
    @State private var kwriteMethod = 1
    var puafPagesOptions = [16, 32, 64, 128, 256, 512, 1024, 2048]
    var puafMethodOptions = ["physpuppet", "smith"]
    var kreadMethodOptions = ["kqueue_workloop_ctl", "sem_open"]
    var kwriteMethodOptions = ["dup", "sem_open"]

    @State private var isSettingsPopoverPresented = false // Track the visibility of the settings popup
    @State private var isConfigPopoverPresented = false // Track the visibility of the config popup
    private func fetchInstalledFontURLs() {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        do {
            // Get the list of all files in the document directory
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)

            // Filter the list to only include font files with the extension ".ttf" or ".otf"
            installedFontsURLs = fileURLs.filter { $0.pathExtension == "ttf" || $0.pathExtension == "otf" }
        } catch {
            print("Error fetching installed fonts: \(error)")
            installedFontsURLs = []
        }
    }
    private var documentsURL: URL {
        // Get the URL for the app's "Documents" directory
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    var body: some View {

           TabView {
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
                       
                       Section(header: Text("Tweaks")) {
                           ForEach(tweakSettings.tweaks) { tweak in
                               TweakToggleView(tweak: tweak)
                           }
                       }
                       
                       Button("Confirm") {
                           kfd = do_kopen(UInt64(puafPages), UInt64(puafMethod), UInt64(kreadMethod), UInt64(kwriteMethod))

                           let enabledTweaks = tweakSettings.tweaks.filter { $0.isEnabled }
                           var cTweaks: [UnsafeMutablePointer<CChar>?] = enabledTweaks.map { tweak in
                               let cString = tweak.valueKey.withCString { strdup($0) }
                               return UnsafeMutablePointer<CChar>(cString)
                           }

                           // Add a null pointer at the end to signal the end of the tweaks array
                           cTweaks.append(nil)

                           // Get the secondary values of the enabled tweaks and convert them to C-style strings
                           var cSecondaryValues: [UnsafeMutablePointer<CChar>?] = enabledTweaks.compactMap { tweak in
                               guard let secondaryValue = tweak.secondaryValue as? String else {
                                   return nil
                               }
                               return secondaryValue.withCString { strdup($0) }
                           }

                           // Add a null pointer at the end to signal the end of the secondary values array
                           cSecondaryValues.append(nil)

                           // Convert the Swift arrays to C-style arrays
                           withCStyleArray(cTweaks) { tweaksPtr in
                               withCStyleArray(cSecondaryValues) { secondaryValuesPtr in
                                   let numTweaks = Int32(cTweaks.count - 1) // Subtract 1 to exclude the null pointer
                                   do_fun(tweaksPtr, secondaryValuesPtr, numTweaks)

                                   // Deallocate the C-style strings after use to avoid memory leaks
                                   cTweaks.forEach { free($0) }
                                   cSecondaryValues.forEach { free($0) }
                               }
                           }
                        }
                   }
               
                   

                       // Helper function to handle C-style arrays and null termination
                  
                       // Helper function to handle C-style arrays and null termination
                     

                   .listStyle(GroupedListStyle()) // Use GroupedListStyle for a standard iOS list appearance
                   .navigationBarItems(leading: configButton, trailing: HStack {
                       settingsButton
                       configButton // Add the new font settings button
                   })
                   .popover(isPresented: $isSettingsPopoverPresented, arrowEdge: .bottom) { settingsPopover }
               }.popover(isPresented: $isConfigPopoverPresented, arrowEdge: .bottom) { configPopover }
           .tabItem {
                   Image(systemName: "list.bullet")
                   Text("Tweaks")
               }
               .navigationViewStyle(StackNavigationViewStyle()) // Use StackNavigationViewStyle to handle multiple tabs properly
               .tag(0)

               SourcesView()
                     .environmentObject(SourcesViewModel())
                     .tabItem {
                       Image(systemName: "list.bullet")
                       Text("Sources")
                   }
                   .tag(1)
               Text("Installed")
                   .tabItem {
                       Image(systemName: "list.bullet")
                       Text("Installed")
                   }
                   .tag(2)
           }
           .onAppear {
               let appearance = UITabBarAppearance()
               appearance.configureWithOpaqueBackground()
               appearance.backgroundColor = UIColor(Color.accentColor) // Set the background color using the primary color
               UITabBar.appearance().standardAppearance = appearance
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
    private var configButton: some View {
        Button(action: {
            isConfigPopoverPresented.toggle() // Toggle the font settings popover
        }) {
            Image(systemName: "textformat") // Use an appropriate icon for font settings
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
    private var configPopover: some View {
        VStack {
            Section(header: Text("Font Settings")) {
                // Dropdown to select the installed font
                Picker("Select Font", selection: $selectedFont) {
                    ForEach(installedFonts, id: \.self) { font in
                        Text(font)
                    }
                }
                .pickerStyle(MenuPickerStyle()) // Use MenuPickerStyle to display a drop-down style picker
                .padding(.leading, 40) // Add some padding to align the picker
            }

            Button("Apply Config") {
                // Find the tweak object for "enableCustomFont"
                if let customFontTweak = tweakSettings.tweaks.first(where: { $0.valueKey == "enableCustomFont" }) {
                    // Update the selectedFont property
                    customFontTweak.selectedFont = selectedFont
                    // Update the secondaryValue property
                    customFontTweak.updateSecondaryValue(selectedFont: selectedFont)

                    // Save the changes to UserDefaults
                    UserDefaults.standard.set(customFontTweak.selectedFont, forKey: customFontTweak.valueKey)
                    UserDefaults.standard.set(customFontTweak.isEnabled, forKey: customFontTweak.valueKey + "enabled")
                    UserDefaults.standard.set(customFontTweak.secondaryValue, forKey: customFontTweak.valueKey + "secondaryValue")
                }
                isConfigPopoverPresented = false // Close the popover after applying settings
            }
        }
        .padding()
        .onAppear {
            // Set an initial value for selectedFont to avoid the 'nil' selection error
            selectedFont = tweakSettings.tweaks.first(where: { $0.valueKey == "enableCustomFont" })?.selectedFont ?? ""
        }
    }
    private func showSecondView() {
        isSecondViewPresented = true
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
