//
//  ContentView.swift
//  AeroAPIDemo
//
//  Created by Justin Ackermann on 9/26/23.
//

import SwiftUI
import AeroAPI
import NomadUtilities

struct ContentView: View {

    
    
    var body: some View {
        VStack {
            #if os(iOS)
            ImageView(request: try! MapDataRequest(
                faId: "UAL231-1696166227-fa-837p"
            )).frame(width: 350, height: 350 * (480/640))
            #endif
        }
        .task {
//            do {
//                let data = try await AeroAPI
//                    .manager
//                    .getMap(for: MapDataRequest(
//                        faId: "UAL231-1696166227-fa-837p"
//                    ))
//
//                let image = UIImage(data: data)
//
//
//            } catch { error.explain() }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .onViewDidLoad {
                
            }
    }
}

class ImageViewModel: ObservableObject {
    @Published var image: UIImage?
    
    init(request: MapDataRequest) {
        Task { @MainActor in
            image = try await AeroAPI
                .manager
                .getMap(for: request)
        }
    }
}

struct ImageView: View {
    @ObservedObject private var imageViewModel: ImageViewModel
    
    init(request: MapDataRequest)
    { imageViewModel = .init(request: request) }
    
    var body: some View {
        Image(uiImage: imageViewModel.image ?? UIImage())
            .resizable()
    }
}

struct ImageView_Previews: PreviewProvider {
    static var previews: some View {
        return VStack { }
    }
}
