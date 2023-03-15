//
//  TableViewController.swift
//  LocalNotification
//
//  Created by Nikita Chekan on 14.03.2023.
//  Copyright © 2018 swiftbook.ru. All rights reserved.
//

import UserNotifications

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        guard let bestAttemptContent = bestAttemptContent,
              let apsData = bestAttemptContent.userInfo["aps"] as? [String: Any],
              let attachmentURLAsString = apsData["attachment-url"] as? String,
              let attachmentUrl = URL(string: attachmentURLAsString) else { return }
        
        downloadImageFrom(url: attachmentUrl) { (attachment) in
            if attachment != nil {
                bestAttemptContent.attachments = [attachment!]
                contentHandler(bestAttemptContent)
            }
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

}

//MARK: - Helper
extension NotificationService {
    private func downloadImageFrom(url: URL, with completionHandler: @escaping(UNNotificationAttachment?) -> Void) {
        
        let task = URLSession.shared.downloadTask(with: url) { (downloadUrl, response, error) in
            guard let downloadUrl = downloadUrl else {
                completionHandler(nil)
                return
            }
            
            var urlPath = URL(fileURLWithPath: NSTemporaryDirectory())
            
            let uniqueUrlEnding = ProcessInfo.processInfo.globallyUniqueString + ".png"
            urlPath = urlPath.appendingPathComponent(uniqueUrlEnding)
            
            try? FileManager.default.moveItem(at: downloadUrl, to: urlPath)
            
            do {
                let attachment  = try UNNotificationAttachment(identifier: "favicon", url: urlPath)
                completionHandler(attachment)
            } catch {
                completionHandler(nil)
            }
        }
        task.resume()
    }
}
