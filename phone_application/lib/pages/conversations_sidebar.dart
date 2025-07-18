import 'package:flutter/material.dart';
import 'package:phone_application/services/chat_service.dart';

class ConversationsSidebar extends StatefulWidget {
  final Function(String) onSelectConversation;
  final VoidCallback onCreateNew;
  final VoidCallback onNavigateToNewPage;
  final String? selectedConversationId;
  final Function(String)? onConversationDeleted;

  const ConversationsSidebar({
    required this.onSelectConversation,
    required this.onCreateNew,
    required this.onNavigateToNewPage,
    this.selectedConversationId,
    this.onConversationDeleted,
    super.key,
  });

  @override
  State<ConversationsSidebar> createState() => _ConversationsSidebarState();
}

class _ConversationsSidebarState extends State<ConversationsSidebar> {
  List<Map<String, dynamic>> _conversations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadConversations();
    });
  }

  Future<void> _loadConversations() async {
    final chats = await ChatService().getConversations();
    if (mounted) {
      setState(() {
        _conversations = chats;
        _loading = false;
      });
    }
  }

  Future<void> _deleteConversation(String conversationId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const SelectableText('Delete Chat'),
        content: const SelectableText('Are you sure you want to delete this chat?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: Colors.black))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red)))
        ],
      ),
    );

    if (confirmed == true) {
      await ChatService().deleteConversation(conversationId: conversationId);
      
      if (widget.selectedConversationId == conversationId) {
        widget.onConversationDeleted?.call(conversationId);
      }
      
      await _loadConversations();
    }
  }

  Future<void> _editConversationTitle(String conversationId, String oldTitle) async {
    final controller = TextEditingController(text: oldTitle);

    final updated = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const SelectableText('Edit Title'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Chat Title'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (updated != null && updated.isNotEmpty && updated != oldTitle) {
      await ChatService().renameConversation(conversationId: conversationId, newTitle: updated);
      await _loadConversations();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: SelectableText('Chats', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadConversations,
                      child: ListView.builder(
                        itemCount: _conversations.length,
                        itemBuilder: (_, index) {
                          final convo = _conversations[index];
                          final title = convo['title'] ?? 'Untitled';
                          final isSelected = convo['id'] == widget.selectedConversationId;

                          return Container(
                            color: isSelected ? Colors.blue.shade100 : null,
                            child: ListTile(
                              title: Text(
                                title,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? Colors.blue : null,
                                ),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                widget.onSelectConversation(convo['id']);
                              },
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    tooltip: 'Edit title',
                                    onPressed: () => _editConversationTitle(convo['id'], title),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    tooltip: 'Delete chat',
                                    onPressed: () => _deleteConversation(convo['id']),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onCreateNew();
                    },
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        widget.onNavigateToNewPage();
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                        child: Text(
                          'New Chat',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}