//
//  HeadScannerApp.swift
//  HeadScanner
//
//  Created by Sean Hong on 2022/11/07.
//

import SwiftUI

@main
struct HeadScannerApp: App {
    @StateObject var model = CameraViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
        }
    }
}
