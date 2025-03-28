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
    @State private var selectedFirmware = "V8"
    let firmwareVersions = ["V8", "V9", "V10"]
    
    var body: some View{
        VStack{
            Text("Shiftwave SWIFT Bluetooth Firmware Updater").bold()
            VStack {
                Text("Device : \(ble.name)")
                Text("Transfer speed : \(ble.kBPerSecond, specifier: "%.1f") kB/s")
                Text("Elapsed time   : \(ble.elapsedTime, specifier: "%.1f") s")
                Text("Upload progress: \(ble.transferProgress, specifier: "%.1f") %")
            }
            HStack{
                Button(action: {
                    ble.startScanning()
                }){
                    Text("connect").padding().overlay(RoundedRectangle(cornerRadius: 15).stroke(colorChange(ble.connected), lineWidth: 2))
                }
                Button(action: {
                    ble.disconnect(forget: false)
                }){
                    Text("disconnect").padding().overlay(RoundedRectangle(cornerRadius: 15).stroke(colorChange(ble.connected), lineWidth: 2))
                }
                Button(action: {
                    ble.disconnect(forget: true)
                }){
                    Text("forget bond").padding().overlay(RoundedRectangle(cornerRadius: 15).stroke(colorChange(ble.connected), lineWidth: 2))
                }
            }
            
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
            HStack{
                Spacer()
            }
        }.padding().accentColor(colorChange(ble.connected))
    }
}

func colorChange(_ connected:Bool) -> Color{
    if connected{
        return Color.green
    }else{
        return Color.blue
    }
}
