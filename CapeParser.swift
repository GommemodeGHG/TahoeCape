import Foundation

class CapeParser {
    static func parse(at url: URL) throws -> Cape {
        var plistURL = url
        
        // Check if the URL is a directory (bundle)
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
            // It's a bundle, look for Contents.plist or Info.plist
            let possibleNames = ["Contents.plist", "Info.plist"]
            var found = false
            for name in possibleNames {
                let checkURL = url.appendingPathComponent(name)
                if FileManager.default.fileExists(atPath: checkURL.path) {
                    plistURL = checkURL
                    found = true
                    break
                }
            }
            if !found {
                throw NSError(domain: "CapeParser", code: 1, userInfo: [NSLocalizedDescriptionKey: "No plist found in .cape bundle"])
            }
        }
        
        let data = try Data(contentsOf: plistURL)
        
        // Debug: Log the keys in the plist
        if let dict = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] {
            AppLogger.shared.log("Plist Keys: \(dict.keys.joined(separator: ", "))")
            if let cursors = dict["Cursors"] as? [String: Any] ?? dict["cursors"] as? [String: Any] {
                AppLogger.shared.log("Found \(cursors.count) cursors.")
                if let firstKey = cursors.keys.first, let firstVal = cursors[firstKey] {
                    AppLogger.shared.log("First Cursor (\(firstKey)) Type: \(type(of: firstVal))")
                    if let cursorDict = firstVal as? [String: Any] {
                        AppLogger.shared.log("Cursor Keys: \(cursorDict.keys.joined(separator: ", "))")
                        if let reps = cursorDict["Representations"] ?? cursorDict["representations"] {
                            AppLogger.shared.log("Representations Type: \(type(of: reps))")
                            if let repsArray = reps as? [Any], let firstRep = repsArray.first {
                                AppLogger.shared.log("First Rep Content: \(firstRep)")
                            } else if let repsDict = reps as? [String: Any], let firstRep = repsDict.values.first {
                                AppLogger.shared.log("First Rep Content: \(firstRep)")
                            }
                        }
                    }
                }
            }
        }

        let decoder = PropertyListDecoder()
        
        do {
            var cape = try decoder.decode(Cape.self, from: data)
            
            // Post-process to link assets if it's a bundle
            if isDir.boolValue {
                cape = linkAssets(for: cape, in: url)
            }
            
            return cape
        } catch {
            print("Decoding error: \(error)")
            throw error
        }
    }
    
    /// If it's a bundle, we need to load the image data from the files
    static func linkAssets(for cape: Cape, in bundleURL: URL) -> Cape {
        var updatedCursors = cape.cursors
        
        for (cursorName, cursor) in updatedCursors {
            var updatedReps = cursor.representations
            for (scale, rep) in updatedReps {
                if let path = rep.path, rep.data == nil {
                    let imageURL = bundleURL.appendingPathComponent(path)
                    if let data = try? Data(contentsOf: imageURL) {
                        updatedReps[scale] = Representation(path: path, data: data, frame: rep.frame)
                    }
                }
            }
            updatedCursors[cursorName] = Cursor(id: cursor.id, hotspot: cursor.hotspot, representations: updatedReps, frameCount: cursor.frameCount, frameDuration: cursor.frameDuration)
        }
        
        return Cape(id: cape.id, name: cape.name, author: cape.author, version: cape.version, cursors: updatedCursors)
    }
}
