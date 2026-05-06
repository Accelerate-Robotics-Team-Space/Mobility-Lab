//
//  UIScrollViewWrapper.swift
//  SensorSuite
//
//  Created by Vadym Riznychok on 7/11/24.
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct UIScrollViewWrapper<Content: View>: UIViewControllerRepresentable {
    @Binding var contentWidth: CGFloat
    @Binding var contentOffset: CGPoint
    @Binding var lastContentOffset: CGPoint

    var content: () -> Content

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIScrollViewViewController {
        let viewController = UIScrollViewViewController()
        viewController.hostingController.rootView = AnyView(self.content())
        viewController.scrollView.delegate = context.coordinator
        return viewController
    }

    func updateUIViewController(_ viewController: UIScrollViewViewController, context: Context) {
        viewController.hostingController.rootView = AnyView(self.content())
        /// Hack to avoid SwiftUI warning: "Modifying state during view update, this will cause undefined behaviour."
        /// https://stackoverflow.com/questions/57442879/swiftui-how-do-i-avoid-modifying-state-during-view-update
        DispatchQueue.main.async {
            viewController.widthConstraint?.constant = self.contentWidth
            viewController.scrollView.contentOffset = self.contentOffset
        }
    }

    class Coordinator: NSObject, UIScrollViewDelegate {
        let parent: UIScrollViewWrapper

        init(parent: UIScrollViewWrapper) {
            self.parent = parent
        }

        func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
            parent.contentOffset = scrollView.contentOffset
        }

        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            parent.contentOffset = scrollView.contentOffset
        }

        func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
            if !decelerate {
                parent.contentOffset = scrollView.contentOffset
            }
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            parent.lastContentOffset = scrollView.contentOffset
        }
    }
}

class UIScrollViewViewController: UIViewController {
    lazy var scrollView: UIScrollView = {
        let view = UIScrollView()
        view.bounces = false
        return view
    }()

    weak var widthConstraint: NSLayoutConstraint?

    var hostingController: UIHostingController<AnyView> = UIHostingController(rootView: AnyView(EmptyView()))

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(self.scrollView)
        self.pinEdges(of: self.scrollView, to: self.view)

        self.hostingController.willMove(toParent: self)
        self.scrollView.addSubview(self.hostingController.view)
        self.pinEdges(of: self.hostingController.view, to: self.scrollView)
        widthConstraint = self.hostingController.view.widthAnchor.constraint(equalToConstant: 100)
        widthConstraint?.isActive = true
        self.hostingController.didMove(toParent: self)
    }

    func pinEdges(of viewA: UIView, to viewB: UIView) {
        viewA.translatesAutoresizingMaskIntoConstraints = false
        viewB.addConstraints([
            viewA.leadingAnchor.constraint(equalTo: viewB.leadingAnchor),
            viewA.trailingAnchor.constraint(equalTo: viewB.trailingAnchor),
            viewA.topAnchor.constraint(equalTo: viewB.topAnchor),
            viewA.bottomAnchor.constraint(equalTo: viewB.bottomAnchor),
        ])
    }
}
