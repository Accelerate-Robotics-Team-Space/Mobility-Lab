//
//  ScannerContainerView.swift
//  MobilityLab
//
//  Created by Josh Franco on 9/15/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct ScannerContainerView: View {
    @Binding var showContainer: Bool
    
    private let indicatorOffset: CGFloat = 50
    private let indicatorLineWidth: CGFloat = 8
    private let cornerRad: CGFloat = 7.5
    private var completion: (Result<String, ScanError>) -> Void
    
    private var isDevEnv: Bool {
        ALTEnvironment.current == .dev || ALTEnvironment.current == .qa
    }
    
    // MARK: - Body
    var body: some View {
        GeometryReader { geo in
            ZStack {
                CodeScannerView(codeTypes: [.qr],
                                useFrontCamera: isDevEnv ? false : true,
                                completion: self.completion)
                    .cornerRadius(cornerRad,
                                  corners: [.topLeft, .topRight])
                    
                Color.black
                    .edgesIgnoringSafeArea(.all)
                    .opacity(0.75)
                    .mask(SquareHoleShape(holeSize: geo.size.width - indicatorOffset))
                    .cornerRadius(cornerRad,
                                  corners: [.topLeft, .topRight])
                
                SquareIndicatorShape(indicatorLength: 75)
                    .stroke(style: StrokeStyle(lineWidth: indicatorLineWidth,
                                               lineCap: .round,
                                               lineJoin: .round))
                    .foregroundColor(.red)
                    .frame(width: geo.size.width - indicatorOffset,
                           height: geo.size.width - indicatorOffset)
                
                VStack {
                    HStack {
                        DirectionalBtn(.left, style: .primary(),
                                       labelStr: R.string.localizable.back()) {
                            showContainer.toggle()
                        }
                        .padding()
                        
                        Spacer()
                    }
            
                    Spacer()
                }
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Init
    init(_ showContainer: Binding<Bool>, completion: @escaping (Result<String, ScanError>) -> Void) {
        self._showContainer = showContainer
        self.completion = completion
    }
}

struct ScannerContainerView_Previews: PreviewProvider {
    static var previews: some View {
        ScannerContainerView(.constant(true), completion: { _ in })
    }
}
