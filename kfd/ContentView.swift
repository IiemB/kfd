import SwiftUI

struct ContentView: View {
    @State private var kfd: UInt64 = 0
    
    @State private var puafPages = 2048
    @State private var puafMethod = 1
    @State private var kreadMethod = 1
    @State private var kwriteMethod = 1
    //tweak vars
    @State private var isDockHidden = false
    @State private var enableCCTweaks = false
    @State private var enableLSTweaks = false
    @State private var enableCustomFont = false
    @State private var enableresset = false
    @State private var hidehomebar = false
    
    var puafPagesOptions = [16, 32, 64, 128, 256, 512, 1024, 2048]
    var puafMethodOptions = ["physpuppet", "smith"]
    var kreadMethodOptions = ["kqueue_workloop_ctl", "sem_open"]
    var kwriteMethodOptions = ["dup", "sem_open"]
    
    var body: some View {
        NavigationView {
            Form {
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
                
                Section {
                    HStack(spacing: 20) {
                        Button("Open exploit") {
                            kfd = do_kopen(UInt64(puafPages), UInt64(puafMethod), UInt64(kreadMethod), UInt64(kwriteMethod))
                            do_fun(kfd)
                        }.disabled(kfd != 0)
                        Button("Close exploit") {
                            do_kclose(kfd)
                            kfd = 0
                        }.disabled(kfd == 0)
                        Button("Respring") {
                            kfd = 0
                            do_respring()
                        }
                        .accentColor(.red)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
                
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
                
                Section(header: Text("Other Actions")) {
                    Button("Hide Dock") {
                        do_hidedock(kfd)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
            .navigationBarTitle("Kernel Exploit", displayMode: .inline)
            .accentColor(.green) // Highlight the navigation bar elements in green
        }
        .foregroundColor(.white) // Set the default text color to black
    
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
                
                Section(header: Text("Tweaks")) {
                    VStack(alignment: .leading, spacing: 20) {
                        Toggle(isOn: $isDockHidden) {
                            HStack(spacing: 20) {
                                Image(systemName: isDockHidden ? "eye.slash" : "eye")
                                    .foregroundColor(.blue)
                                    .imageScale(.large)
                                Text("Hide Dock")
                                    .font(.headline)
                            }
                        }
                        .onChange(of: isDockHidden, perform: { _ in
                            // Perform any actions when the toggle state changes
                        })

                        Toggle(isOn: $hidehomebar) {
                            HStack(spacing: 20) {
                                Image(systemName: hidehomebar ? "rectangle.grid.1x2.fill" : "rectangle.grid.1x2")
                                    .foregroundColor(.purple)
                                    .imageScale(.large)
                                Text("Hide Home Bar")
                                    .font(.headline)
                            }
                        }
                        .onChange(of: hidehomebar, perform: { _ in
                            // Perform any actions when the toggle state changes
                        })

                        Toggle(isOn: $enableresset) {
                            HStack(spacing: 20) {
                                Image(systemName: enableresset ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                    .foregroundColor(.green)
                                    .imageScale(.large)
                                Text("Enable iPhone 14 Pro Resolution")
                                    .font(.headline)
                            }
                        }
                        .onChange(of: enableresset, perform: { _ in
                            // Perform any actions when the toggle state changes
                        })

                        Toggle(isOn: $enableCustomFont) {
                            HStack(spacing: 20) {
                                Image(systemName: enableCustomFont ? "a.circle.fill" : "a.circle")
                                    .foregroundColor(.orange)
                                    .imageScale(.large)
                                Text("Enable Custom Font")
                                    .font(.headline)
                            }
                        }
                        .onChange(of: enableCustomFont, perform: { _ in
                            // Perform any actions when the toggle state changes
                        })

                        Toggle(isOn: $enableCCTweaks) {
                            HStack(spacing: 20) {
                                Image(systemName: enableCCTweaks ? "pencil.circle.fill" : "pencil.circle")
                                    .foregroundColor(.pink)
                                    .imageScale(.large)
                                Text("Enable CC Custom Icons")
                                    .font(.headline)
                            }
                        }
                        .onChange(of: enableCCTweaks, perform: { _ in
                            // Perform any actions when the toggle state changes
                        })
                        Toggle(isOn: $enableLSTweaks) {
                            HStack(spacing: 20) {
                                Image(systemName: enableLSTweaks ? "pencil.circle.fill" : "pencil.circle")
                                    .foregroundColor(.pink)
                                    .imageScale(.large)
                                Text("Enable Lockscreen Custom Icons")
                                    .font(.headline)
                            }
                        }

                        .onChange(of: enableLSTweaks, perform: { _ in
                            // Perform any actions when the toggle state changes
                        })
                    }
                    .padding(.vertical, 8)
                }

                Section(header: Text("Confirm")) {
                    Button("Confirm") {
                        kfd = do_kopen(UInt64(puafPages), UInt64(puafMethod), UInt64(kreadMethod), UInt64(kwriteMethod))

                        let tweaks = enabledTweaks()

                        // Convert the Swift array of strings to a C-style array of char*
                        var cTweaks: [UnsafeMutablePointer<CChar>?] = tweaks.map { strdup($0) } // Use strdup to allocate memory for C-style strings

                        // Add a null pointer at the end to signal the end of the array
                        cTweaks.append(nil)

                        // Pass the C-style array to do_fun along with the count of tweaks
                        cTweaks.withUnsafeMutableBufferPointer { buffer in
                            do_fun(buffer.baseAddress, Int32(buffer.count - 1))
                        }

                        // Deallocate the C-style strings after use to avoid memory leaks
                        cTweaks.forEach { free($0) }
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
                
            }
            .navigationBarTitle("Pois0nKFD", displayMode: .inline)
            .accentColor(.green) // Highlight the navigation bar elements in green
            .navigationBarItems(trailing: settingsButton)
            .popover(isPresented: $isSettingsPopoverPresented, arrowEdge: .bottom) {
                settingsPopover
            }
        }
        .foregroundColor(.white) // Set the default text color to white
    }
    
    // Settings Button in the Navigation Bar
    private var settingsButton: some View {
        Button(action: {
            isSettingsPopoverPresented.toggle() // Toggle the settings popover
        }) {
            Image(systemName: "gearshape")
                .imageScale(.large)
                .foregroundColor(.green)
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
        var enabledTweaks: [String] = []
        if isDockHidden {
            enabledTweaks.append("HideDock")
        }
        if hidehomebar {
            enabledTweaks.append("hidehomebar")
        }
        if enableresset {
            enabledTweaks.append("enableresset")
        }
        if enableCustomFont {
            enabledTweaks.append("enableCustomFont")
        }
        if enableCCTweaks {
            enabledTweaks.append("enableCCTweaks")
        }
        if enableLSTweaks {
            enabledTweaks.append("enableLSTweaks")
        }


        return enabledTweaks
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
