//
//  CameraManager.swift
//  SeeSoSample
//
//  Created by David on 1/4/24.
//  Copyright © 2024 VisaulCamp. All rights reserved.
//

import Foundation
import AVKit

class CameraManager : NSObject {
  private var captureSession = AVCaptureSession()
  private let videoDevice = AVCaptureDevice.default(for: AVMediaType.video)
  private var videoInput: AVCaptureInput?
  private var videoOutput = AVCaptureVideoDataOutput()
  private var videoLayer: AVCaptureVideoPreviewLayer?
  private var metaOutput: AVCaptureMetadataOutput?

  weak var delegate: CameraManagerDelegate?


  override init() {
    super.init()
    setVideoInput()
    setVideoOutput()
  }

  private func setVideoInput() {
    do {
      let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .front)
      videoInput = try AVCaptureDeviceInput(device: captureDevice!) as AVCaptureInput
      captureSession.addInput(videoInput!)
    } catch let error as NSError {
      print(error)
    }
  }

  private func setVideoOutput() {   
    videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]

    let queue = DispatchQueue.main
    videoOutput.setSampleBufferDelegate(self, queue: queue)
    captureSession.addOutput(videoOutput)
    videoOutput.connection(with: .video)?.videoOrientation = .portrait
    videoOutput.alwaysDiscardsLateVideoFrames = true
    captureSession.sessionPreset = AVCaptureSession.Preset.hd1280x720
  }

  func start() {
    DispatchQueue.global(qos: .userInteractive).async {
      self.captureSession.startRunning()
    }
  }

  func stop() {
    DispatchQueue.global(qos: .userInteractive).async {
      self.captureSession.stopRunning()
    }
  }

  public func getInput() -> AVCaptureInput? {
    return videoInput
  }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    delegate?.videoOutput(sampleBuffer: sampleBuffer)
  }
}


protocol CameraManagerDelegate: AnyObject {
  func videoOutput(sampleBuffer: CMSampleBuffer)
}
