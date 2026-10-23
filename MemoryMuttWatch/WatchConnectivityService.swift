import WatchConnectivity
import Foundation

struct WatchDeckPayload: Identifiable {
    let id: UUID
    let name: String
    let cards: [WatchCardPayload]
    /// Total due on the phone; `cards` is only the batch sent for this session.
    let dueCount: Int
}

struct WatchCardPayload: Identifiable {
    let id: UUID
    let front: String
    let back: String
    let easeFactor: Double
    let interval: Int
    let statusRaw: String

    var status: CardStatus { CardStatus(rawValue: statusRaw) ?? .new }
}

@Observable
@MainActor
final class WatchConnectivityService: NSObject, WCSessionDelegate {
    static let shared = WatchConnectivityService()

    var decks: [WatchDeckPayload] = []
    var isLoading = false
    var errorMessage: String?

    private var loadingTimeout: Task<Void, Never>?

    override init() {
        super.init()
        #if DEBUG
        if WatchScreenshotDemo.isActive {
            decks = WatchScreenshotDemo.decks
            return
        }
        #endif
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func requestDecks() {
        #if DEBUG
        if WatchScreenshotDemo.isActive { return }
        #endif
        let session = WCSession.default
        NSLog("MMWC watch requestDecks state=\(session.activationState.rawValue) reachable=\(session.isReachable) companion=\(session.isCompanionAppInstalled) inFlight=\(isLoading)")
        // One request at a time. Reachability flaps constantly on a real watch, and
        // re-requesting on every flap kept resetting the timeout so the spinner never ended.
        guard !isLoading else { return }

        guard session.activationState == .activated else {
            // The activation callback calls back in here on success, and reports an error
            // (without retrying) on failure — so this can't loop. Refresh retries activation.
            isLoading = true
            errorMessage = nil
            startLoadingTimeout()
            if session.activationState == .notActivated { session.activate() }
            return
        }
        guard session.isCompanionAppInstalled else {
            finishLoading(error: "Install MemoryMutt on your iPhone")
            return
        }
        guard session.isReachable else {
            finishLoading(error: "Can't reach your iPhone. Keep it nearby and tap Refresh.")
            return
        }
        isLoading = true
        errorMessage = nil
        startLoadingTimeout()

        NSLog("MMWC watch sending requestDecks message")
        session.sendMessage(["type": "requestDecks"]) { [weak self] reply in
            NSLog("MMWC watch got reply keys=\(Array(reply.keys))")
            Task { @MainActor [weak self] in
                self?.parseDecks(from: reply)
                self?.finishLoading()
            }
        } errorHandler: { [weak self] error in
            NSLog("MMWC watch sendMessage error=\(error)")
            Task { @MainActor [weak self] in
                self?.finishLoading(error: "iPhone didn't answer (\((error as NSError).code)). Open MemoryMutt on your iPhone, then tap Refresh.")
            }
        }
    }

    /// Guarantees the spinner is never permanent: if activation stalls or a
    /// reply is lost, clear the loading state and surface a recoverable message.
    private func startLoadingTimeout() {
        loadingTimeout?.cancel()
        loadingTimeout = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(10))
            guard let self, !Task.isCancelled, self.isLoading else { return }
            self.isLoading = false
            if self.decks.isEmpty && self.errorMessage == nil {
                let state = WCSession.default.activationState
                self.errorMessage = state == .activated
                    ? "Couldn't reach your iPhone. Open MemoryMutt on iPhone, then tap Refresh."
                    : "Watch connection didn't start (state \(state.rawValue)). Tap Refresh."
            }
        }
    }

    private func finishLoading(error: String? = nil) {
        loadingTimeout?.cancel()
        loadingTimeout = nil
        isLoading = false
        if let error { errorMessage = error }
    }

    func sendReview(cardID: UUID, rating: ReviewRating, result: (easeFactor: Double, interval: Int, nextReviewDate: Date, status: CardStatus)) {
        let message: [String: Any] = [
            "type": "recordReview",
            "cardID": cardID.uuidString,
            "rating": rating.rawValue,
            "newEaseFactor": result.easeFactor,
            "newInterval": result.interval,
            "newStatusRaw": result.status.rawValue,
            "newNextReviewDate": result.nextReviewDate.timeIntervalSince1970
        ]
        // Live delivery keeps the phone current; if it fails or the phone is out of
        // range, queue it — transferUserInfo is guaranteed to arrive eventually.
        guard WCSession.default.isReachable else {
            WCSession.default.transferUserInfo(message)
            return
        }
        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            NSLog("MMWC watch review send failed, queueing: \(error.localizedDescription)")
            WCSession.default.transferUserInfo(message)
        }
    }

    private func parseDecks(from response: [String: Any]) {
        guard let raw = response["decks"] as? [[String: Any]] else { return }
        decks = raw.compactMap { dict in
            guard let idStr = dict["id"] as? String,
                  let id = UUID(uuidString: idStr),
                  let name = dict["name"] as? String,
                  let cardsRaw = dict["cards"] as? [[String: Any]] else { return nil }
            let cards: [WatchCardPayload] = cardsRaw.compactMap { c in
                guard let idStr = c["id"] as? String,
                      let cid = UUID(uuidString: idStr),
                      let front = c["front"] as? String,
                      let back = c["back"] as? String,
                      let ef = c["easeFactor"] as? Double,
                      let iv = c["interval"] as? Int,
                      let sr = c["statusRaw"] as? String else { return nil }
                return WatchCardPayload(id: cid, front: front, back: back, easeFactor: ef, interval: iv, statusRaw: sr)
            }
            let dueCount = dict["dueCount"] as? Int ?? cards.count
            return WatchDeckPayload(id: id, name: name, cards: cards, dueCount: dueCount)
        }
    }

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        NSLog("MMWC watch activationDidComplete state=\(activationState.rawValue) error=\(error?.localizedDescription ?? "nil")")
        Task { @MainActor in
            // A request parked waiting on activation is still "loading"; release it and retry.
            self.isLoading = false
            if activationState == .activated {
                self.requestDecks()
            } else {
                self.finishLoading(error: "Watch connection failed: \(error?.localizedDescription ?? "unknown error"). Tap Refresh.")
            }
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        // Only retry when there's nothing on screen yet; don't reload mid-study.
        if session.isReachable {
            Task { @MainActor in
                if self.decks.isEmpty { self.requestDecks() }
            }
        }
    }
}
