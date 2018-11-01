// Copyright (c) 2017-2018 Coinbase Inc. See LICENSE

import RxSwift
import SystemConfiguration

private let apiHost = "www.google.com"

public final class Internet {
    private static let shared = Internet()

    private var isRunning: Bool = false
    private let changes = BehaviorSubject<ConnectionStatus>(value: .unknown)
    private var reachability = SCNetworkReachabilityCreateWithName(nil, apiHost)

    /// Get the current network status
    public private(set) static var status: ConnectionStatus = .unknown {
        didSet {
            if oldValue != status {
                Internet.shared.changes.onNext(status)
            }
        }
    }

    /// Observer for new network status changes
    public static var statusChanges: Observable<ConnectionStatus> {
        return Internet.shared.changes.asObservable()
    }

    /// Determine whether network is online or not
    public static var isOnline: Bool {
        switch Internet.status {
        case .connected:
            return true
        default:
            return false
        }
    }

    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(stop),
            name: .UIApplicationWillResignActive,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(start),
            name: .UIApplicationDidBecomeActive,
            object: nil
        )
    }

    /// Stop monitoring network changes
    public static func stopMonitor() {
        Internet.shared.stop()
    }

    /// Start monitoring network changes
    public static func startMonitor() {
        Internet.shared.start()
    }

    // MARK: - Manage network monitor

    @objc
    private func start() {
        assert(Thread.isMainThread)
        if isRunning {
            return
        }

        guard let reachability = self.reachability ?? SCNetworkReachabilityCreateWithName(nil, apiHost) else {
            return assertionFailure("Unable to create new instance of network reachability")
        }

        isRunning = true
        var context = SCNetworkReachabilityContext(version: 0, info: nil, retain: nil, release: nil,
                                                   copyDescription: nil)

        SCNetworkReachabilityScheduleWithRunLoop(reachability, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue)

        SCNetworkReachabilitySetCallback(reachability, { _, flags, _ in
            Internet.status = ConnectionStatus(flags: flags)
        }, &context)
    }

    @objc
    private func stop() {
        assert(Thread.isMainThread)
        guard isRunning, let reachability = self.reachability else {
            return
        }

        isRunning = false
        SCNetworkReachabilitySetCallback(reachability, nil, nil)
        SCNetworkReachabilityUnscheduleFromRunLoop(reachability, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue)
        self.reachability = SCNetworkReachabilityCreateWithName(nil, apiHost)
    }
}
