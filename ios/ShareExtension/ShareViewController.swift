//
//  ShareViewController.swift
//  ShareExtension
//
//  Recall iOS Share Extension for receiving URLs from other apps
//

import UIKit
import Social
import MobileCoreServices
import UniformTypeIdentifiers

class ShareViewController: SLComposeServiceViewController {
    
    override func isContentValid() -> Bool {
        // Validate that we have a valid URL
        return true
    }
    
    override func didSelectPost() {
        // Get the shared URL
        if let item = extensionContext?.inputItems.first as? NSExtensionItem,
           let attachments = item.attachments {
            
            for attachment in attachments {
                // Check for URL type
                if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    attachment.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] (url, error) in
                        if let shareURL = url as? URL {
                            self?.handleSharedURL(shareURL.absoluteString)
                        } else if let error = error {
                            print("Error loading URL: \(error.localizedDescription)")
                            self?.completeRequest(withError: error)
                        }
                    }
                    return
                }
                // Also check for plain text (some apps share URLs as text)
                else if attachment.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    attachment.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { [weak self] (text, error) in
                        if let urlString = text as? String, self?.isValidURL(urlString) ?? false {
                            self?.handleSharedURL(urlString)
                        } else if let error = error {
                            print("Error loading text: \(error.localizedDescription)")
                            self?.completeRequest(withError: error)
                        }
                    }
                    return
                }
            }
        }
        
        // If we get here, no valid URL was found
        let error = NSError(domain: "com.recall.mobile.ShareExtension", code: -1, 
                           userInfo: [NSLocalizedDescriptionKey: "No valid URL found"])
        completeRequest(withError: error)
    }
    
    override func configurationItems() -> [Any]! {
        // Return an empty array to hide the default configuration UI
        return []
    }
    
    // MARK: - Private Methods
    
    private func handleSharedURL(_ urlString: String) {
        // Store the URL in a shared container that the main app can access
        if let userDefaults = UserDefaults(suiteName: "group.com.recall.mobile") {
            userDefaults.set(urlString, forKey: "sharedURL")
            userDefaults.set(Date(), forKey: "sharedURLTimestamp")
            userDefaults.synchronize()
        }
        
        // Open the main app with the shared URL
        var urlComponents = URLComponents()
        urlComponents.scheme = "recall"
        urlComponents.host = "share"
        urlComponents.queryItems = [URLQueryItem(name: "url", value: urlString)]
        
        if let url = urlComponents.url {
            openURL(url)
        }
        
        // Complete the share request
        completeRequest(withError: nil)
    }
    
    private func completeRequest(withError error: Error?) {
        if let error = error {
            extensionContext?.cancelRequest(withError: error)
        } else {
            extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
    }
    
    private func isValidURL(_ string: String) -> Bool {
        // Basic URL validation
        if let url = URL(string: string), 
           let scheme = url.scheme?.lowercased(),
           (scheme == "http" || scheme == "https") {
            return true
        }
        return false
    }
    
    @objc private func openURL(_ url: URL) {
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                application.perform(#selector(openURL(_:)), with: url)
                return
            }
            responder = responder?.next
        }
    }
}
