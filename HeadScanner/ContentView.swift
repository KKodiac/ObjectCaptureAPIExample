//
//  ContentView.swift
//  HeadScanner
//
//  Created by Sean Hong on 2022/11/07.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var model: CameraViewModel
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            CameraView(model: model)
        }
        .environment(\.colorScheme, .dark)
    }
}

struct ContentView_Previews: PreviewProvider {
    @StateObject private static var model = CameraViewModel()
    static var previews: some View {
        ContentView(model: model)
    }
}
