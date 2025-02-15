//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//       

import ArgumentParser
import DeviceDiscovery
import Foundation

/// A Command that kills running tmux session on the given devices.
/// This can be used to stop instances of a deployed web services without having to manually ssh into each deployment target.
public struct KillSessionCommand: ParsableCommand {
    public static var configuration: CommandConfiguration {
        CommandConfiguration(
            commandName: "kill-session",
            abstract: "IoT deployment - Stop Session",
            discussion: "Kills the running deployed system on the remote device.",
            version: "0.4.0"
        )
    }
    
    @Argument(help: "The type ids that should be searched for")
    var types: String
    
    @Option(help: "Name of the deployed web service")
    var productName: String
    
    @Flag(help: "If set, looks for the corresponding docker instance instead")
    var docker = false
    
    public init() {}

    public func run() throws {
        for id in types.split(separator: ",").map(String.init) {
            let discovery = DeviceDiscovery(DeviceIdentifier(id))
            discovery.configuration = [.runPostActions: false]

            let credentials = IoTContext.readUsernameAndPassword(for: id)
            let results = try discovery.run(2).wait()

            for result in results {
                let ipAddress = try IoTContext.ipAddress(for: result.device)
                let client = try SSHClient(username: credentials.username, password: credentials.password, ipAdress: ipAddress)
                IoTContext.logger.info("Trying to kill session on \(ipAddress)")
                if docker {
                    try client.execute(cmd: "sudo docker kill \(productName)")
                } else {
                    try client.execute(cmd: "tmux kill-session -t \(productName)")
                }
            }
            IoTContext.logger.info("Finished.")
        }
    }
}
