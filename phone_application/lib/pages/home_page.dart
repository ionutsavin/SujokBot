import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:phone_application/pages/chat_page.dart';
import 'package:phone_application/pages/conversations_sidebar.dart';
import 'package:phone_application/pages/palm_hand_diagram_page.dart';
import 'package:phone_application/pages/back_hand_diagram_page.dart';
import 'package:phone_application/services/chat_service.dart';
import 'package:phone_application/pages/login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String? _activeConversationId;
  List<String>? _passedPalmZones;
  List<String>? _passedBackZones;
  String? _username;

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _checkForLastConversation();

    HomePageNavigator.instance.setNavigateToPalmHandPageCallback((List<String>? palmZones) {
      setState(() {
        _passedPalmZones = palmZones;
        _passedBackZones = null;
        _selectedIndex = 1;
      });
    });

    HomePageNavigator.instance.setNavigateToBackHandPageCallback((List<String>? backZones) {
      setState(() {
        _passedBackZones = backZones;
        _passedPalmZones = null;
        _selectedIndex = 2;
      });
    });
  }
  void _loadUsername() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      final email = user.email!;
      setState(() {
        _username = email.split('@')[0];
      });
    }
  }

  Future<void> _checkForLastConversation() async {
    final lastId = await ChatService().getLastOpenedConversationId();
    if (lastId != null && mounted) {
      setState(() {
        _activeConversationId = lastId;
      });
    }
  }

  Future<void> _createNewConversation() async {
    final controller = TextEditingController();
    String? errorText;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const SelectableText('New Chat'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Enter title',
                  errorText: errorText,
                ),
                onChanged: (value) {
                  if (errorText != null && value.trim().isNotEmpty) {
                    setDialogState(() {
                      errorText = null;
                    });
                  }
                },
                onSubmitted: (value) {
                  final title = value.trim();
                  if (title.isEmpty) {
                    setDialogState(() {
                      errorText = 'Chat title cannot be empty!';
                    });
                  } else {
                    Navigator.pop(context, {'action': 'create', 'title': title});
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, {'action': 'cancel'}),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.red),
                ),
            ),
            ElevatedButton(
              onPressed: () {
                final title = controller.text.trim();
                if (title.isEmpty) {
                  setDialogState(() {
                    errorText = 'Chat title cannot be empty!';
                  });
                } else {
                  Navigator.pop(context, {'action': 'create', 'title': title});
                }
              },
              child: const Text(
                'Create',
                style: TextStyle(color: Colors.green),
                ),
            ),
          ],
        ),
      ),
    );

    if (result != null && result['action'] == 'create') {
      final title = result['title'] as String;
      
      final newId = await ChatService().createConversation(title);
      await ChatService().saveLastOpenedConversationId(newId!);
      setState(() {
        _activeConversationId = newId;
        _selectedIndex = 0;
      });
    }
  }

  void _navigateToNewPage() async {
    await ChatService().clearLastConversationId();
    setState(() {
      _activeConversationId = null;
      _selectedIndex = 0;
    });
  }

  void _handleConversationDeleted(String deletedConversationId) async {
    await ChatService().clearLastConversationId();
    
    setState(() {
      _activeConversationId = null;
      _selectedIndex = 0;
    });
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Sujok Assistant';
      case 1:
        return 'Palm Diagram';
      case 2:
        return 'Back Hand Diagram';
      default:
        return 'Sujok Assistant';
    }
  }

  Future<void> _logout() async {
    await ChatService().clearLastConversationId();
    ChatService().clearMessages();

    if(!kIsWeb){
      final GoogleSignIn googleSignIn = GoogleSignIn();
      if(await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }
    }
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Logged out successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const SelectableText('Logout'),
          content: const SelectableText('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.black)
                ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMainView() {
    switch (_selectedIndex) {
      case 0:
        if (_activeConversationId != null) {
          return ChatPage(
            conversationId: _activeConversationId!,
            key: ValueKey(_activeConversationId),
          );
        } else {
          return Center(
            child: ElevatedButton(
              onPressed: _createNewConversation,
              child: const Text(
                'Start a new chat',
                style: TextStyle(
                  color: Colors.blue,
                ),
              ),
            ),
          );
        }
      case 1:
        return PalmHandDiagramPage(palmZones: _passedPalmZones);
      case 2:
        return BackHandDiagramPage(backZones: _passedBackZones);
      default:
        return const SizedBox();
    }
  }

  void _selectConversation(String conversationId) async {
    await ChatService().saveLastOpenedConversationId(conversationId);
    setState(() {
      _activeConversationId = conversationId;
      _selectedIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ConversationsSidebar(
          selectedConversationId: _activeConversationId,
          onSelectConversation: _selectConversation,
          onCreateNew: _createNewConversation,
          onNavigateToNewPage: _navigateToNewPage,
          onConversationDeleted: _handleConversationDeleted,
        ),
      ),
      appBar: AppBar(
        title: SelectableText(_getAppBarTitle()),
        centerTitle: true,
        actions: [
          if (_username != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Center(
                child: SelectableText(
                  _username!,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') _showLogoutDialog();
            },
            itemBuilder: (_) => [
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildMainView(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() {
          _selectedIndex = index;
          _passedPalmZones = null;
          _passedBackZones = null;
        }),
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(
            icon: ImageIcon(
              AssetImage('assets/hand_removebg.png'),
              size: 30,
              color: Colors.black,
            ),
            label: 'Palm',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(
              AssetImage('assets/back_hand_removebg.png'),
              size: 30,
              color: Colors.black,
            ),
            label: 'Back Hand',
          ),
        ],
      ),
    );
  }
}

class HomePageNavigator {
  static final HomePageNavigator _instance = HomePageNavigator._internal();
  static HomePageNavigator get instance => _instance;
  HomePageNavigator._internal();

  Function(List<String>?)? _navigateToPalmHandPageCallback;
  Function(List<String>?)? _navigateToBackHandPageCallback;

  void setNavigateToPalmHandPageCallback(Function(List<String>?) callback) {
    _navigateToPalmHandPageCallback = callback;
  }

  void setNavigateToBackHandPageCallback(Function(List<String>?) callback) {
    _navigateToBackHandPageCallback = callback;
  }

  void navigateToPalmHandPage({List<String>? palmZones}) {
    _navigateToPalmHandPageCallback?.call(palmZones);
  }

  void navigateToBackHandPage({List<String>? backZones}) {
    _navigateToBackHandPageCallback?.call(backZones);
  }
}