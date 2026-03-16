import SwiftUI


struct CollageView: View {
    let images: [UIImage]
    let layout: CollageLayout
    var watermark: String? = "ItaBinder"
    
    var body: some View {
        VStack(spacing: 4) {
            content
                .background(Color.white)
            
            if let watermark = watermark {
                HStack {
                    Spacer()
                    Text(watermark)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.gray.opacity(0.5))
                        .padding(.trailing, 8)
                }
                .padding(.bottom, 4)
            }
        }
        .background(Color.white)
        .frame(width: 300) // Base width for rendering
    }
    
    @ViewBuilder
    private var content: some View {
        switch layout {
        case .oneByThree:
            VStack(spacing: 2) {
                ForEach(0..<min(images.count, 3), id: \.self) { index in
                    Image(uiImage: images[index])
                        .resizable()
                        .scaledToFill()
                        .frame(height: 150)
                        .clipped()
                }
            }
            
        case .twoByTwo:
            VStack(spacing: 2) {
                HStack(spacing: 2) {
                    collageImage(at: 0)
                    collageImage(at: 1)
                }
                HStack(spacing: 2) {
                    collageImage(at: 2)
                    collageImage(at: 3)
                }
            }
        }
    }
    
    @ViewBuilder
    private func collageImage(at index: Int) -> some View {
        if index < images.count {
            Image(uiImage: images[index])
                .resizable()
                .scaledToFill()
                .frame(width: 149, height: 149)
                .clipped()
        } else {
            Color.gray.opacity(0.1)
                .frame(width: 149, height: 149)
        }
    }
}

#Preview {
    CollageView(images: [UIImage(systemName: "photo")!, UIImage(systemName: "photo")!, UIImage(systemName: "photo")!], layout: .oneByThree)
}
