//
//  ExecutionService.swift
//  SupportXPC
//
//  Created by Jordy Witteman on 29/11/2023.
//

import Foundation

struct ExecutionService {
    
    static func getUpdateDeclaration(completion: @escaping (Data) -> Void) throws -> Void {
        
        // Specify the path to the plist file
        let plistPath = "/private/var/db/softwareupdate/SoftwareUpdateDDMStatePersistence.plist" // Replace this with the actual path to your plist file
        
        // Check if the file exists
        if FileManager.default.fileExists(atPath: plistPath) {
            logger.debug("macOS software update declaration plist was found")
            
            // Read the plist file
            do {
                // Read plist data from the file
                let plistData = try Data(contentsOf: URL(fileURLWithPath: plistPath))
                completion(plistData)
                
            } catch {
                logger.error("Error reading plist: \(error)")
            }
        } else {
            logger.debug("No macOS software update declaration plist found")
        }
    }

    static func executeScript(command: String, completion: @escaping ((NSNumber) -> Void)) throws -> Void {
        
        let process = Process()
        process.launchPath = "/bin/zsh"
        process.arguments = ["-c", command]

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        try process.run()
        
        // Stream script output to Unified Logging
        outputPipe.fileHandleForReading.readabilityHandler = { fileHandle in
            let data = fileHandle.availableData
            if data.isEmpty {
                outputPipe.fileHandleForReading.readabilityHandler = nil
                return
            }
            if let outputString = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .newlines) {
                logger.log("\(outputString, privacy: .public)")
                print(outputString)
            }
        }
                
        process.waitUntilExit()
        
        process.terminationHandler = { process in
            completion(NSNumber(value: process.terminationStatus))
        }
    }
}