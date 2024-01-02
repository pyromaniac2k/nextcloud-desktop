/*
 * Copyright (C) 2023 by Claudio Cambra <claudio.cambra@nextcloud.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
 * for more details.
 */

import Foundation
import FileProvider
import OSLog

class ClientCommunicationService: NSObject, NSFileProviderServiceSource, NSXPCListenerDelegate, ClientCommunicationProtocol {
    let listener = NSXPCListener.anonymous()
    let serviceName = NSFileProviderServiceName("com.nextcloud.desktopclient.ClientCommunicationService")
    let fpExtension: FileProviderExtension

    init(fpExtension: FileProviderExtension) {
        Logger.desktopClientConnection.debug("Instantiating client communication service")
        self.fpExtension = fpExtension
        super.init()
    }

    func makeListenerEndpoint() throws -> NSXPCListenerEndpoint {
        listener.delegate = self
        listener.resume()
        return listener.endpoint
    }

    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        newConnection.exportedInterface = NSXPCInterface(with: ClientCommunicationProtocol.self)
        newConnection.exportedObject = self
        newConnection.resume()
        return true
    }

    //MARK: - Client Communication Protocol methods

    func getExtensionAccountId(completionHandler: @escaping (String?, Error?) -> Void) {
        let accountUserId = self.fpExtension.domain.identifier.rawValue
        Logger.desktopClientConnection.info("Sending extension account ID \(accountUserId, privacy: .public)")
        completionHandler(accountUserId, nil)
    }

    func configureAccount(withUser user: String, 
                          serverUrl: String,
                          password: String) {
        Logger.desktopClientConnection.info("Received configure account information over client communication service")
        self.fpExtension.setupDomainAccount(user: user,
                                            serverUrl: serverUrl,
                                            password: password)
    }

    func removeAccountConfig() {
        self.fpExtension.removeAccountConfig()
    }

    func createDebugArchive(at url: URL!) {
        if #available(macOSApplicationExtension 12.0, *) {
            Logger.createDebugArchive(saveFolderUrl: url)
        }
    }
}
