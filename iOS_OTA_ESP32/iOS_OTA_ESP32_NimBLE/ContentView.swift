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
    
    var body: some View{
        VStack{
            Text("Shiftwave SWIFT Bluetooth Firmware Updater").bold()
                .padding(.bottom, 10)
            
            // MIDI Connection Status
            HStack(spacing: 5) {
                Circle()
                    .fill(midiManager.midiConnected ? Color.green : Color.yellow)
                    .frame(width: 10, height: 10)
                
                Text(midiManager.connectionStatusMessage)
                    .font(.system(size: 14))
                
                Button(action: {
                    midiManager.startPeriodicHardwareCheck()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                }
            }
            .padding(.vertical, 5)
            
            // DFU Status Message - show when device is connected
            if midiManager.midiConnected {
                Text(midiManager.dfuStatusMessage)
                    .font(.system(size: 13))
                    .foregroundColor(midiManager.hardwareStatus == .dfuMode ? .green : .blue)
                    .padding(.vertical, 2)
            }
            
            // Enter Firmware Update Mode Button
            Button(action: {
                midiManager.sendFirmwareUpdateMode()
                startRebootSequence()
            }) {
                Text("Enter Firmware Update Mode")
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(midiManager.midiConnected ? Color.green : Color.gray, lineWidth: 2)
                    )
            }
            .disabled(!midiManager.midiConnected || isRebooting || midiManager.hardwareStatus == .dfuMode || ble.connected)
            .opacity((midiManager.midiConnected && !isRebooting && midiManager.hardwareStatus != .dfuMode && !ble.connected) ? 1.0 : 0.5)
            .padding(.bottom, 5)
            
            // Reboot status message
            if isRebooting {
                Text("Rebooting SWIFT into Update Mode, please wait... (\(remainingTime)s)")
                    .foregroundColor(.orange)
                    .font(.system(size: 14))
                    .padding(.bottom, 10)
            } else {
                Spacer()
                    .frame(height: 24) // Maintains layout even when message is hidden
                    .padding(.bottom, 10)
            }
        /*
            // BLE Connection Buttons
            HStack{
                Button(action: {
                    ble.startScanning()
                }){
                    Text("connect").padding().overlay(RoundedRectangle(cornerRadius: 15).stroke(colorChange(ble.connected), lineWidth: 2))
                }
                .disabled(isRebooting)
                .opacity(isRebooting ? 0.5 : 1.0)
                
                Button(action: {
                    ble.disconnect(forget: false)
                }){
                    Text("disconnect").padding().overlay(RoundedRectangle(cornerRadius: 15).stroke(colorChange(ble.connected), lineWidth: 2))
                }
                .disabled(isRebooting)
                .opacity(isRebooting ? 0.5 : 1.0)
                
                Button(action: {
                    ble.disconnect(forget: true)
                }){
                    Text("forget bond").padding().overlay(RoundedRectangle(cornerRadius: 15).stroke(colorChange(ble.connected), lineWidth: 2))
                }
                .disabled(isRebooting)
                .opacity(isRebooting ? 0.5 : 1.0)
            }
            .padding(.bottom, 10)
          */
            // BLE Status Information
            VStack {
                Text("Device : \(ble.name)")
                Text("Transfer speed : \(ble.kBPerSecond, specifier: "%.1f") kB/s")
                Text("Elapsed time   : \(ble.elapsedTime, specifier: "%.1f") s")
                Text("Upload progress: \(ble.transferProgress, specifier: "%.1f") %")
            }
            .padding(.bottom, 10)
            
            // Firmware Version Selection
            VStack {
                Text("Select Firmware Version").font(.headline)
                HStack {
                    ForEach(firmwareVersions, id: \.self) { version in
                        Button(action: {
                            selectedFirmware = version
                        }) {
                            Text(version)
                                .padding()
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(selectedFirmware == version ? Color.green : colorChange(ble.connected), lineWidth: 2)
                                )
                                .background(selectedFirmware == version ? Color.green.opacity(0.2) : Color.clear)
                        }
                    }
                }
                .padding()
            }
            
            // Flash Button
            HStack{
                Button(action: {
                    ble.sendFile(filename: selectedFirmware, fileEnding: ".bin")
                }){
                    Text("Flash \(selectedFirmware).bin to ESP32").padding().overlay(RoundedRectangle(cornerRadius: 15).stroke(colorChange(ble.connected), lineWidth: 2))
                }.disabled(ble.transferOngoing)
            }
            
            if !ble.errorMessage.isEmpty {
                Text(ble.errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
            
            Divider()
            VStack{
                Stepper("chunks (1-4) per write cycle: \(ble.chunkCount)", value: $ble.chunkCount, in: 1...4)
                    .disabled(ble.transferOngoing)
            }
        }
        .padding()
        .accentColor(colorChange(ble.connected))
        .onDisappear {
            // Clean up timer when view disappears
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
            if self.midiManager.hardwareStatus == .dfuMode {
                self.isRebooting = false
                self.cancelRebootTimer()
                // No need to connect automatically - we're already in DFU mode
                return
            }
            
            if self.remainingTime > 0 {
                self.remainingTime -= 1
                
                // Stop DFU status polling after 3 seconds
                // This gives enough time to receive the last status message
                if self.remainingTime == 12 {
                    print("3 seconds elapsed, stopping DFU status polling")
                    self.midiManager.stopDFUStatusPolling()
                }
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
