import Foundation

struct ChatStorage {
    
    // MARK: - Notification
    
    static let didChangeNotification =
    Notification.Name("ChatStorageDidChange")
    
    // MARK: - Last Message
    
    static func lastMessage(
        for chatName: String
    ) -> String? {
        
        UserDefaults.standard.string(
            forKey: "chat_last_message_" + chatName
        )
    }
    
    // MARK: - Unread Count
    
    static func unreadCount(
        for chatName: String
    ) -> Int {
        
        UserDefaults.standard.integer(
            forKey: "chat_unread_" + chatName
        )
    }
    
    // MARK: - Has Unread Record
    
    static func hasUnreadRecord(
        for chatName: String
    ) -> Bool {
        
        UserDefaults.standard.object(
            forKey: "chat_unread_" + chatName
        ) != nil
    }
    
    // MARK: - Save Last Message
    
    static func saveLastMessage(
        _ message: String,
        for chatName: String
    ) {
        
        UserDefaults.standard.set(
            message,
            forKey: "chat_last_message_" + chatName
        )
        
        notifyChange()
    }
    
    // MARK: - Add Unread
    
    static func addUnread(
        for chatName: String
    ) {
        
        let key =
        "chat_unread_" + chatName
        
        let count =
        UserDefaults.standard.integer(
            forKey: key
        )
        
        UserDefaults.standard.set(
            count + 1,
            forKey: key
        )
        
        notifyChange()
    }
    
    // MARK: - Mark As Read
    
    static func markAsRead(
        for chatName: String
    ) {
        
        UserDefaults.standard.set(
            0,
            forKey: "chat_unread_" + chatName
        )
        
        notifyChange()
    }
    
    // MARK: - Notify
    
    private static func notifyChange() {
        
        NotificationCenter.default.post(
            name: didChangeNotification,
            object: nil
        )
    }
}
