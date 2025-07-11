//
//  ContentView.swift
//  Instafilter
//
//  Created by BizMagnets on 03/07/25.
//

import SwiftUI
import PhotosUI
import CoreImage
import StoreKit
import CoreImage.CIFilterBuiltins

struct ContentView: View {
    @State private var processedImage: Image?
    @State private var filterIntensity = 0.5
    @State private var selectedItem: PhotosPickerItem?
    @State private var currentFilter: CIFilter = CIFilter.sepiaTone()
    @State private var showingFilters = false
    @AppStorage("filterCount") var filterCount = 0
    @Environment(\.requestReview) var requestReview
    let context = CIContext()

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()

                PhotosPicker(selection: $selectedItem) {
                    if let img = processedImage {
                        img
                            .resizable()
                            .scaledToFit()
                    } else {
                        ContentUnavailableView(
                            "No picture",
                            systemImage: "photo.badge.plus",
                            description: Text("Tap to import a photo")
                        )
                    }
                }
                .buttonStyle(.plain)
                .onChange(of: selectedItem, loadImage)

                Spacer()

                HStack {
                    Text("Intensity")
                    Slider(value: $filterIntensity)
                        .onChange(of: filterIntensity, applyProcessing)
                }

                HStack {
                    Button("Change Filter", action: changeFilter)
                    Spacer()
                    if let processedImage {
                        ShareLink(item: processedImage, preview: SharePreview("Instafilter image", image: processedImage))
                    }
                }
            }
            .padding([.horizontal, .bottom])
            .navigationTitle("Instafilter")
            .confirmationDialog("Select a filter", isPresented: $showingFilters) {
                Button("Crystallize")    { setFilter(CIFilter.crystallize()) }
                Button("Edges")          { setFilter(CIFilter.edges()) }
                Button("Gaussian Blur")  { setFilter(CIFilter.gaussianBlur()) }
                Button("Pixellate")      { setFilter(CIFilter.pixellate()) }
                Button("Sepia Tone")     { setFilter(CIFilter.sepiaTone()) }
                Button("Unsharp Mask")   { setFilter(CIFilter.unsharpMask()) }
                Button("Vignette")       { setFilter(CIFilter.vignette()) }
                Button("Cancel", role: .cancel) { }
            }
        }
    }

    func changeFilter() {
        showingFilters = true
    }

    func loadImage() {
        Task {
            guard
                let data = try await selectedItem?.loadTransferable(type: Data.self),
                let uiImage = UIImage(data: data)
            else { return }

            let ciImage = CIImage(image: uiImage)
            currentFilter.setValue(ciImage, forKey: kCIInputImageKey)
            applyProcessing()
        }
    }

    func applyProcessing() {
        let keys = currentFilter.inputKeys
        if keys.contains(kCIInputIntensityKey) { currentFilter.setValue(filterIntensity, forKey: kCIInputIntensityKey) }
        if keys.contains(kCIInputRadiusKey)    { currentFilter.setValue(filterIntensity * 200, forKey: kCIInputRadiusKey) }
        if keys.contains(kCIInputScaleKey)     { currentFilter.setValue(filterIntensity * 10,  forKey: kCIInputScaleKey) }

        guard
            let output = currentFilter.outputImage,
            let cgimg  = context.createCGImage(output, from: output.extent)
        else { return }

        processedImage = Image(uiImage: UIImage(cgImage: cgimg))
    }

    @MainActor func setFilter(_ filter: CIFilter) {
        currentFilter = filter
        loadImage()
        filterCount += 1

        if filterCount >= 20 {
            requestReview()
        }
    }
}

#Preview {
    ContentView()
}

