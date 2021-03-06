//
//  DataManager.swift
//  iSeaGoals
//
//  Created by Pham Van Hai on 4/4/19.
//  Copyright © 2019 Pham Van Hai. All rights reserved.
//

import Foundation

struct DataManager {
    
    //*****************************************************************
    // Helper struct to get either local or remote JSON
    //*****************************************************************
    
    static func getDataWithSuccess(success: @escaping ((_ metaData: Data?, _ error: Error?) -> Void)) {
        
        DispatchQueue.global(qos: .userInitiated).async {
            if useLocalData {
                getDataFromFileWithSuccess() { data in
                    success(data, nil)
                }
            } else {
                guard let matchDataURL = URL(string: matchDataURL) else {
                    if kDebugLog { print("matchDataURL not a valid URL") }
                    success(nil, nil)
                    return
                }
                
                loadDataFromURL(url: matchDataURL) { data, error in
                    success(data, error)
                }
            }
        }
    }
    
    //*****************************************************************
    // Load local JSON Data
    //*****************************************************************
    
    static func getDataFromFileWithSuccess(success: (_ data: Data?) -> Void) {
        guard let filePathURL = Bundle.main.url(forResource: "match_data", withExtension: "json") else {
            if kDebugLog { print("The local JSON file could not be found") }
            success(nil)
            return
        }
        
        do {
            let data = try Data(contentsOf: filePathURL, options: .uncached)
            success(data)
        } catch {
            fatalError()
        }
    }
    
    //*****************************************************************
    // REUSABLE DATA/API CALL METHOD
    //*****************************************************************
    
    static func loadDataFromURL(url: URL, completion: @escaping (_ data: Data?, _ error: Error?) -> Void) {
        
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.allowsCellularAccess = true
        sessionConfig.timeoutIntervalForRequest = 15
        sessionConfig.timeoutIntervalForResource = 30
        sessionConfig.httpMaximumConnectionsPerHost = 1
        
        let session = URLSession(configuration: sessionConfig)
        
        // Use URLSession to get data from an NSURL
        let loadDataTask = session.dataTask(with: url) { data, response, error in
            
            guard error == nil else {
                completion(nil, error!)
                if kDebugLog { print("API ERROR: \(error!)") }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
                completion(nil, nil)
                if kDebugLog { print("API: HTTP status code has unexpected value") }
                return
            }
            
            guard let data = data else {
                completion(nil, nil)
                if kDebugLog { print("API: No data received") }
                return
            }
            
            // Success, return data
            completion(data, nil)
        }
        
        loadDataTask.resume()
    }
}

