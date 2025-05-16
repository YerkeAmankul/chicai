import Foundation

final class IAPManager {
    private init() {}
    static let shared = IAPManager()
    var isSubscribed: Bool = false
}
