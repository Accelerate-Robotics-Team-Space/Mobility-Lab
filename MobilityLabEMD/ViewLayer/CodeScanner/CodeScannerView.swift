//
//  CodeScannerView.swift
//  MobilityLabEMD
//
//  Created by Nguyen Bui on 10/20/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import AVFoundation
import SwiftUI

enum ScanError: Error {
    case badInput
    case badOutput
}

extension ScanError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .badInput:
            return "Bad Scanning Input"
        case .badOutput:
            return "Bad Scanning Output"
        }
    }
}

/// A SwiftUI view that is able to scan barcodes, QR codes, and more, and send back what was found.
/// To use, set `codeTypes` to be an array of things to scan for, e.g. `[.qr]`, and set `completion` to
/// a closure that will be called when scanning has finished. This will be sent the string that was detected or a `ScanError`.
/// For testing inside the simulator, set the `simulatedData` property to some test data you want to send back.
struct CodeScannerView: UIViewControllerRepresentable {
    let codeTypes: [AVMetadataObject.ObjectType]
    var simulatedData = ""
    var completion: (Result<String, ScanError>) -> Void
    var isUsingFrontCamera: Bool

    init(codeTypes: [AVMetadataObject.ObjectType], useFrontCamera: Bool = true, completion: @escaping (Result<String, ScanError>) -> Void) {
        self.codeTypes = codeTypes
        self.simulatedData = ""
        self.isUsingFrontCamera = useFrontCamera
        self.completion = completion
    }

    func makeCoordinator() -> ScannerCoordinator {
        return ScannerCoordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> ScannerViewController {
        let viewController = ScannerViewController()
        viewController.useFrontCamera = isUsingFrontCamera
        viewController.coordinator = context.coordinator
        return viewController
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}
}

struct CodeScannerView_Previews: PreviewProvider {
    static var previews: some View {
        CodeScannerView(codeTypes: [.qr]) { _ in
            // do nothing
        }
    }
}
