//
//  ControlsViewController.swift
//  syphon-kinect-metal-client
//
//  Created by George Brown on 23.01.20.
//  Copyright © 2020 George Brown. All rights reserved.
//

import Cocoa
import Syphon

class ControlsViewController: NSViewController {

    var syphonServerDirectory: SyphonServerDirectory!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        syphonServerDirectory = SyphonServerDirectory.shared()
        NotificationCenter.default.addObserver(self, selector: #selector(handleSyphonServerAnnouce(notification:)), name: NSNotification.Name.SyphonServerAnnounce, object: nil)
    }
    
    
    
    @objc func handleSyphonServerAnnouce(notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        print("Syphon Server announced")
        print("\(SyphonServerDescriptionAppNameKey):\(userInfo[SyphonServerDescriptionAppNameKey] ?? "Missing object")")
        print("\(SyphonServerDescriptionNameKey):\(String(describing: userInfo[SyphonServerDescriptionNameKey]))")
    }
    
}
