// swift-tools-version:5.3
import PackageDescription

let package = Package(name: "SDDownloadManager",
                      platforms: [.iOS(.v10)],
                      products: [.library(name: "SDDownloadManager",
                                          targets: ["SDDownloadManager"])],
                      targets: [.target(name: "SDDownloadManager",
                                        path: "SDDownloadManager/Classes"),
                                ]
                      )
