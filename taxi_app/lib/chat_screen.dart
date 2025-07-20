import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/rasa_chat_service.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> 
    with TickerProviderStateMixin {
  final RasaChatService rasaService = RasaChatService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  
  List<Map<String, dynamic>> messages = [];
  bool _isTyping = false;
  late AnimationController _typingController;
  late Animation<double> _typingAnimation;

  @override
  void initState() {
    super.initState();
    _typingController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    _typingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _typingController,
      curve: Curves.easeInOut,
    ));
    
    // Add welcome message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        messages.add({
          "role": "bot",
          "text": "Hello! I'm your taxi booking assistant. How can I help you today?",
          "buttons": [
            {"title": "Book a Ride", "payload": "book_ride"},
            {"title": "Track Order", "payload": "track_order"},
            {"title": "Help", "payload": "help"}
          ]
        });
      });
    });
  }

  @override
  void dispose() {
    _typingController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    HapticFeedback.lightImpact();
    
    setState(() {
      messages.add({
        "role": "user", 
        "text": message.trim(), 
        "buttons": [],
        "timestamp": DateTime.now()
      });
      _isTyping = true;
    });

    _controller.clear();
    _scrollToBottom();
    _typingController.repeat();

    try {
      // Simulate network delay for better UX
      await Future.delayed(Duration(milliseconds: 800));
      
      List<Map<String, dynamic>> botResponses =
          await rasaService.sendMessage(message);
      
      setState(() {
        _isTyping = false;
      });
      _typingController.stop();
      
      for (var response in botResponses) {
        await Future.delayed(Duration(milliseconds: 300));
        setState(() {
          messages.add({
            "role": "bot",
            "text": response['text'],
            "buttons": response['buttons'] ?? [],
            "timestamp": DateTime.now()
          });
        });
        _scrollToBottom();
      }
    } catch (e) {
      setState(() {
        _isTyping = false;
        messages.add({
          "role": "bot",
          "text": "Sorry, I'm having trouble connecting. Please try again.",
          "buttons": [],
          "timestamp": DateTime.now()
        });
      });
      _typingController.stop();
      _scrollToBottom();
    }
  }

  void handleButtonClick(String payload) {
    HapticFeedback.selectionClick();
    sendMessage(payload);
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildTypingIndicator() {
    return AnimatedBuilder(
      animation: _typingAnimation,
      builder: (context, child) {
        return Container(
          margin: EdgeInsets.only(left: 16, right: 80, bottom: 8),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: Offset(0, 2),
              )
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDot(0),
              SizedBox(width: 4),
              _buildDot(1),
              SizedBox(width: 4),
              _buildDot(2),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _typingAnimation,
      builder: (context, child) {
        final delay = index * 0.2;
        final animValue = (_typingAnimation.value + delay) % 1.0;
        final opacity = animValue < 0.5 ? animValue * 2 : (1.0 - animValue) * 2;
        
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey[400]!.withOpacity(opacity.clamp(0.3, 1.0)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF4CAF50)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.local_taxi, color: Colors.white, size: 22),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "TaxiBot",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  "Online",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.black54),
            onPressed: () {
              // Add menu functionality
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(vertical: 16),
              itemCount: messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isTyping && index == messages.length) {
                  return _buildTypingIndicator();
                }
                
                final message = messages[index];
                bool isUser = message['role'] == "user";

                return AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  margin: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: isUser 
                        ? MainAxisAlignment.end 
                        : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (!isUser) ...[
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF6C63FF), Color(0xFF4CAF50)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.smart_toy, color: Colors.white, size: 18),
                        ),
                        SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Column(
                          crossAxisAlignment: isUser
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Container(
                              constraints: BoxConstraints(maxWidth: 280),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: isUser
                                    ? LinearGradient(
                                        colors: [Color(0xFF6C63FF), Color(0xFF9C88FF)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                color: isUser ? null : Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                  bottomLeft: isUser
                                      ? Radius.circular(20)
                                      : Radius.circular(6),
                                  bottomRight: isUser
                                      ? Radius.circular(6)
                                      : Radius.circular(20),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isUser 
                                        ? Color(0xFF6C63FF).withOpacity(0.3)
                                        : Colors.black.withOpacity(0.08),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  )
                                ],
                              ),
                              child: Text(
                                message['text'] ?? "",
                                style: TextStyle(
                                  fontSize: 15,
                                  color: isUser ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.w400,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            if (!isUser && (message['buttons'] as List).isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: (message['buttons'] as List)
                                      .map<Widget>((button) {
                                    return Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () => handleButtonClick(
                                            button['payload'] ?? button['title']),
                                        borderRadius: BorderRadius.circular(20),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: Color(0xFF6C63FF).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: Color(0xFF6C63FF).withOpacity(0.3),
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            button['title'],
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF6C63FF),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (isUser) ...[
                        SizedBox(width: 8),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Color(0xFF6C63FF),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.person, color: Colors.white, size: 18),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: Offset(0, -2),
                )
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        style: TextStyle(fontSize: 15),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: "Type your message...",
                          hintStyle: TextStyle(
                            fontSize: 15, 
                            color: Colors.grey[500]
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20, 
                            vertical: 12
                          ),
                        ),
                        onSubmitted: (value) {
                          sendMessage(value);
                          _focusNode.requestFocus();
                        },
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF9C88FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF6C63FF).withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        )
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => sendMessage(_controller.text),
                        borderRadius: BorderRadius.circular(24),
                        child: Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}