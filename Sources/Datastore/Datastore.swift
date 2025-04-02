// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

public enum Status {
    case OK
    case ERROR
}

public struct DatastoreError: Error {
    let message: String
}

public struct Result<T: Codable> {
    public var status: Status
    public var err: DatastoreError?
    public var obj: T?
}

public struct Directory {
    var name: String

    func GetPath() -> String {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let docDir = paths[0]
        return docDir.appendingPathComponent(self.name).path
    }
}

public class Datastore {

    public static func GetDirectory(_ name: String) -> Directory {
        return Directory(name: name)
    }

    public static func SaveGeneric<T: Encodable>(_ dir: Directory, fname: String, data: T) -> Result<T> {
        if let err = writeToDisk(dir: dir.GetPath(), fName: fname, data: data) {
            return Result(status: .ERROR, err: err, obj: nil)
        }
        return Result(status: .OK, err: nil, obj: data)
    }

    public static func LoadGeneric<T: Decodable>(_ dir: Directory, fname: String, as type: T.Type)
        -> Result<T>
    {
        return readFromDisk(dir: dir.GetPath(), fName: fname, as: type)
    }

    static private func writeToDisk<T: Encodable>(dir: String, fName: String, data: T)
        -> DatastoreError?
    {
        do {
            let url = try createDirectoryIfNeeded(name: dir)
            let fUrl = url.appendingPathComponent(fName)

            // Encode data into JSON format before writing
            let encodedData = try JSONEncoder().encode(data)

            try encodedData.write(to: fUrl, options: .atomic)
            return nil
        } catch {
            return DatastoreError(message: "Error saving \(fName): \(error)")
        }
    }

    private func deleteFile(dir: String, fName: String) -> DatastoreError? {
        let fileManager = FileManager.default
        let docDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dataDir = docDir.appendingPathComponent(dir)
        let filePath = dataDir.appendingPathComponent(fName).path

        do {
            if fileManager.fileExists(atPath: filePath) {
                try fileManager.removeItem(atPath: filePath)
                return nil
            } else {
                return DatastoreError(message: "File not found at path: \(filePath)")
            }
        } catch {
            return DatastoreError(message: ("Error deleting file at path \(filePath): \(error)"))
        }
    }
    
    public func jsonEncode<T: Encodable>(_ object: T) -> Result<String> {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        do {
            let jsonData = try encoder.encode(object)
            if let str = String(data: jsonData, encoding: .utf8) {
                return Result(status: .OK, err: nil, obj: str)
            }
            return Result(
                status: .ERROR, err: DatastoreError(message: "Failed to encode object"), obj: nil)
        } catch {
            return Result(
                status: .ERROR, err: DatastoreError(message: "Failed to encode object: \(error)"),
                obj: nil)
        }
    }

    public func jsonDecode<T: Decodable>(_ jsonData: Data, as type: T.Type) -> Result<T> {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let decodedObject = try decoder.decode(T.self, from: jsonData)
            return Result(status: .OK, err: nil, obj: decodedObject)
        } catch {
            return Result(
                status: .ERROR, err: DatastoreError(message: "Failed to decode JSON: \(error)"),
                obj: nil)
        }
    }

}



func readFromDisk<T: Decodable>(dir: String, fName: String, as type: T.Type) -> Result<T> {
    let fManager = FileManager.default
    let docDir = fManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    let dataDir = docDir.appendingPathComponent(dir)
    let fUrl = dataDir.appendingPathComponent(fName)
    do {
        let data = try Data(contentsOf: fUrl)
        return jsonDecode(data, as: type)
    } catch {
        return Result(
            status: .ERROR, err: DatastoreError(message: "Error reading \(fName): \(error)"),
            obj: nil)
    }
}

private func writetoDisk(data: Data, dir: String, fName: String) -> DatastoreError? {
    do {
        let url = try createDirectoryIfNeeded(name: dir)
        let fUrl = url.appendingPathComponent(fName)
        let jsonData = try JSONEncoder().encode(data)
        try jsonData.write(to: fUrl, options: .atomic)
        return nil
    } catch {
        return DatastoreError(message: "Error saving \(fName): \(error)")
    }
}

private func createDirectoryIfNeeded(name: String) throws -> URL {
    let fileManager = FileManager.default
    let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    let dataDirectory = documentsDirectory.appendingPathComponent(name)

    if !fileManager.fileExists(atPath: dataDirectory.path) {
        try fileManager.createDirectory(at: dataDirectory, withIntermediateDirectories: true)
    }

    return dataDirectory
}
