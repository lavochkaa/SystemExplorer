import Foundation

@main
struct EntitlementKeyParserTests {
    static func main() {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <plist version="1.0"><dict>
        <!-- <key>fake.comment</key> -->
        <key>com.example.alpha</key><true/>
        <key>com.example.nested</key><dict><key>fake.nested</key><true/></dict>
        <key>com.example.escaped&amp;key</key><string>value</string>
        </dict></plist>
        """
        precondition(EntitlementKeyParser.keys(from: xml) == [
            "com.example.alpha", "com.example.escaped&key", "com.example.nested"
        ])
        precondition(EntitlementKeyParser.keys(from: "") == ["No entitlements"])
        precondition(EntitlementKeyParser.keys(from: "<plist><dict><key>broken") == ["No entitlements"])
        print("3 entitlement parser cases passed")
    }
}
