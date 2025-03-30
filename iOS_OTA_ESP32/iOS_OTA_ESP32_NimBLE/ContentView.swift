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
    @State private var remainingTime = 10
    @State private var rebootTimer: Timer?
    
    // Define a consistent width for the UI
    private let contentWidth: CGFloat = 300
    
    // Standardized font sizes
    private let titleFontSize: CGFloat = 18
    private let bodyFontSize: CGFloat = 14
    private let buttonFontSize: CGFloat = 15 // Slightly larger than body text
    private let smallFontSize: CGFloat = 13
    
    private var headerView: some View {
        VStack {
            Text("Shiftwave Firmware Updater").bold()
                .font(.system(size: titleFontSize))
                .kerning(0.5)
                .frame(width: contentWidth, alignment: .center)
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
                    .font(.system(size: smallFontSize))
                
                Spacer()
            }
            .frame(width: contentWidth)
            .padding(.vertical, 5)
            
            if midiManager.midiConnected {
                Text(midiManager.dfuStatusMessage)
                    .font(.system(size: smallFontSize))
                    .frame(width: contentWidth, height: 20, alignment: .leading)
                    .padding(.vertical, 2)
            } else {
                Text("")
                    .frame(width: contentWidth, height: 20)
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
                .font(.system(size: buttonFontSize, weight: .medium))
                .foregroundColor(midiManager.midiConnected ? Color.green : Color.gray)
                .padding(.vertical)
                .frame(width: contentWidth)
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
                Text("Rebooting SWIFT into DFU Mode... (\(remainingTime)s)")
                    .foregroundColor(.orange)
                    .font(.system(size: bodyFontSize))
                    .frame(width: contentWidth)
                    .padding(.bottom, 10)
            } else if midiManager.dfuModeConfirmed {
                Text("SWIFT is ready for Bluetooth firmware update!")
                    .foregroundColor(.green)
                    .font(.system(size: bodyFontSize))
                    .frame(width: contentWidth)
                    .padding(.bottom, 10)
            } else {
                Spacer()
                    .frame(width: contentWidth, height: 24)
                    .padding(.bottom, 10)
            }
        }
    }
    
    private var firmwareSelectionView: some View {
        VStack {
            Text("Select Firmware Version")
                .font(.system(size: titleFontSize, weight: .semibold))
                .frame(width: contentWidth)
                .opacity(midiManager.dfuModeConfirmed ? 1.0 : 0.3)
            HStack(spacing: 20) {
                ForEach(firmwareVersions, id: \.self) { version in
                    Button(action: {
                        selectedFirmware = version
                    }) {
                        Text(version)
                            .font(.system(size: buttonFontSize))
                            .padding()
                            .frame(width: 70)
                            .overlay(
                                RoundedRectangle(cornerRadius: 13)
                                    .stroke((selectedFirmware == version) && midiManager.dfuModeConfirmed ? Color.green : Color.gray, lineWidth: 2)
                            )
                            .background((selectedFirmware == version) && midiManager.dfuModeConfirmed ? Color.green.opacity(0.2) : Color.clear)
                    } .opacity(midiManager.dfuModeConfirmed ? 1.0 : 0.3)
                    .disabled(!midiManager.dfuModeConfirmed)
                }
            }
            .frame(width: contentWidth)
            .padding()
        }
    }
    
    private var dfuStatusView: some View {
        VStack(alignment: .leading) {
            Text("Device : \(ble.name)")
                .font(.system(size: smallFontSize))
                .frame(width: contentWidth, alignment: .leading)
            Text("Transfer speed : \(ble.kBPerSecond, specifier: "%.1f") kB/s")
                .font(.system(size: smallFontSize))
                .frame(width: contentWidth, alignment: .leading)
            Text("Elapsed time   : \(ble.elapsedTime, specifier: "%.1f") s")
                .font(.system(size: smallFontSize))
                .frame(width: contentWidth, alignment: .leading)
            
            // Replace text with progress bar
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Upload progress")
                        .font(.system(size: smallFontSize))
                    Spacer()
                    Text("\(ble.transferProgress, specifier: "%.1f") %")
                        .font(.system(size: smallFontSize))
                }
                .frame(width: contentWidth)
                ProgressView(value: ble.transferProgress, total: 100)
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(height: 25)
                    .frame(width: contentWidth)
            }
        }
        .opacity(midiManager.dfuModeConfirmed ? 1 : 0.3)
        .padding(.top, 10)
    }
    
    private var flashButton: some View {
        Button(action: {
            ble.sendFile(filename: selectedFirmware, fileEnding: ".bin")
        }) {
            Text("Flash \(selectedFirmware) to SWIFT")
                .font(.system(size: buttonFontSize, weight: .medium))
                .foregroundColor(midiManager.dfuModeConfirmed ? Color.green : Color.gray)
                .padding(.vertical)
                .frame(width: contentWidth)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(midiManager.dfuModeConfirmed ? Color.green : Color.gray, lineWidth: 2)
                )
        }
        .opacity(midiManager.dfuModeConfirmed ? 1 : 0.3)
        .disabled(ble.transferOngoing)
    }
    
    var body: some View {
        VStack {
            headerView
            firmwareUpdateButton
            statusMessageView
            firmwareSelectionView
            flashButton
            dfuStatusView
            
            if !ble.errorMessage.isEmpty {
                Text(ble.errorMessage)
                    .font(.system(size: smallFontSize))
                    .foregroundColor(.red)
                    .frame(width: contentWidth)
                    .padding()
            }
        }
        .frame(width: contentWidth + 40) // Add some padding
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        .padding()
        .accentColor(colorChange(ble.connected))
        .onDisappear {
            cancelRebootTimer()
        }
        .onChange(of: midiManager.dfuModeConfirmed) { newValue in
            if newValue {
                ble.startScanning()
            }
        }
    }
    
    // Start the reboot sequence with timer
    private func startRebootSequence() {
        isRebooting = true
        remainingTime = 10
        
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
