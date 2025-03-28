//
//  MyHelper.swift
//
//  Created by Claes Hallberg on 7/6/20.
//  Copyright © 2020 Claes Hallberg. All rights reserved.
//  Licence: MIT

import Foundation

/*----------------------------------------------------------------------------
 Load file (fileName: name.extension) return it in Data type
 First tries the firmware directory, then falls back to the main bundle
----------------------------------------------------------------------------*/
func getBinFileToData(fileName: String, fileEnding: String) throws -> Data? {
    // First check if file exists in the "firmware" directory in the app bundle
    if let firmwareDirectory = Bundle.main.url(forResource: "firmware", withExtension: nil),
       let fileURL = URL(string: "\(firmwareDirectory.absoluteString)/\(fileName)\(fileEnding)")?.standardized {
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                let fileData = try Data(contentsOf: fileURL)
                print("Loaded firmware file from firmware directory: \(fileURL.path)")
                return Data(fileData)
            } catch {
                print("Error loading firmware file from firmware directory: \(error)")
                // Fall back to main bundle if file not found in firmware directory
            }
        }
    }
    
    // Fall back to main bundle
    guard let fileURL = Bundle.main.url(forResource: fileName, withExtension: fileEnding) else { 
        print("Firmware file \(fileName)\(fileEnding) not found in main bundle")
        return nil 
    }
    
    do {
        let fileData = try Data(contentsOf: fileURL)
        print("Loaded firmware file from main bundle: \(fileURL.path)")
        return Data(fileData)
    } catch {
        print("Error loading firmware file from main bundle: \(error)")
        return nil
    }
}

