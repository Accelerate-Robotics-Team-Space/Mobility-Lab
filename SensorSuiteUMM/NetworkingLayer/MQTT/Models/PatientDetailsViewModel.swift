//
//  PatientDetailsViewModel.swift
//  SensorSuiteUMM
//
//  Created by Nguyen Bui on 11/1/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import Combine
import Foundation

class PatientDetailsViewModel: ObservableObject {
    @Published var id: String
    @Published var weightInPounds: Int?
    @Published var heightInInches: Int?
    @Published var sex: ALTSex?
    @Published var turnProtocol: String?
    @Published var complianceDegree: Int?
    private var weightSubscriber: Set<AnyCancellable> = []
    private var heightSubscriber: Set<AnyCancellable> = []
    
    init(
        id: String,
        weightInPounds: Int? = nil,
        heightInInches: Int? = nil,
        sex: ALTSex? = nil
    ) {
        self.id = id
        self.weightInPounds = weightInPounds
        self.heightInInches = heightInInches
        self.sex = sex
    }
}
