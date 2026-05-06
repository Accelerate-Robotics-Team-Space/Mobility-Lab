//
//  NotificationsCellView.swift
//  SensorSuite
//
//  Created by Josh Franco on 12/3/20.
//  Copyright © 2020 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct NotificationsCellView: View {
    @ObservedObject var driver: NotificationsCellDriver
    
    // MARK: - Body
    var body: some View {
        VStack {
            HStack(spacing: 16) {
                R.image.notificationSated.image
                    .renderingMode(.template)
                    .foregroundColor(.charcoal)
                
                Text("Notifications")
                    .textStyle(.header4)
                
                Spacer()
            }
            
            ForEach(driver.notifications) { note in
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.tangerine)
                    
                    Spacer()
                    
                    Text("\(note.description)")
                        .textStyle(.body1)
                }
                .padding()
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(5)
        .shadow(radius: 5)
    }
    
    // MARK: - Init
    init(_ manager: PatientManager) {
        self.driver = NotificationsCellDriver(using: manager)
    }
}

struct NotificationsCellView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationsCellView(.preview)
    }
}
