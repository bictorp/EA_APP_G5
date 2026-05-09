import 'package:get/get.dart';
import '../models/message.dart';
import '../services/socket_service.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import '../constants/api_constants.dart';
import 'dart:convert';

class ChatController extends GetxController {
  final SocketService _socketService = SocketService();
  final StorageService _storageService = StorageService();

  var messages = <Message>[].obs;
  var contacts = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;
  String? currentUserId;

  // Selección de mensajes
  var selectedMessageIds = <String>[].obs;
  var isSelectionMode = false.obs;

  @override
  void onInit() async {
    super.onInit();
    await _loadCurrentUser();
    _setupSocketListeners();
    fetchContacts();
  }

  Future<void> _loadCurrentUser() async {
    final userData = await _storageService.getUserData();
    if (userData != null) {
      final user = jsonDecode(userData);
      currentUserId = user['_id'];
    }
  }

  void _setupSocketListeners() {
    _socketService.on('receive_message', (data) {
      final message = Message.fromJson(data);
      messages.add(message);
    });

    _socketService.on('message_sent', (data) {
      final message = Message.fromJson(data);
      if (!messages.any((m) => m.id == message.id)) {
        messages.add(message);
      }
    });

    _socketService.on('messages_deleted', (data) {
      final List messageIds = data['messageIds'];
      final String type = data['type'];

      if (type == 'me') {
        messages.removeWhere((m) => messageIds.contains(m.id));
      } else if (type == 'everyone') {
        for (var i = 0; i < messages.length; i++) {
          if (messageIds.contains(messages[i].id)) {
            messages[i] = Message(
              id: messages[i].id,
              remitenteId: messages[i].remitenteId,
              destinatarioId: messages[i].destinatarioId,
              contenido: 'El mensaje ha sido eliminado',
              createdAt: messages[i].createdAt,
              leido: messages[i].leido,
              eliminadoParaTodos: true,
            );
          }
        }
        messages.refresh();
      }
    });
  }

  Future<void> fetchContacts() async {
    isLoading.value = true;
    try {
      final response = await AuthService.dio.get('${ApiConstants.baseUrl}/chat/contacts');
      if (response.statusCode == 200) {
        contacts.assignAll(List<Map<String, dynamic>>.from(response.data));
      }
    } catch (e) {
      print('Error buscando contactos: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadConversation(String otherUserId) async {
    isLoading.value = true;
    messages.clear();
    try {
      final response = await AuthService.dio.get('${ApiConstants.baseUrl}/chat/conversation/$otherUserId');
      if (response.statusCode == 200) {
        final List data = response.data;
        messages.assignAll(data.map((m) => Message.fromJson(m)).toList());
      }
    } catch (e) {
      print('Error cargando conversación: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void sendMessage(String destinatarioId, String contenido) {
    if (contenido.trim().isEmpty) return;
    
    _socketService.emit('send_message', {
      'destinatarioId': destinatarioId,
      'contenido': contenido,
    });
  }

  // Métodos de selección y eliminación
  void toggleSelection(String messageId) {
    if (selectedMessageIds.contains(messageId)) {
      selectedMessageIds.remove(messageId);
      if (selectedMessageIds.isEmpty) isSelectionMode.value = false;
    } else {
      selectedMessageIds.add(messageId);
      isSelectionMode.value = true;
    }
  }

  void clearSelection() {
    selectedMessageIds.clear();
    isSelectionMode.value = false;
  }

  void deleteMessages(String type, String destinatarioId) {
    if (selectedMessageIds.isEmpty) return;

    _socketService.emit('delete_messages', {
      'messageIds': selectedMessageIds.toList(),
      'type': type,
      'destinatarioId': destinatarioId,
    });
    
    clearSelection();
  }

  @override
  void onClose() {
    _socketService.off('receive_message');
    _socketService.off('message_sent');
    super.onClose();
  }
}
