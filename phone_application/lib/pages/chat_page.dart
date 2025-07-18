import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phone_application/components/button.dart';
import 'package:phone_application/components/textfield.dart';
import 'package:phone_application/services/chat_service.dart';
import 'package:phone_application/pages/home_page.dart';

class ChatPage extends StatefulWidget {
  final String conversationId;

  const ChatPage({super.key, required this.conversationId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ChatService _chatService = ChatService();
  final ScrollController _scrollController = ScrollController();
  bool _isThinking = false;
  static final Map<String, double> _scrollPositions = {};
  static final Map<String, String> _conversationTexts = {};
  
  @override
  void initState() {
    super.initState();
    _loadChatMessages();
    _scrollController.addListener(_saveScrollPosition);
    _controller.text = _conversationTexts[widget.conversationId] ?? '';
  }

  @override
  void dispose() {
    _saveScrollPosition();
    _conversationTexts[widget.conversationId] = _controller.text;
    _scrollController.removeListener(_saveScrollPosition);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ChatPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conversationId != widget.conversationId) {
      _conversationTexts[oldWidget.conversationId] = _controller.text;
      _controller.text = _conversationTexts[widget.conversationId] ?? '';
      _loadChatMessages();
    }
  }

  void _saveScrollPosition() {
    if (_scrollController.hasClients) {
      _scrollPositions[widget.conversationId] = _scrollController.offset;
    }
  }

  void _restoreScrollPosition() {
    final savedPosition = _scrollPositions[widget.conversationId];
    if (savedPosition != null && _scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients && mounted) {
          _scrollController.animateTo(
            savedPosition,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    } else {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && mounted) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _loadChatMessages() async {
    await _chatService.loadConversation(conversationId: widget.conversationId);
    if (mounted) {
      setState(() {});
      _restoreScrollPosition();
    }
  }

  Future<void> sendMessage() async {
    String userInput = _controller.text.trim();
    if (userInput.isEmpty) return;

    _controller.clear();
    _conversationTexts[widget.conversationId] = '';
    
    await _chatService.addMessage('user', userInput);

    if (!mounted) return;
    setState(() {
      _isThinking = true;
    });
    await _chatService.askQuestion(userInput);

    if (!mounted) return;
    setState(() {
      _isThinking = false;
    });

    _scrollToBottom();
  }

  Future<bool> _checkAssetExists(String assetPath) async {
    try {
      await rootBundle.load(assetPath);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<String>> _getValidSeeds(List<String> seeds) async {
    List<String> validSeeds = [];
    for (String seed in seeds) {
      String assetPath = 'assets/seeds/$seed.png';
      bool exists = await _checkAssetExists(assetPath);
      if (exists) {
        validSeeds.add(seed);
      }
    }
    return validSeeds;
  }

  void _showSeedsModal(List<String> seeds) async {
    List<String> validSeeds = await _getValidSeeds(seeds);

    if (validSeeds.isEmpty || !mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 500,
              maxHeight: 600,
            ),
            child: Dialog(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SelectableText(
                      'Seeds',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: validSeeds.length == 1
                          ? _buildSeedItem(validSeeds[0], single: true)
                          : GridView.builder(
                              shrinkWrap: true,
                              itemCount: validSeeds.length,
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: validSeeds.length >= 4 ? 2 : validSeeds.length,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 1,
                              ),
                              itemBuilder: (context, index) {
                                return _buildSeedItem(validSeeds[index]);
                              },
                            ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSeedItem(String seed, {bool single = false}) {
    final seedName = seed.replaceAll('_', ' ');
    final image = ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(
        'assets/seeds/$seed.png',
        fit: BoxFit.cover,
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        single
            ? SizedBox(
                width: 150,
                height: 150,
                child: image,
              )
            : Expanded(child: image),
        const SizedBox(height: 8),
        SelectableText(
          seedName,
          style: TextStyle(fontSize: single ? 16 : 12, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget buildMessage(Map<String, dynamic> message) {
    String role = message['role'];
    String text = message['text'];
    List<String>? palmZones = message['left_palm_zones'];
    List<String>? backZones = message['back_left_hand_zones'];
    List<String>? seeds = message['seeds'];
    bool isUser = role == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? Colors.blueAccent : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              text,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black,
              ),
            ),
            if (!isUser && palmZones != null && palmZones.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: InkWell(
                  onTap: () {
                    HomePageNavigator.instance.navigateToPalmHandPage(palmZones: palmZones);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.teal,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.touch_app, color: Colors.white, size: 16),
                        SizedBox(width: 5),
                        Text(
                          'View Palm Diagram',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (!isUser && backZones != null && backZones.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: InkWell(
                  onTap: () {
                    HomePageNavigator.instance.navigateToBackHandPage(backZones: backZones);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.touch_app, color: Colors.white, size: 16),
                        SizedBox(width: 5),
                        Text(
                          'View Back Hand Diagram',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (!isUser && seeds != null && seeds.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: FutureBuilder<List<String>>(
                  future: _getValidSeeds(seeds),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox.shrink();
                    }
                    if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                      return InkWell(
                        onTap: () => _showSeedsModal(seeds),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.eco, color: Colors.white, size: 16),
                              SizedBox(width: 5),
                              Text(
                                'View Seeds',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  reverse: false,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: _chatService.messages.length,
                  itemBuilder: (context, index) {
                    return buildMessage(_chatService.messages[index]);
                  },
                ),
              ),
              if (_isThinking)
                const Padding(
                  padding: EdgeInsets.all(10),
                  child: CircularProgressIndicator(),
                ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    MyTextField(
                      controller: _controller,
                      hintText: 'Type your question...',
                      obscureText: false,
                      isMultiline: true,
                      onSubmit: sendMessage,
                    ),
                    const SizedBox(height: 10),
                    MyButton(
                      onTap: sendMessage,
                      text: 'Send',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}