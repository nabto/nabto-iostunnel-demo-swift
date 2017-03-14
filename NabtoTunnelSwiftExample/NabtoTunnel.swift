//
//  NabtoTunnel.swift
//  NabtoTunnelSwiftExample
//
//  Simple demonstration of using Nabto Client SDK tunnel api from swift.
//
//  Known issues: 
//    * NABTO-1447: NabtoClient.nabtoStatusString does not handle 3.0.15 API error codes
//    * NABTO-1448: Not possible to retrieve underlying error on tunnel API errors
//    * NABTO-1449: Introduce asynchronous tunnel API
//
//  Created by Nabto on 3/13/17.
//  Copyright © 2017 Nabto. All rights reserved.
//

import Foundation

class NabtoTunnel {

    var tunnel: nabto_tunnel_t? = nil
    var tunnelTimer: Timer? = nil
    let nabto = { return NabtoClient.instance() as! NabtoClient }()

    func start() -> Bool {
        var status = nabto.nabtoStartup()
        if (status != NABTO_OK) {
            print("Nabto startup failed: \(status)")
            return false
        }
        
        status = nabto.nabtoOpenSessionGuest()
        if (status != NABTO_OK) {
            print("Open session failed: \(status)")
            return false
        }
        
        status = nabto.nabtoTunnelOpenTcp(&tunnel, toHost:"streamdemo.nabto.net", onPort: 80)
        if (status == NABTO_OK) {
            print("Open tunnel succeeded, polling state to know when ready to use")
            self.startPeriodicStatusCheck()
            return true;
        } else {
            print("Open tunnel failed: \(status)")
            return false
        }
    }
    
    func stop() {
        tunnelTimer?.invalidate()
        nabto.nabtoShutdown()
    }

    func startPeriodicStatusCheck() {
        tunnelTimer = Timer.scheduledTimer(timeInterval: 0.1, target:self, selector: #selector(self.checkTunnelStatus), userInfo: nil, repeats: true)
    }
    
    @objc func checkTunnelStatus() {
        let tunnelState = nabto.nabtoTunnelInfo(tunnel)
        if (tunnelState == NTCS_CONNECTING) {
            print(".", terminator:"")
        } else {
            tunnelTimer?.invalidate()
            if (self.isConnected(tunnelState:tunnelState)) {
                let info = NabtoClient.nabtoTunnelInfoString(tunnelState)
                let port = nabto.nabtoTunnelPort(tunnel)
                print("Connection established: \(info!), local port is \(port)")
                print("TODO: now connect your TCP client (e.g. browser or RTSP player) to '127.0.0.1:\(port)'")
            } else {
                let error = nabto.nabtoTunnelError(tunnel)
                print("Connection failed: '\(error)' (tunnelState=\(tunnelState))")
                print("TODO: retry / handle connect error")
            }
        }
    }
    
    func isConnected(tunnelState: nabto_tunnel_state_t) -> Bool {
        return tunnelState == NTCS_LOCAL ||
            tunnelState == NTCS_REMOTE_P2P ||
            tunnelState == NTCS_REMOTE_RELAY ||
            tunnelState == NTCS_REMOTE_RELAY_MICRO
    }
    
}
