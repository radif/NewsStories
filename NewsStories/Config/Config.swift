//
//  Config.swift
//  NewsStories
//
//  Created by Radif Sharafullin on 12/11/25.
//

import Foundation

enum Config {
    enum Error: Swift.Error, LocalizedError {
        case missingKey(String)
        case missingPlist

        var errorDescription: String? {
            switch self {
            case .missingKey(let key):
                return "Missing configuration key: \(key)"
            case .missingPlist:
                return "Secrets.plist not found in bundle"
            }
        }
    }

    private static var secrets: [String: Any]? = {
        guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist") else {
            print("Config: Secrets.plist not found in bundle")
            return nil
        }
        guard let data = try? Data(contentsOf: url) else {
            print("Config: Could not read Secrets.plist data")
            return nil
        }
        guard let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
            print("Config: Could not parse Secrets.plist")
            return nil
        }
        print("Config: Secrets.plist loaded successfully with keys: \(plist.keys)")
        return plist
    }()

    static var newsAPIKey: String {
        get throws {
            guard let secrets else {
                throw Error.missingPlist
            }
            guard let key = secrets["NEWS_API_KEY"] as? String else {
                throw Error.missingKey("NEWS_API_KEY")
            }
            return key
        }
    }

    static var claudeAPIKey: String {
        get throws {
            guard let secrets else {
                throw Error.missingPlist
            }
            guard let key = secrets["CLAUDE_API_KEY"] as? String else {
                throw Error.missingKey("CLAUDE_API_KEY")
            }
            return key
        }
    }
}
