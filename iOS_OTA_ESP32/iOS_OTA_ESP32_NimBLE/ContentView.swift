//
//  ContentView.swift
//  iOS_OTA_ESP32
//  Inspired by: purpln https://github.com/purpln/bluetooth
//  Licence: MIT
//  Created by Claes Hallberg on 1/13/22.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var ble : BLEConnection
    @EnvironmentObject var midiManager: MIDIManager
    @State private var selectedFirmware = "V8"
    let firmwareVersions = ["V8", "V9", "V10"]
    
    // States for timer functionality
    @State private var isRebooting = false
    @State private var remainingTime = 15
    @State private var rebootTimer: Timer?
    
    private var headerView: some View {
        VStack {
            Text("Shiftwave SWIFT Firmware Updater").bold()
                .padding(.bottom, 10)
            connectionStatusView
        }
    }
    
    private var connectionStatusView: some View {
        VStack {
            HStack(spacing: 5) {
                Circle()
                    .fill(midiManager.midiConnected ? Color.green : Color.yellow)
                    .frame(width: 10, height: 10)
                
                Text(midiManager.connectionStatusMessage)
                    .font(.system(size: 14))
            }
            .padding(.vertical, 5)
            
            if midiManager.midiConnected {
                Text(midiManager.dfuStatusMessage)
                    .font(.system(size: 13))
                    .frame(height: 20)
                    .padding(.vertical, 2)
            } else {
                Text("")
                    .frame(height: 20)
                    .padding(.vertical, 2)
            }
        }
    }
    
    private var firmwareUpdateButton: some View {
        Button(action: {
            midiManager.sendFirmwareUpdateMode()
            startRebootSequence()
        }) {
            Text("Enter Firmware Update Mode")
                .foregroundColor(midiManager.midiConnected ? Color.green : Color.gray)
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(midiManager.midiConnected ? Color.green : Color.gray, lineWidth: 2)
                )
        }
        .disabled(!midiManager.midiConnected || isRebooting || midiManager.dfuModeConfirmed)
        .opacity((midiManager.midiConnected && !isRebooting && !midiManager.dfuModeConfirmed) ? 1.0 : 0.5)
        .padding(.bottom, 5)
    }
    
    private var statusMessageView: some View {
        Group {
            if isRebooting {
                Text("Rebooting SWIFT into Update Mode, please wait... (\(remainingTime)s)")
                    .foregroundColor(.orange)
                    .font(.system(size: 14))
                    .padding(.bottom, 10)
            } else if midiManager.dfuModeConfirmed {
                Text("SWIFT is ready for firmware flashing")
                    .foregroundColor(.green)
                    .font(.system(size: 14))
                    .padding(.bottom, 10)
            } else {
                Spacer()
                    .frame(height: 24)
                    .padding(.bottom, 10)
            }
        }
    }
    
    private var firmwareSelectionView: some View {
        VStack {
            Text("Select Firmware Version")
                .font(.headline)
                .opacity(midiManager.dfuModeConfirmed ? 1.0 : 0.3)
            HStack {
                ForEach(firmwareVersions, id: \.self) { version in
                    Button(action: {
                        selectedFirmware = version
                    }) {
                        Text(version)
                            .padding()
                            .overlay(
                                RoundedRectangle(cornerRadius: 13)
                                    .stroke((selectedFirmware == version) && midiManager.dfuModeConfirmed ? Color.green : Color.gray, lineWidth: 2)
                            )
                            .background((selectedFirmware == version) && midiManager.dfuModeConfirmed ? Color.green.opacity(0.2) : Color.clear)
                    } .opacity(midiManager.dfuModeConfirmed ? 1.0 : 0.3)
                    .disabled(!midiManager.dfuModeConfirmed)
                }
            }
            .padding()
        }
    }
    
    private var dfuStatusView: some View {
        VStack {
            Text("Device : \(ble.name)")
            Text("Transfer speed : \(ble.kBPerSecond, specifier: "%.1f") kB/s")
            Text("Elapsed time   : \(ble.elapsedTime, specifier: "%.1f") s")
            Text("Upload progress: \(ble.transferProgress, specifier: "%.1f") %")
        }
        .opacity(midiManager.dfuModeConfirmed ? 1 : 0.3)
        .padding(.top, 10)
    }
    
    var body: some View {
        VStack {
            headerView
            firmwareUpdateButton
            statusMessageView
            firmwareSelectionView
            
            Button(action: {
                ble.sendFile(filename: selectedFirmware, fileEnding: ".bin")
            }) {
                Text("Flash \(selectedFirmware).bin to SWIFT")
                    .foregroundColor(midiManager.dfuModeConfirmed ? Color.green : Color.gray)
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(midiManager.dfuModeConfirmed ? Color.green : Color.gray, lineWidth: 2)
                    )
            }.opacity(midiManager.dfuModeConfirmed ? 1 : 0.3)
            .disabled(ble.transferOngoing)
            
            dfuStatusView
            
            if !ble.errorMessage.isEmpty {
                Text(ble.errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .padding()
        .accentColor(colorChange(ble.connected))
        .onDisappear {
            cancelRebootTimer()
        }
    }
    
    // Start the reboot sequence with timer
    private func startRebootSequence() {
        isRebooting = true
        remainingTime = 15
        
        // Cancel any existing timer
        cancelRebootTimer()
        
        // Create a new timer that fires every second
        rebootTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [self] timer in
            // Check if DFU mode has been confirmed
            if self.midiManager.dfuModeConfirmed {
                self.isRebooting = false
                self.cancelRebootTimer()
                // No need to connect automatically - we're already in DFU mode
                //TODO: this is unlikely to work since firmware only confirms dfumode with midi once at startup
                return
            }
            
            if self.remainingTime > 0 {
                self.remainingTime -= 1
            } else {
                self.isRebooting = false
                self.cancelRebootTimer()
                
                // Automatically try to connect after timer finishes
                DispatchQueue.main.async {
                    self.ble.startScanning()
                }
            }
        }
        
        // Make sure the timer keeps firing when scrolling
        if let timer = rebootTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }
    
    // Cancel the timer
    private func cancelRebootTimer() {
        rebootTimer?.invalidate()
        rebootTimer = nil
    }
}

func colorChange(_ connected:Bool) -> Color{
    if connected{
        return Color.green
    }else{
        return Color.blue
    }
}
