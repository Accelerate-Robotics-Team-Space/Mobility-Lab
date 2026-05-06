//
//  Copyright © 2024 Atlas LiftTech. All rights reserved.
//

import Combine
import FactoryKit
import Foundation
import Network

protocol NetworkMonitorProtocol: AnyObject {
    @available(*, deprecated, renamed: "isConnected", message: "use isConnected instead")
    var isNetworkAvailable: Bool { get }
    func start()
    func stop()
    var isConnectedPublisher: Published<Bool>.Publisher { get }
    var isConnected: Bool { get }
}

#if BMM
extension Container {
    var networkMonitor: Factory<any NetworkMonitorProtocol> {
        self { NetworkMonitor() }.cached
    }
}
#endif

final class NetworkMonitor: ObservableObject, NetworkMonitorProtocol {
    private let container: Container
    #if UMM
    static let shared = NetworkMonitor()
    private var mqttService: MQTTServiceProtocol = MQTTService.shared
    private let notificationCenter: NotificationCenterServiceProtocol = NotificationCenterService.shared
    #elseif BMM
    private var mqttService: MQTTServiceProtocol { container.mqttService.resolve() }
    @Injected(\.notificationCenter) private var notificationCenter
    #endif

    static let connectionNote = Notification.Name("network-monitor-connected")
    static let disconnectionNote = Notification.Name("network-monitor-disconnected")
    
    private let networkMonitor: NetworkPathMonitorProtocol
    private let netMonitorQueue = DispatchQueue(label: "Network-Monitor")
    @Published private(set) var isConnected = false
    @Published private var speed: Double = 0.0
    private var speedTestTimer: Timer?
    private let speedTester = SpeedTest()

    var isConnectedPublisher: Published<Bool>.Publisher {
        $isConnected
    }

    var isNetworkAvailable: Bool {
        networkMonitor.currentNetworkStatus == .satisfied
    }
    
    init(_ container: Container = .shared, networkMonitor: NetworkPathMonitorProtocol = NetworkPathMonitor()) {
        self.networkMonitor = networkMonitor
        self.container = container
        networkMonitor.statusUpdateHandler = { [weak self] status in
            switch status {
            case .satisfied:
                self?.notificationCenter.post(name: Self.connectionNote, object: nil)
                self?.isConnected = true
                self?.mqttService.connect()
                DispatchQueue.main.async {
                    self?.speedTestTimer?.invalidate()
                    self?.speedTestTimer = nil
                }
            case .unsatisfied, .requiresConnection:
                self?.isConnected = false
                self?.notificationCenter.post(name: Self.disconnectionNote, object: nil)
                DispatchQueue.main.async {
                    self?.speedTestTimer?.invalidate()
                    self?.speed = 0.0
                }
            @unknown default:
                logger.error("Network Monitor Error: Unknown Case for pathUpdateHandler")
            }
        }
    }
    
    func start() {
        networkMonitor.start(queue: netMonitorQueue)
    }
    
    func stop() {
        networkMonitor.cancel()
    }
}

@preconcurrency
protocol NetworkPathMonitorProtocol: AnyObject {
    var statusUpdateHandler: ((NWPath.Status) -> Void)? { get set }
    func start(queue: DispatchQueue)
    func cancel()
    var currentNetworkStatus: NWPath.Status { get }
}

final class NetworkPathMonitor: NetworkPathMonitorProtocol {
    var statusUpdateHandler: ((NWPath.Status) -> Void)?
    let monitor: NWPathMonitor

    var currentNetworkStatus: NWPath.Status {
        monitor.currentPath.status
    }

    init(monitor: NWPathMonitor = NWPathMonitor()) {
        self.monitor = monitor
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            self.statusUpdateHandler?(path.status)
        }
    }

    func start(queue: DispatchQueue) {
        monitor.start(queue: queue)
    }

    func cancel() {
        monitor.cancel()
    }
}
