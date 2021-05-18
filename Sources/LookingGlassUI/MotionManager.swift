//
//  MotionManager.swift
//  ReflectiveUI
//
//  Created by Ryan Lintott on 2020-09-17.
//

import CoreMotion
import FirebladeMath
import SwiftUI

@available(iOS 13, *)
class MotionManager: ObservableObject {
    static let defaultUpdateInterval: TimeInterval = 0.1
    static let motionQueue = OperationQueue()
    static let screenSize = UIScreen.main.bounds.size
    static let maxScreenDimension = max(MotionManager.screenSize.height, MotionManager.screenSize.width)
    
    private let cmManager = CMMotionManager()

    // set to 0 for off
    @Published private(set) var updateInterval: TimeInterval {
        didSet {
            toggleIfNeeded()
        }
    }
    
    @Published private(set) var disabled: Bool = false {
        didSet {
            toggleIfNeeded()
        }
    }
    
    @Published private(set) var animatedQuaternion: Quat4f = .identity
    @Published private(set) var quaternion: Quat4f = .identity
    
    @Published var deviceOrientation: UIDeviceOrientation = .unknown
    
    public init(updateInterval: TimeInterval = defaultUpdateInterval) {
        self.updateInterval = updateInterval

        toggleIfNeeded()
    }
    
    deinit {
        cmManager.stopDeviceMotionUpdates()
    }
    
    var isDetectingMotion: Bool {
        updateInterval > 0 && !disabled
    }
    
    var interfaceSize: CGSize {
        switch deviceOrientation {
        case .landscapeRight, .landscapeLeft:
            return CGSize(width: MotionManager.screenSize.height, height: MotionManager.screenSize.width)
        default:
            return MotionManager.screenSize
        }
    }
    
    public func changeDeviceOrientation() {
        let newOrientation = UIDevice.current.orientation

        guard deviceOrientation != newOrientation else {
            return
        }
        
        if InfoDictionary.supportedOrientations.contains(newOrientation) {
            self.deviceOrientation = newOrientation
        }
    }
    
    public func setUpdateInterval(_ newUpdateInterval: TimeInterval) {
        if updateInterval != newUpdateInterval {
            updateInterval = newUpdateInterval
        }
    }
    
    public func setDisabled(_ newDisabled: Bool) {
        if disabled != newDisabled {
            disabled = newDisabled
        }
    }
    
    public func restart() {
        cmManager.stopDeviceMotionUpdates()        
        toggleIfNeeded()
    }
    
    private func toggleIfNeeded() {
        if cmManager.isDeviceMotionActive {
            cmManager.stopDeviceMotionUpdates()
        }
        
        guard updateInterval > 0 && !disabled else { return }

        cmManager.deviceMotionUpdateInterval = updateInterval

        cmManager.startDeviceMotionUpdates(to: .main) { motionData, error in
            if let motionData = motionData {
                let quaternion = motionData.attitude.quaternion.quat4f
                
                self.quaternion = quaternion
                withAnimation(Animation.linear(duration: self.updateInterval)) {
                    self.animatedQuaternion = quaternion
                }
                
            } else if let error = error {
                print(error.localizedDescription)
            } else {
                print("Error - Unknown motion update error")
            }
        }
    }
}
