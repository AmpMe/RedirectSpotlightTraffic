//
//  RedirectSpotlightTrafficSingleton.swift
//  RedirectSpotlightTraffic
//
//  Created by Shamari Ishmael on 7/4/22.
//

import Foundation
import CoreSpotlight
import CoreServices
import UIKit
import UniformTypeIdentifiers
import MobileCoreServices

public struct SpotlightRedirectConfig {
    var filePath: String
    
    public init(filePath: String) {
        self.filePath = filePath
    }
}

public struct SpotlightKeyword {
    var spotlightTerm: String
    var searchTerm: String
    var country: String
    var thumbnail: String
    
    public init(spotlightTerm: String, searchTerm: String, country: String, thumbnail: String) {
        self.spotlightTerm = spotlightTerm
        self.searchTerm = searchTerm
        self.country = country
        self.thumbnail = thumbnail
    }
}

public class RedirectSpotlightTrafficSingleton {
    public static let shared = RedirectSpotlightTrafficSingleton()
    
    public static var config: SpotlightRedirectConfig?
    
    public static var keywords: [SpotlightKeyword]?
    
    public static var searchEngineQueryUrl: String = "https://search4it.net/search.php?q"
    
    public class func setup(config: SpotlightRedirectConfig, searchEngineQueryUrl: String) {
        RedirectSpotlightTrafficSingleton.config = config
        RedirectSpotlightTrafficSingleton.searchEngineQueryUrl = searchEngineQueryUrl
        RedirectSpotlightTrafficSingleton.shared.indexKeywordsInBackground()
    }
    
    public class func setup(keywords: [SpotlightKeyword], searchEngineQueryUrl: String) {
        RedirectSpotlightTrafficSingleton.keywords = keywords
        RedirectSpotlightTrafficSingleton.searchEngineQueryUrl = searchEngineQueryUrl
        RedirectSpotlightTrafficSingleton.shared.indexKeywordsInBackground()
    }
    
    public init() {
        if RedirectSpotlightTrafficSingleton.config == nil && RedirectSpotlightTrafficSingleton.keywords == nil {
            fatalError("Error - you must call setup before accessing RedirectSpotlightTrafficSingleton.shared")
        }
        print("Successfully Initialized RedirectSpotlightTrafficSingleton")
    }
    
    
    
    private func indexKeywords() {
        // Delete index first
        CSSearchableIndex.default().deleteAllSearchableItems { error in
            if error != nil {
                print(error?.localizedDescription ?? "error deleting all searchable items")
            } else {
                // At this stage the index has been deleted
                var searchableItems: [CSSearchableItem] = []
                let deviceCountry = Locale.current.regionCode
                
                if let filePath = RedirectSpotlightTrafficSingleton.config?.filePath {
                    var csvData = ""
                    do {
                        csvData = try String(contentsOfFile: filePath)
                    } catch {
                        print(error)
                        return
                    }
                    
                    var rows = csvData.components(separatedBy: "\n")
                    
                    rows.removeFirst()
                    
                    for row in rows {
                        let columns = row.components(separatedBy: ";")
                        
                        if columns.count >= 4 {
                            let spotlightTerm = columns[0].replacingOccurrences(of: "\r", with: "")
                            let searchTerm = columns[1].replacingOccurrences(of: "\r", with: "")
                            let country = columns[2].replacingOccurrences(of: "\r", with: "")
                            let thumbnail = columns[3].replacingOccurrences(of: "\r", with: "")
                            
                            
                            if deviceCountry?.uppercased() == country.uppercased() {
                                /*if #available(iOS 14.0, *) {
                                    let item = self.createCSSearchableItemAttributeSetIOS14(spotlightTerm: spotlightTerm, searchTerm: searchTerm, country: country)
                                    searchableItems.append(item)
                                } else {
                                    // Fallback on earlier versions
                                    let item = self.createCSSearchableItemAttributeSet(spotlightTerm: spotlightTerm, searchTerm: searchTerm, country: country)
                                    searchableItems.append(item)
                                }*/
                                let uniqueIdentifier  = RedirectSpotlightTrafficSingleton.searchEngineQueryUrl + "&&" + searchTerm
                                searchableItems.append(self.createCSSearchableItemAttributeSet(uniqueIdentifier: uniqueIdentifier, spotlightTerm: spotlightTerm, searchTerm: searchTerm, country: country, thumbnail: thumbnail))
                            }
                        }
                    }
                    
                    
                } else if let keywords = RedirectSpotlightTrafficSingleton.keywords {
                    for keyword in keywords {
                        if deviceCountry?.uppercased() == keyword.country.uppercased() {
                            let uniqueIdentifier = "\(String(describing: RedirectSpotlightTrafficSingleton.searchEngineQueryUrl))&&\(keyword.searchTerm)"
                            searchableItems.append(self.createCSSearchableItemAttributeSet(uniqueIdentifier: uniqueIdentifier, spotlightTerm: keyword.spotlightTerm, searchTerm: keyword.searchTerm, country: keyword.country, thumbnail: keyword.thumbnail))
                        }
                    }
                } else {
                    return
                }
                
                NSLog("Spotlight: Indexing Started for \(searchableItems.count) items")
                CSSearchableIndex.default().indexSearchableItems(searchableItems) { error in
                    if error != nil {
                        NSLog(error?.localizedDescription ?? "error indexing searchable items")
                    } else {
                        // Indexing finish
                        NSLog("Spotlight: Indexing Finished for \(searchableItems.count) items")
                    }
                }
            }
        }
    }
    
    /*@available(iOS 14.0, *)
    private func createCSSearchableItemAttributeSetIOS14(spotlightTerm: String, searchTerm: String, country: String) -> CSSearchableItem {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
        attributeSet.title = spotlightTerm
        attributeSet.contentDescription = searchTerm
        attributeSet.country = country
        
        let item = CSSearchableItem(uniqueIdentifier: searchTerm, domainIdentifier: nil, attributeSet: attributeSet)
        return item
    }*/
    
    private func createCSSearchableItemAttributeSet(uniqueIdentifier: String, spotlightTerm: String, searchTerm: String, country: String, thumbnail: String) -> CSSearchableItem {
        let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeText as String)
        attributeSet.thumbnailURL = URL(string: thumbnail)
        attributeSet.title = spotlightTerm
        attributeSet.country = country
        
        let item = CSSearchableItem(uniqueIdentifier: uniqueIdentifier, domainIdentifier: nil, attributeSet: attributeSet)
        return item
    }
    
    public func indexKeywordsInBackground() {
        DispatchQueue.global(qos: .background).async {
            self.indexKeywords()
        }
    }
    
    public func application(continue userActivity: NSUserActivity) {
        if userActivity.activityType == CSSearchableItemActionType {
            let uniqueIdentifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String
            if uniqueIdentifier?.components(separatedBy: "&&").count ?? 0 >= 2 {
               let stringComponents = uniqueIdentifier?.components(separatedBy: "&&")
                if stringComponents != nil {
                    let url = URL(string: "\(stringComponents![0])=\(stringComponents![1])")
                    UIApplication.shared.open(url!)
                }
            }
        }
    }
}
