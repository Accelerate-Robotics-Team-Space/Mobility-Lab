//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import SwiftUI

struct SystemInfoCell: View {
    @ObservedObject var bmmViewModel: BMMViewModel
    var showSystemInfo: Bool {
        bmmViewModel.cardData.canShowPatientDetails
    }

    var body: some View {
        VStack {
            Button {
                if bmmViewModel.currentOpening != .system {
                    bmmViewModel.currentOpening = .system
                } else {
                    bmmViewModel.currentOpening = .none
                }
            } label: {
                HStack {
                    Text(R.string.localizable.system())
                        .font(.custom("Avenir-Heavy", size: 20))
                        .foregroundColor(.charcoal1)
                    Spacer()
                    Image(R.image.arrowDown.name)
                        .resizable()
                        .frame(width: 24, height: 24)
                        .rotationEffect(.degrees(bmmViewModel.currentOpening == .system ? -180 : 0))
                        .animation(.spring(), value: bmmViewModel.currentOpening)
                }
            }

            if bmmViewModel.currentOpening == .system {
                Spacer().frame(height: 4)
                CellRow(title: R.string.localizable.turnProtocol(),
                        value: showSystemInfo ? bmmViewModel.patientDetailsViewModel?.turnProtocol ?? "" : "-")
                Divider()
                CellRow(title: R.string.localizable.complianceDegree(),
                        value: showSystemInfo ? "\(bmmViewModel.patientDetailsViewModel?.complianceDegree ?? 0)" : "-")
                Divider()
                CellRow(title: R.string.localizable.patientId(),
                        value: showSystemInfo ? bmmViewModel.patientDetailsViewModel?.id ?? "No ID" : "-")
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                Divider()
                CellRow(title: R.string.localizable.bmmDeviceId(), value: bmmViewModel.deviceId)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Divider()
                CellRow(title: R.string.localizable.ummDeviceId(), value: UserDefaults.standard.baseStationFromApple ?? "")
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
        .padding()
    }
}

private struct CellRow: View {
    var title: String
    var value: String
    @State var lineLimit = 2
    @State var minimumScaleFactor: CGFloat?

    var body: some View {
        HStack {
            Text(title)
                .font(.custom("Avenir-Heavy", size: 16))
                .foregroundColor(.charcoal1)
            Spacer()
            if let minimumScaleFactor {
                Text(value)
                    .font(.custom("Avenir-Roman", size: 16))
                    .foregroundColor(.charcoal3)
                    .lineLimit(lineLimit)
                    .minimumScaleFactor(minimumScaleFactor)
            } else {
                Text(value)
                    .font(.custom("Avenir-Roman", size: 16))
                    .foregroundColor(.charcoal3)
                    .lineLimit(lineLimit)
            }
        }
    }

    func lineLimit(_ lineLimit: Int) -> Self {
        var copy = self
        copy._lineLimit = .init(initialValue: lineLimit)
        return copy
    }

    func minimumScaleFactor(_ scaleFactor: CGFloat) -> Self {
        var copy = self
        copy._minimumScaleFactor = .init(initialValue: scaleFactor)
        return copy
    }
}

#Preview {
    SystemInfoCell(bmmViewModel: BMMViewModel())
}
