# Swift Datastore

Solve the headache/rewriting of classes to read and write arbitrary json data locally on device

## Installing 

Just add the Github url in swift package manager 

```
https://github.com/mperkins808/swift-datastore
```

```
import Datastore
```

## Usage

Create a struct that conforms to Codable 

```swift
    struct SomeData: Codable {
        var name : String
        var age : Int
    }
```

True one liner reading of JSON data.

```swift
    if let data = Datastore.jsonDecode(Data, as: Table.self).obj {
        // ...
    }

    // or if you want to read the error 
    let result = Datastore.jsonDecode(Data, as: Table.self) 
    guard let data = result.obj else {
        print(result.err!)
    }
```

Save data to disk. If the directory doesn't exist it will be created.

```swift
    func Save() {
        let data = SomeData(name: "Mat", age: 24)
        let dir = Datastore.GetDirectory("example")
        let result = Datastore.SaveGeneric(dir, fname: "mat.json", data: data)
        switch result.status {
        case .ERROR:
            print(result.err!)
        case .OK:
            print("file saved")
        }

        // or 
        if let err = result.error {
            // ... 
        }
    }
```

Read it from disk 

```swift
    func Load() {
        let dir = Datastore.GetDirectory("example")
        let result = Datastore.LoadGeneric(dir, fname: "mat.json", as: SomeData.self)
        switch result.status {
        case .ERROR:
            print(result.err!)
        case .OK:
            print("file loaded")
            print(result.obj!)
        }
    }
```

Reading API calls? Just parse response data directly 

```swift
    func Parse(_ jsonData: Data) {
        let result = Datastore.jsonDecode(jsonData, as: SomeData.self)
        switch result.status {
        case .ERROR:
            print(result.err!)
        case .OK:
            print(result.obj!)
        }
    }
```