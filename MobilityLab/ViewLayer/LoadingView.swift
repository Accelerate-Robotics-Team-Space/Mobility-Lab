//
//  LoadingView.swift
//  MobilityLab BMM
//
//  Created by Deepika Ramesh on 3/12/24.
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct LoadingView: View {
	var msg: String
	
	var body: some View {
		ZStack {
			Rectangle()
				.fill(.black)
				.opacity(0.15)
				.ignoresSafeArea()
			
			VStack(spacing: 20) {
				ProgressView()
				Text(msg)
					.font(.custom("Avenir-Black", size: 20))
			}
			.background {
				RoundedRectangle(cornerRadius: 10)
					.fill(.white)
					.frame(width: 200, height: 200)
			}
			.offset(y: -70)
		}
	}
}

#Preview {
	LoadingView(msg: "Loading...")
}
