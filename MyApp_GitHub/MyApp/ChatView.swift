import SwiftUI

// MARK: - Message Model

struct Message: Identifiable, Codable {
    
    let id: UUID
    let text: String
    let isMe: Bool
    
    init(
        id: UUID = UUID(),
        text: String,
        isMe: Bool
    ) {
        self.id = id
        self.text = text
        self.isMe = isMe
    }
}

// MARK: - Chat View

struct ChatView: View {
    
    let chat: ChatItem
    
    private let aiService = AIService()
    
    @State private var messageText = ""
    
    @State private var messages: [Message]
    
    @State private var isChatActive = false
    
    init(chat: ChatItem) {
        
        self.chat = chat
        
        let key =
        "chat_messages_" + chat.name
        
        if let data =
            UserDefaults.standard.data(
                forKey: key
            ),
           let savedMessages =
            try? JSONDecoder().decode(
                [Message].self,
                from: data
            ) {
            
            _messages = State(
                initialValue: savedMessages
            )
            
        } else {
            
            _messages = State(
                initialValue: [
                    Message(
                        text: "你h",
                        isMe: false
                    ),
                    Message(
                        text: "你好！",
                        isMe: true
                    )
                ]
            )
        }
    }
    
    var body: some View {
        
        VStack(spacing: 0) {
            
            // MARK: 聊天消息区域
            
            ScrollViewReader { proxy in
                
                ScrollView {
                    
                    VStack(spacing: 12) {
                        
                        ForEach(messages) { message in
                            
                            HStack(
                                alignment: .top,
                                spacing: 10
                            ) {
                                
                                // 对方消息
                                if !message.isMe {
                                    
                                    ChatAvatar(
                                        systemName: chat.avatar
                                    )
                                    .frame(
                                        width: 50,
                                        height: 50
                                    )
                                    
                                    Text(message.text)
                                        .frame(
                                            alignment: .center
                                        )
                                        .font(
                                            .system(size: 16)
                                        )
                                        .foregroundStyle(.primary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 10)
                                        .background(
                                            Color.black.tertiary
                                        )
                                        .clipShape(
                                            RoundedRectangle(
                                                cornerRadius: 5
                                            )
                                        )
                                    
                                    Spacer()
                                    
                                } else {
                                    
                                    // 自己的消息
                                    Spacer()
                                    
                                    Text(message.text)
                                        .font(
                                            .system(size: 16)
                                        )
                                        .foregroundStyle(.primary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 9)
                                        .background(
                                            Color.green.opacity(0.2)
                                        )
                                        .clipShape(
                                            RoundedRectangle(
                                                cornerRadius: 5
                                            )
                                        )
                                }
                            }
                            .id(message.id)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 15)
                }
                .background(
                    Color(.systemGroupedBackground)
                )
                .onChange(of: messages.count) {
                    
                    if let lastMessage =
                        messages.last {
                        
                        withAnimation {
                            proxy.scrollTo(
                                lastMessage.id,
                                anchor: .bottom
                            )
                        }
                    }
                }
            }
            
            // MARK: 输入区域
            
            HStack(spacing: 10) {
                
                Image(systemName: "mic")
                    .font(.system(size: 22))
                    .foregroundStyle(.primary)
                
                TextField(
                    "输入消息",
                    text: $messageText
                )
                .padding(.horizontal, 10)
                .frame(height: 38)
                .background(Color.black)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 5
                    )
                )
                .onSubmit {
                    sendMessage()
                }
                
                Image(systemName: "face.smiling")
                    .font(.system(size: 22))
                    .foregroundStyle(.primary)
                
                if !messageText.trimmingCharacters(
                    in: .whitespacesAndNewlines
                ).isEmpty {
                    
                    Button {
                        sendMessage()
                    } label: {
                        
                        Text("发送")
                            .font(.system(size: 15))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .frame(height: 32)
                            .background(Color.green)
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: 5
                                )
                            )
                    }
                    
                } else {
                    
                    Image(systemName: "plus.circle")
                        .font(.system(size: 22))
                        .foregroundStyle(.primary)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                Color(.systemGray6)
            )
        }
        .background(
            Color(.systemGroupedBackground)
        )
        .navigationTitle(chat.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            
            isChatActive = true
            
            // 进入聊天后清除未读
            ChatStorage.markAsRead(
                for: chat.name
            )
        }
        .onDisappear {
            
            isChatActive = false
        }
    }
    
    // MARK: - Send Message
    
    private func sendMessage() {
        
        let text =
        messageText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        
        guard !text.isEmpty else {
            return
        }
        
        // MARK: 显示自己的消息
        
        messages.append(
            Message(
                text: text,
                isMe: true
            )
        )
        
        saveMessages()
        
        // 更新聊天列表最后一条消息
        ChatStorage.saveLastMessage(
            text,
            for: chat.name
        )
        
        // 清空输入框
        messageText = ""
        
        // MARK: 请求 AI
        
        aiService.sendMessage(messages) { reply in
            
            messages.append(
                Message(
                    text: reply,
                    isMe: false
                )
            )
            
            saveMessages()
            
            // 更新聊天列表最后一条消息
            ChatStorage.saveLastMessage(
                reply,
                for: chat.name
            )
            
            // 如果聊天页面已经离开
            // 就增加未读
            if !isChatActive {
                
                ChatStorage.addUnread(
                    for: chat.name
                )
            }
        }
    }
    
    // MARK: - Save Messages
    
    private func saveMessages() {
        
        let key =
        "chat_messages_" + chat.name
        
        if let data =
            try? JSONEncoder().encode(
                messages
            ) {
            
            UserDefaults.standard.set(
                data,
                forKey: key
            )
        }
    }
}

// MARK: - Preview

#Preview {
    ChatView(
        chat: ChatItem(
            avatar: "person",
            name: "妈妈",
            lastMessage: "晚上回家吃饭吗",
            time: "09:15",
            unread: 2
        )
    )
}
