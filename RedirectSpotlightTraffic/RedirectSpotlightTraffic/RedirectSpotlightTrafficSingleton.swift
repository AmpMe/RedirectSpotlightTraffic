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

public class RedirectSpotlightTrafficSingleton {
    public static let shared = RedirectSpotlightTrafficSingleton()
    
    public static var config: SpotlightRedirectConfig?
    
    public class func setup(_ config: SpotlightRedirectConfig) {
        RedirectSpotlightTrafficSingleton.config = config
        
        RedirectSpotlightTrafficSingleton.shared.indexKeywordsInBackground()
    }
    
    public init() {
        guard let _ = RedirectSpotlightTrafficSingleton.config else {
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
                
                guard let filePath = RedirectSpotlightTrafficSingleton.config?.filePath else {
                    return
                }
                
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
                    let columns = row.components(separatedBy: ",")
                    
                    if columns.count == 3 {
                        let spotlightTerm = columns[0]
                        let searchTerm = columns[1]
                        let country = columns[2].replacingOccurrences(of: "\r", with: "")
                        
                        let deviceCountry = Locale.current.regionCode
                        
                        if deviceCountry?.uppercased() == country.uppercased() {
                            /*if #available(iOS 14.0, *) {
                                let item = self.createCSSearchableItemAttributeSetIOS14(spotlightTerm: spotlightTerm, searchTerm: searchTerm, country: country)
                                searchableItems.append(item)
                            } else {
                                // Fallback on earlier versions
                                let item = self.createCSSearchableItemAttributeSet(spotlightTerm: spotlightTerm, searchTerm: searchTerm, country: country)
                                searchableItems.append(item)
                            }*/
                            let item = self.createCSSearchableItemAttributeSet(spotlightTerm: spotlightTerm, searchTerm: searchTerm, country: country)
                            searchableItems.append(item)
                        }
                    }
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
    
    private func createCSSearchableItemAttributeSet(spotlightTerm: String, searchTerm: String, country: String) -> CSSearchableItem {
        let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeText as String)
        attributeSet.title = spotlightTerm
        attributeSet.contentDescription = searchTerm
        attributeSet.country = country
        
        let item = CSSearchableItem(uniqueIdentifier: searchTerm, domainIdentifier: nil, attributeSet: attributeSet)
        return item
    }
    
    public func indexKeywordsInBackground() {
        DispatchQueue.global(qos: .background).async {
            self.indexKeywords()
        }
    }
    
    public func application(continue userActivity: NSUserActivity) {
        if userActivity.activityType == CSSearchableItemActionType {
            if let uniqueIdentifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String,
               let url = URL(string: "https://www.bing.com/search?q=\(uniqueIdentifier)") {
                UIApplication.shared.open(url)
            }
        }
    }
}
