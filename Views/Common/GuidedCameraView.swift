import SwiftUI
import AVFoundation
import UIKit
import Observation

/// A premium, custom camera view with gyroscope-based anti-glare angle guidance.
/// Replaces the basic UIImagePickerController with a full AVCaptureSession pipeline.
struct GuidedCameraView: View {
    var onImageCaptured: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var guideManager = CaptureGuideManager()
    @State private var cameraModel = CameraSessionModel()
    @State private var flashAnimation = false
    @State private var capturedImage: UIImage?
    @State private var showProcessing = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // 1. Camera Preview Layer
            CameraPreviewLayer(session: cameraModel.session)
                .ignoresSafeArea()
            
            // 2. Flash overlay
            if flashAnimation {
                Color.white
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
            
            // 3. Top controls (Native-style back button)
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .padding(.leading, 16)
                    .padding(.top, 10)
                    
                    Spacer()
                }
                Spacer()
            }
            
            // 4. Bottom controls
            VStack {
                Spacer()
                Button(action: capturePhoto) {
                    ZStack {
                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                            .frame(width: 72, height: 72)
                        
                        Circle()
                            .fill(Color.white)
                            .frame(width: 60, height: 60)
                    }
                }
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            guideManager.startMonitoring()
            cameraModel.startSession()
        }
        .onDisappear {
            guideManager.stopMonitoring()
            cameraModel.stopSession()
        }
        .fullScreenCover(isPresented: $showProcessing) {
            if let image = capturedImage {
                CaptureProcessingView(
                    capturedImage: image,
                    onComplete: { processedImage in
                        onImageCaptured(processedImage)
                        dismiss()
                    },
                    onRetake: {
                        showProcessing = false
                        capturedImage = nil
                    }
                )
            }
        }
        .statusBarHidden()
    }
    
    // MARK: - Subviews
    
    
    // MARK: - State Helpers
    
    
    // MARK: - Actions
    
    private func capturePhoto() {
        HapticManager.shared.impact(.heavy)
        
        cameraModel.capturePhoto { image in
            guard let image else { return }
            
            // Flash effect
            withAnimation(.easeIn(duration: 0.05)) { flashAnimation = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 0.2)) { flashAnimation = false }
            }
            
            HapticManager.shared.notification(.success)
            capturedImage = image
            showProcessing = true
        }
    }
}

// MARK: - AVCaptureSession Model

@Observable
final class CameraSessionModel: NSObject {
    let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private var completion: ((UIImage?) -> Void)?
    
    func startSession() {
        guard !session.isRunning else { return }
        
        // Check permissions first
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted { self?.setupSession() }
            }
        default:
            print("Camera access denied")
        }
    }
    
    private func setupSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo
        
        // Remove existing inputs/outputs
        session.inputs.forEach { session.removeInput($0) }
        session.outputs.forEach { session.removeOutput($0) }
        
        // Standard back camera
        guard let camera = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            session.commitConfiguration()
            return
        }
        
        if session.canAddInput(input) { session.addInput(input) }
        if session.canAddOutput(output) { session.addOutput(output) }
        
        session.commitConfiguration()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
    }
    
    func stopSession() {
        guard session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.stopRunning()
        }
    }
    
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        self.completion = completion
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .off  // Flash causes glare on metal badges
        output.capturePhoto(with: settings, delegate: self)
    }
}

extension CameraSessionModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            completion?(nil)
            return
        }
        completion?(image)
    }
}

// MARK: - Camera Preview UIViewRepresentable

struct CameraPreviewLayer: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }
    
    func updateUIView(_ uiView: PreviewView, context: Context) {
        // Optimization: only update if session changed
        if uiView.videoPreviewLayer.session !== session {
            uiView.videoPreviewLayer.session = session
        }
    }
}

class PreviewView: UIView {
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
}

extension CameraSessionModel {
    func checkCameraSelection() {
        let deviceTypes: [AVCaptureDevice.DeviceType] = [.builtInWideAngleCamera, .builtInDualCamera, .builtInTripleCamera]
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes, mediaType: .video, position: .back)
        print("Available cameras: \(discoverySession.devices.map { $0.localizedName })")
    }
}
