import Foundation

struct AIService {
    
    // MARK: - AI 人设提示词
    
    private let systemPrompt = """
    你是一个名叫“廖苡诺”的女生，是德阳天立九年级三班的学生。
    
    你正在通过微信和“罗以恒”聊天。
    
    你是女生，说话有温度，语气甜甜的、自然、亲切。
    你们是在微信上进行真实、日常的聊天。
    
    回复规则：
    - 像真实的人聊天，不要像 AI 助手、客服或百科全书。
    - 回复要符合真实微信聊天的长度，切记不要过长。
    - 普通聊天通常用 1～2 句话即可。
    - 一句话能自然表达时，就不要写成好几句话。
    - 除非事情确实需要解释，否则不要超过 3 句话。
    - 不要为了显得有内容而主动扩写。
    - 根据上下文自然回应，不要机械重复罗以恒的话。
    - 可以自然使用“哈哈”“嗯嗯”“好呀”“诶”等口语表达，但不要滥用。
    - 语气温柔、甜一点、有温度，但不要过度做作。
    - 如果只是普通闲聊，就自然聊天。
    - 如果罗以恒问问题，也要保持微信聊天的语气，不要突然变成正式说明。
    - 不要主动说自己是 AI、语言模型或人工智能。
    - 不要使用“作为一个 AI 助手”之类的表达。
    - 不要在每次回复最后说“还有什么可以帮助你的吗”。
    """
    
    // MARK: - DeepSeek API Key
    
    private let apiKey = "sk-bd11d3f8b9214486bf3c85b4656cc534"
    
    // MARK: - Send Message
    
    func sendMessage(
        _ messages: [Message],
        completion: @escaping (String) -> Void
    ) {
        
        guard let url = URL(
            string: "https://api.deepseek.com/chat/completions"
        ) else {
            return
        }
        
        var request =
        URLRequest(url: url)
        
        request.httpMethod = "POST"
        
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )
        
        request.setValue(
            "Bearer \(apiKey)",
            forHTTPHeaderField: "Authorization"
        )
        
        // MARK: DeepSeek Messages
        
        var deepSeekMessages: [
            DeepSeekMessage
        ] = [
            DeepSeekMessage(
                role: "system",
                content: systemPrompt
            )
        ]
        
        for message in messages {
            
            deepSeekMessages.append(
                DeepSeekMessage(
                    role: message.isMe
                    ? "user"
                    : "assistant",
                    content: message.text
                )
            )
        }
        
        // MARK: Request Body
        
        let body = DeepSeekRequest(
            model: "deepseek-flash",
            messages: deepSeekMessages,
            stream: false
        )
        
        do {
            
            request.httpBody =
            try JSONEncoder().encode(body)
            
        } catch {
            
            print(
                "请求数据错误：\(error)"
            )
            
            return
        }
        
        // MARK: Network Request
        
        URLSession.shared.dataTask(
            with: request
        ) { data, response, error in
            
            if let error = error {
                
                print(
                    "网络错误：\(error)"
                )
                
                DispatchQueue.main.async {
                    completion(
                        "网络请求失败，请检查网络连接"
                    )
                }
                
                return
            }
            
            guard let data = data else {
                
                print("没有收到数据")
                
                DispatchQueue.main.async {
                    completion(
                        "AI 没有收到服务器返回"
                    )
                }
                
                return
            }
            
            // MARK: HTTP Status
            
            if let httpResponse =
                response as? HTTPURLResponse {
                
                print(
                    "DeepSeek HTTP 状态码：\(httpResponse.statusCode)"
                )
                
                if httpResponse.statusCode != 200 {
                    
                    if let text =
                        String(
                            data: data,
                            encoding: .utf8
                        ) {
                        
                        print(
                            "DeepSeek 错误返回：\(text)"
                        )
                    }
                    
                    DispatchQueue.main.async {
                        completion(
                            "AI 请求失败，请检查 API Key 和网络"
                        )
                    }
                    
                    return
                }
            }
            
            // MARK: Decode Response
            
            do {
                
                let result =
                try JSONDecoder().decode(
                    DeepSeekResponse.self,
                    from: data
                )
                
                let reply =
                result.choices.first?.message.content
                ?? "AI 没有返回内容"
                
                DispatchQueue.main.async {
                    completion(reply)
                }
                
            } catch {
                
                print(
                    "解析错误：\(error)"
                )
                
                if let text =
                    String(
                        data: data,
                        encoding: .utf8
                    ) {
                    
                    print(
                        "DeepSeek 返回：\(text)"
                    )
                }
                
                DispatchQueue.main.async {
                    completion(
                        "AI 返回的数据无法解析"
                    )
                }
            }
            
        }.resume()
    }
}

// MARK: - Request

private struct DeepSeekRequest: Codable {
    
    let model: String
    let messages: [DeepSeekMessage]
    let stream: Bool
}

// MARK: - DeepSeek Message

private struct DeepSeekMessage: Codable {
    
    let role: String
    let content: String
}

// MARK: - Response

private struct DeepSeekResponse: Codable {
    
    let choices: [DeepSeekChoice]
}

// MARK: - Choice

private struct DeepSeekChoice: Codable {
    
    let message: DeepSeekMessage
}
