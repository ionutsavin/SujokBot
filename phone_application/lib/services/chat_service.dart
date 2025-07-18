import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:phone_application/models/palm_hand_zone.dart';
import 'package:phone_application/models/back_hand_zone.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:phone_application/config/app_config.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<Map<String, dynamic>> messages = [];
  String? _activeConversationId;
  String? get activeConversationId => _activeConversationId;

  Future<String?> createConversation(String title) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      final docRef = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('conversations')
          .add({
        'title': title,
        'created_at': FieldValue.serverTimestamp(),
      });

      _activeConversationId = docRef.id;
      messages.clear();
      return docRef.id;
    } catch (e) {
      debugPrint("Failed to create conversation: $e");
      return null;
    }
  }

  Future<void> loadConversation({required String conversationId}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .orderBy('timestamp')
          .get();

      messages.clear();
      _activeConversationId = conversationId;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        messages.add({
          'role': data['role'],
          'text': data['text'],
          'left_palm_zones': (data['left_palm_zones'] as List?)?.cast<String>(),
          'back_left_hand_zones': (data['back_left_hand_zones'] as List?)?.cast<String>(),
          'seeds': (data['seeds'] as List?)?.cast<String>(),
        });
      }
    } catch (e) {
      debugPrint("Failed to load conversation: $e");
    }
  }

  Future<void> deleteConversation({required String conversationId}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final messagesRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('conversations')
          .doc(conversationId)
          .collection('messages');

      final snapshot = await messagesRef.get();
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('conversations')
          .doc(conversationId)
          .delete();

      if (_activeConversationId == conversationId) {
        _activeConversationId = null;
        messages.clear();
      }
    } catch (e) {
      debugPrint("Failed to delete conversation: $e");
    }
  }

  Future<void> renameConversation({required String conversationId, required String newTitle}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('conversations')
        .doc(conversationId);

    await doc.update({'title': newTitle});
  }

  Future<List<Map<String, dynamic>>> getConversations() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('conversations')
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] ?? 'Untitled',
          'created_at': data['created_at'],
        };
      }).toList();
    } catch (e) {
      debugPrint("Failed to get conversations: $e");
      return [];
    }
  }

  Future<void> _saveMessage(Map<String, dynamic> message) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _activeConversationId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('conversations')
          .doc(_activeConversationId)
          .collection('messages')
          .add({
        ...message,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Failed to save message: $e");
    }
  }

  Future<void> addMessage(String role, String text, {List<String>? palmZones, List<String>? backZones, List<String>? seeds}) async {
    final message = {
      'role': role,
      'text': text,
      'left_palm_zones': palmZones,
      'back_left_hand_zones': backZones,
      'seeds': seeds,
    };

    messages.add(message);
    _saveMessage(message);
  }

  Future<String> askQuestion(String question) async {
    final baseUrl = await AppConfig.baseUrl;
    String url = '$baseUrl/ask';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'question': question}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String answer = data['answer'] ?? 'No answer received.';

        List<String> palmZones = data['left_palm_zones'] != null
            ? List<String>.from(data['left_palm_zones'])
            : [];
        List<String> backZones = data['back_left_hand_zones'] != null
            ? List<String>.from(data['back_left_hand_zones'])
            : [];
        List<String>? seeds = data['seeds'] != null
            ? List<String>.from(data['seeds'])
            : [];

        List<String>? validPalmZones;
        if (palmZones.isNotEmpty) {
          final availableZones = PalmHandZones.getZones();
          validPalmZones = palmZones
              .where((zone) => availableZones.containsKey(zone))
              .toList();
        }

        List<String>? validBackZones;
        if (backZones.isNotEmpty) {
          final availableBackZones = BackHandZones.getZones();
          validBackZones = backZones
              .where((zone) => availableBackZones.containsKey(zone))
              .toList();
        }

        addMessage('assistant', answer,
            palmZones: validPalmZones,
            backZones: validBackZones,
            seeds: seeds);
        return answer;
      } else {
        return 'Error: ${response.statusCode}';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<void> saveLastOpenedConversationId(String conversationId) async {
    await _storage.write(key: 'last_conversation_id', value: conversationId);
  }

  Future<String?> getLastOpenedConversationId() async {
    return await _storage.read(key: 'last_conversation_id');
  }

  Future<void> clearLastConversationId() async {
    await _storage.delete(key: 'last_conversation_id');
  }

  Stream<List<Map<String, dynamic>>> conversationStream() {
    return _firestore
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('conversations')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  void clearMessages() {
    messages.clear();
  }
}
