import Foundation

enum EntitlementKeyParser {
    static func keys(from xml: String) -> [String] {
        guard let plist = try? PropertyListSerialization.propertyList(
            from: Data(xml.utf8), options: [], format: nil
        ), let entitlements = plist as? [String: Any], !entitlements.isEmpty else {
            return ["No entitlements"]
        }
        return entitlements.keys.sorted()
    }
}
