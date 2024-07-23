SDDownloadManager
=================
![alt text](/SDDownloadManager/sddwn.png)

A simple and robust download manager for iOS (Swift 5) based on `URLSession` to deal with asynchronous downloading and management of multiple files.

`SDDownloadManager` is a singleton instance and can thus be called in your code safely from wherever you need to. The idea of writing yet another download manager library stemmed from the fact there are no available open source projects written using Swift based on the new `URLSession` APIs.

***Background downloads are supported starting from version 1.1.0*** 


`SDDownloadManager` leverages the power of `URLSession` and `URLSessionDownloadTask` to make downloading of files and keeping track of their progress a breeze. Originally inspired by TWRDownloadManager (https://github.com/chasseurmic/TWRDownloadManager)

- - - 

## Minimum iOS version support

iOS 12.0

## Installing the library

To use the library, just add the dependency to your `Podfile`:

```ruby
platform :ios
pod 'SDDownloadManager', '2.0.0'
```

Run `pod install` to install the dependencies.

## Usage

`SDDownloadManager` provides APIs for the following tasks:

- Downloading multiple files asynchronusly to your specified directory.
- Keeping track of download progress and download completion via closure syntax, no need to implement delegates!


### Downloading files

```swift
public func dowloadFile(withRequest request: URLRequest,
                        inDirectory directory: String? = nil,
                        withName fileName: String? = nil,
                        onProgress progressBlock:DownloadProgressBlock? = nil,
                        onCompletion completionBlock:@escaping DownloadCompletionBlock) -> String? 
```

#### Parameters :

- `request` : A `URLRequest` which represents a downloadable resource.

- `directory` : A `String` which represents a directory name inside the Caches directory of the app.

All the files, once downloaded will be moved from the `/tmp` directory of the device to the Caches directory. This is done for two reasons:
 
  1) The `/tmp` directory can be cleaned once in a while to make sure that any partial, cancelled or failed downloads get properly disposed of and do not occupy space both on the device and in iTunes backups.
  2) The Caches directory is not synced by default with the user's iCloud documents. This is in compliance with Apple's rules about content that – not being user-specific – can be re-downloaded from the internet and should not be synced with iCloud.

If a directory name is provided, a new sub-directory will be created in the Cached directory.

- `fileName` : Once the file is finished downloading, if a `fileName` was provided by the user, it will be used to store the file in its final destination. If no name was provided the manager will use by default the suggested file name that comes in the response parameter OR last path component of the URL string (e.g. for `http://www.example.com/files/my_image.jpg`, the final file name would be `my_image.jpg`).

- `progressBlock` : Called back with a `CGFloat` value ranging from 0 to 1.0 when the download progresses.

- `completionBlock` : Called back with two parameters `error` and `fileUrl`.
    - If the download was successful, `fileUrl` represents the URL of the file. The file can be accessed using this url.
    - If the download was unsuccessful, `error` represents the error that occured in the downloading process.
    
#### Calling this method
```swift
SDDownloadManager.shared.downloadFile( /*Params */)
```    
    
#### return

- The method returns a key which is unique to that download call. Ideally, this key can be used later for cancelling the download or altering the progress block of a specific download.  ***If a download with the speicied urlrequest already exists, this method returns `nil`.***

### Downloading files in background

The parameter `shouldDownloadInBackground` to the method `downloadFile()` decides whether the download should occur using a background session.
For background downloads to be supported, add this to your `AppDelegate`
```swift
func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
    debugPrint("handleEventsForBackgroundURLSession: \(identifier)")
    SDDownloadManager.shared.backgroundCompletionHandler = completionHandler
}
```

If you want to show a local notification after all background downloads finish, set `showLocalNotificationOnBackgroundDownloadDone` to `true`. You can set the text of local notification using `localNotificationText` property, Refer the following snippet : 

```swift
SDDownloadManager.shared.showLocalNotificationOnBackgroundDownloadDone = true  // Set this if you want to issue a local notification when all the background downloads complete.
SDDownloadManager.shared.localNotificationText = "All background downloads complete"  // Text for the local notification
let downloadKey = SDDownloadManager.shared.downloadFile(withRequest: request, inDirectory: directoryName, withName: directoryName, shouldDownloadInBackground: true, onProgress: { (progress) in
        let percentage = String(format: "%.1f %", (progress * 100))
        debugPrint("Background progress : \(percentage)")
    }) { [weak self] (error, url) in
        if let error = error {
            print("Error is \(error as NSError)")
        } else {
            if let url = url {
                print("Downloaded file's url is \(url.path)")
            }
        }
    }
```
      
### Checking for current downloads 

To check if a file is being downloaded, you can use one of the following methods:
```swift
public func isDownloadInProgress(forKey key:String?) -> Bool
```

To get all the dowloads that are in progress:
```swift
public func currentDownloads() -> [String]
```

To alter the blocks of an ongoing download:
```swift
public func alterDownload(withKey key:String?,
                          onProgress progressBlock:DownloadProgressBlock?,
                          onCompletion completionBlock:@escaping DownloadCompletionBlock)
```
### Cancelling downloads

To cancel all downloads:
```swift
public func cancelAllDownloads()
```

To cancel a specific download:

```swift
public func cancelDownload(forUniqueKey key:String?)
```
                                  
## Requirements

`SDDownloadManager` requires iOS 12.x or greater.

## Future Enhancements

I'm planning to integrate the following features in upcoming releases :
- ~~Background Downloads.~~ (Now supported starting from version 1.1.0)
- Resumable Downloads.
- A better and clean example project with more demonstration. (It will be great if I get some help in this from those who are actually using it!)

## License

Usage is provided under the [MIT License](http://opensource.org/licenses/mit-license.php).  See LICENSE for the full details.

## Contributions

All contributions are welcome. Please fork the project to add functionalities and submit a pull request to merge them in next releases.
