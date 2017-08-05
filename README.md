SDDownloadManager
=================

## SDDownloadManager

A simple and robust download manager for iOS (Swift 3) based on `URLSession` to deal with asynchronous downloading and management of multiple files.

`SDDownloadManager` is a singleton instance and can thus be called in your code safely from wherever you need to. The idea of writing yet another download manager library stemmed from the fact there are no available open source projects written using Swift based on the new `URLSession` APIs.

`SDDownloadManager` leverages the power of `URLSession` and `URLSessionDownloadTask` to make downloading of files and keeping track of their progress a breeze.

- - - 

## Installing the library

To use the library, just add the dependency to your `Podfile`:

```ruby
platform :ios
pod 'SDDownloadManager'
```

Run `pod install` to install the dependencies.

## Usage

`SDDownloadManager` provides facilities for the following task:

- Downloading multiple files asynchronusly.
- Keeping track of download progress and download completion via block syntax, no need to implement delegates!
- checking for file existence.

All the following instance methods can be called directly on 

### Downloading files



The easiest way to get started is by simply passing to the last of the aforementioned methods the URL string of the file that needs to be downloaded. You will get a chance to pass in two blocks that will help you keep track of the download progress (a float from 0 to 1) and of the completion of the task.

All the files, once downloaded will be moved from the `/tmp` directory of the device to the Caches directory. This is done for two reasons:
 
- the `/tmp` directory can be cleaned once in a while to make sure that any partial, cancelled or failed downloads get properly disposed of and do not occupy space both on the device and in iTunes backups;
- the Caches directory is not synced by default with the user's iCloud documents. This is in compliance with Apple's rules about content that – not being user-specific – can be re-downloaded from the internet and should not be synced with iCloud.

If a directory name is provided, a new sub-directory will be created in the Cached directory.

Once the file is finished downloading, if a name was provided by the user, it will be used to store the file in its final destination. If no name was provided the manager will use by default the last path component of the URL string (e.g. for `http://www.example.com/files/my_file.zip`, the final file name would be `my_file.zip`).

### Checking for current downloads 

To check if a file is being downloaded, you can use one of the following methods:

As with the previous download methods, you get a chance to be called back for progress and completion.

To retrieve a list of current files being downloaded, you can use the following:


This method returns an array of `NSString` objects with the URLs of the current downloads being performed.

### Canceling downloads

The downloads, which are uniquely referenced by the download manager by the provided URL, can either be canceled singularly or all together with a single call via one of the two following methods:




## Requirements

`SDDownloadManager` requires iOS 9.x or greater.


## License

Usage is provided under the [MIT License](http://opensource.org/licenses/mit-license.php).  See LICENSE for the full details.

## Contributions

All contributions are welcome. Please fork the project to add functionalities and open a pull request to have them merged into the master branch in the next releases.
