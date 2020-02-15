//
//  ViewController.swift
//  syphon-kinect-metal-client
//
//  Created by George Brown on 23.01.20.
//  Copyright © 2020 George Brown. All rights reserved.
//

import Cocoa
import Syphon
import MetalKit

class DisplayViewController: NSViewController {
    var syphonServerDirectory: SyphonServerDirectory!
    var syphonClient: SyphonMetalClient?
    var pointCloudRenderer: KinectRenderer?
    
    let niMateSyphonServerAppName:String = "Delicode NI mate"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        syphonServerDirectory = SyphonServerDirectory.shared()
        guard let view = view as? MTKView else {
            print("Could not get view as metal")
            return
        }
        view.device = MTLCreateSystemDefaultDevice()
        view.enableSetNeedsDisplay = true
        
        //view.colorPixelFormat = MTLPixelFormat.bgra8Unorm
        print(view)
        print(view.device ?? "No device")
        print(view.colorPixelFormat)
        
    }
    
    override func viewDidAppear() {
        guard let view = view as? MTKView else {
            return
        }
        super.viewDidAppear()
        pointCloudRenderer = KinectRenderer(with: view)
        print("View = \(view)")
        print("View is kind of mtkView :\(view.isKind(of: MTKView.self))")
                NotificationCenter.default.addObserver(self, selector: #selector(handleSyphonServerAnnouce(notification:)), name: NSNotification.Name.SyphonServerAnnounce, object: nil)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    @objc func handleSyphonServerAnnouce(notification: Notification) {
        print("Syphon Server announced")

        guard let userInfo = notification.userInfo else { return }
        guard let view = view as? MTKView, let device = view.device else {
            print("Could not get view \(self.view)")
            return }
        print("\(SyphonServerDescriptionAppNameKey):\(userInfo[SyphonServerDescriptionAppNameKey] ?? "Missing object")")
        print("\(SyphonServerDescriptionNameKey):\(String(describing: userInfo[SyphonServerDescriptionNameKey]))")
        guard let serverAppName = userInfo[SyphonServerDescriptionAppNameKey] as? String,
            serverAppName == niMateSyphonServerAppName,
            let serverName = userInfo[SyphonServerDescriptionNameKey] as? String,
            serverName.hasSuffix("_depth") else {
                return
        }

        guard let client = SyphonMetalClient(serverDescription: userInfo, device: device, colorPixelFormat: MTLPixelFormat.bgra8Unorm, options: nil, newFrameHandler: { [weak self] (frameClient) in
            guard let self = self,
            let frameClient = frameClient else {
                return
            }
            self.pointCloudRenderer?.depthTexture = frameClient.newFrameImage()
            self.view.needsDisplay = true
            
            //print("Has new frame \(String(describing: frameClient?.newFrameImage()))")
        }) else {
            print("Failed to create client")
            return
        }
        print("client = \(client)")
        syphonClient = client
    }


}

