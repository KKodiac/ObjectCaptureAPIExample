//
//  SwiftUIView.swift
//  HeadScanner
//
//  Created by Sean Hong on 2022/11/11.
//

import SwiftUI
import os

private let logger = Logger(subsystem: "com.seanhong.KKodiac.HeadScanner",
                            category: "ShareView")
struct ShareView: View {
    @State private var isActivityPresented = false
    
    @ObservedObject var model: CameraViewModel
    @ObservedObject var captureFolderState: CaptureFolderState
    let usingCurrentCaptureFolder: Bool
    
    init(model: CameraViewModel) {
        self.model = model
        self.captureFolderState = model.captureFolderState!
        self.usingCurrentCaptureFolder = true
    }
    
    init(model: CameraViewModel, observing captureFolderState: CaptureFolderState) {
        self.model = model
        self.captureFolderState = captureFolderState
        usingCurrentCaptureFolder = (model.captureFolderState?.captureDir?.lastPathComponent
                                        == captureFolderState.captureDir?.lastPathComponent)
    }
    
    var body: some View {
        Button("Send to Macbook for processing!") {
            self.isActivityPresented = true
            logger.log("Current folder \(String(describing: captureFolderState.captureDir?.lastPathComponent))")
        }.sheet(isPresented: $isActivityPresented) {
            ActivityView(activityItems: [captureFolderState.captureDir!], isPresented: $isActivityPresented)
                .presentationDetents([.fraction(0.0)])
        }
    }
}

struct ActivityView: UIViewControllerRepresentable {
    var activityItems: [URL]
    var applicationActivities: [UIActivity]? = nil
    @Binding var isPresented: Bool

    func makeUIViewController(context: Context) -> ActivityViewWrapper {
        ActivityViewWrapper(activityItems: activityItems, applicationActivities: applicationActivities, isPresented: $isPresented)
    }

    func updateUIViewController(_ uiViewController: ActivityViewWrapper, context: Context) {
        uiViewController.isPresented = $isPresented
        uiViewController.updateState()
    }
}

class ActivityViewWrapper: UIViewController {
    var activityItems: [URL]
    var applicationActivities: [UIActivity]?
    var isPresented: Binding<Bool>
    
    var archiveUrl: URL?
    var error: NSError?
    let coordinator = NSFileCoordinator()

    init(activityItems: [URL], applicationActivities: [UIActivity]? = nil, isPresented: Binding<Bool>) {
        self.activityItems = activityItems
        
        self.applicationActivities = applicationActivities
        self.isPresented = isPresented
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        updateState()
    }
    
    fileprivate func createZipFile() {
        coordinator.coordinate(readingItemAt: activityItems.first!, options: [.forUploading], error: &error) { (zipUrl) in
            let tempUrl = try! FileManager.default.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: zipUrl, create: true).appendingPathComponent("archive.zip")
            try! FileManager.default.moveItem(at: zipUrl, to: tempUrl)
            
            archiveUrl = tempUrl
        }
    }

    fileprivate func updateState() {
        guard parent != nil else {return}
        let isActivityPresented = presentedViewController != nil
        if isActivityPresented != isPresented.wrappedValue {
            if !isActivityPresented {
                if let archiveUrl = archiveUrl {
                    let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
                    controller.popoverPresentationController?.sourceView = self.view
                    controller.excludedActivityTypes = [.addToReadingList, .assignToContact, .openInIBooks, .postToVimeo, .postToWeibo, .postToFlickr, .postToTwitter, .postToFacebook, .postToTencentWeibo]
                    controller.completionWithItemsHandler = { (activityType, completed, _, _) in
                        self.isPresented.wrappedValue = false
                    }
                    present(controller, animated: true, completion: nil)
                } else {
                    self.createZipFile()
                }
            }
            else {
                self.presentedViewController?.dismiss(animated: true, completion: nil)
            }
        }
    }
}
