//
//  CameraManager.swift
//  mirroringBooth
//
//  Created by 이상유 on 2025-12-27.
//

import Foundation
import AVFoundation

final class CameraManager: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    private let session = AVCaptureSession()
    private let cameraQueue = DispatchQueue(label: "cameraQueue")
    
    func startSession() throws {
        session.sessionPreset = .hd1280x720
        
        guard let device = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .back
        ) else { return }
        
        let input = try AVCaptureDeviceInput(device: device)
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: cameraQueue)
        output.alwaysDiscardsLateVideoFrames = true
        
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        
        session.startRunning()
    }
    
    func stopSession() {
        session.stopRunning()
    }
    
    // 프레임 처리
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        
    }
    
}
