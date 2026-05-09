import 'package:dio/dio.dart';
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
  var currentUserId = Rxn<String>();

  // Estados de carga - plain bool para GetBuilder
  bool _isLoadingContacts = false;
  bool _isLoadingMessages = false;
  
  bool get isContactsLoading => _isLoadingContacts;
  bool get isMessagesLoading => _isLoadingMessages;

  // Selección de mensajes
  var selectedMessageIds = <String>[].obs;
  var isSelectionMode = false.obs;

  // Notificaciones de mensajes sin leer
  var unreadCounts = <String, int>{}.obs; // contactId -> count
  var totalUnreadCount = 0.obs;

  String? activeChatId; // Para saber qué chat está abierto actualmente

  @override
  void onInit() {
    super.onInit();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    await _loadCurrentUser();
    _setupSocketListeners();
    fetchContacts();
    fetchTotalUnreadCount();
  }

  Future<void> _loadCurrentUser() async {
    final userData = await _storageService.getUserData();
    if (userData != null) {
      final user = jsonDecode(userData);
      currentUserId.value = user['_id'];
      print('[Chat] Usuario actual cargado: ${currentUserId.value}');
      update(); // Para que GetBuilder vea el nuevo userId
    }
  }

  void _setupSocketListeners() {
    _socketService.on('receive_message', (data) {
      final message = Message.fromJson(data);
      
      if (activeChatId == message.remitenteId) {
        messages.add(message);
        update();
      } else {
        unreadCounts[message.remitenteId] = (unreadCounts[message.remitenteId] ?? 0) + 1;
        _updateTotalUnreadCount();
      }

      _updateContactLastMessage(message);
    });

    _socketService.on('message_sent', (data) {
      final message = Message.fromJson(data);
      if (!messages.any((m) => m.id == message.id)) {
        messages.add(message);
      }
      
      _updateContactLastMessage(message);
      update();
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
      update();
    });
  }

  void _updateContactLastMessage(Message message) {
    final contactIndex = contacts.indexWhere((c) => 
      c['_id'] == message.remitenteId || c['_id'] == message.destinatarioId
    );
    
    if (contactIndex != -1) {
      final updatedContact = Map<String, dynamic>.from(contacts[contactIndex]);
      updatedContact['lastMessage'] = message.contenido;
      
      // Mover el contacto al principio de la lista (como WhatsApp)
      contacts.removeAt(contactIndex);
      contacts.insert(0, updatedContact);
      update();
    }
  }

  Future<void> fetchContacts() async {
    _isLoadingContacts = true;
    update();
    try {
      print('[Chat] Fetching contacts from: ${ApiConstants.baseUrl}/chat/contacts');
      final response = await AuthService.dio.get('${ApiConstants.baseUrl}/chat/contacts');
      print('[Chat] Contacts response: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 304) {
        if (response.data != null && response.data is List) {
          contacts.assignAll(List<Map<String, dynamic>>.from(response.data));
          // Actualizar mapa de no leídos desde la respuesta del servidor
          for (var contact in contacts) {
            unreadCounts[contact['_id']] = contact['unreadCount'] ?? 0;
          }
          _updateTotalUnreadCount();
          print('[Chat] Loaded ${contacts.length} contacts');
        }
      }
    } catch (e) {
      print('[Chat] Error buscando contactos: $e');
    } finally {
      _isLoadingContacts = false;
      update();
    }
  }

  Future<void> fetchTotalUnreadCount() async {
    try {
      final response = await AuthService.dio.get('${ApiConstants.baseUrl}/chat/unread-count');
      if (response.statusCode == 200) {
        totalUnreadCount.value = response.data['count'] ?? 0;
      }
    } catch (e) {
      print('Error al obtener contador global: $e');
    }
  }

  void _updateTotalUnreadCount() {
    int total = 0;
    unreadCounts.forEach((key, value) => total += value);
    totalUnreadCount.value = total;
    update();
  }

  void loadConversation(String otherUserId) {
    print('[Chat] >>> CARGANDO CHAT: $otherUserId');
    
    // Si cambiamos de chat, limpiamos
    if (activeChatId != otherUserId) {
      messages.clear();
      activeChatId = otherUserId;
    }
    
    // Mostrar loading solo si no hay mensajes en caché
    // No llamar update() aquí porque puede ser invocado desde initState (durante build)
    // El GetBuilder leerá el valor en su primer build automáticamente
    if (messages.isEmpty) {
      _isLoadingMessages = true;
    }

    // Restar no leídos de este contacto
    final count = unreadCounts[otherUserId] ?? 0;
    if (count > 0) {
      totalUnreadCount.value = (totalUnreadCount.value - count).clamp(0, 999999);
      unreadCounts[otherUserId] = 0;
    }
    
    // Lanzar la petición HTTP sin bloquear
    _fetchMessages(otherUserId);
  }

  Future<void> _fetchMessages(String otherUserId) async {
    // Asegurar que tenemos userId
    if (currentUserId.value == null) {
      await _loadCurrentUser();
    }

    try {
      print('[Chat] Intentando carga...');
      final response = await AuthService.dio.get(
        '${ApiConstants.baseUrl}/chat/conversation/$otherUserId',
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      // Verificar que el usuario no cambió de chat
      if (activeChatId != otherUserId) return;

      if (response.data != null && response.data is List) {
        final List data = response.data;
        messages.assignAll(data.map((m) => Message.fromJson(m)).toList());
        print('[Chat] Carga exitosa: ${messages.length} mensajes');
      } else {
        print('[Chat] Respuesta sin mensajes');
      }
    } catch (e) {
      print('[Chat] Error cargando mensajes: $e');
    } finally {
      _isLoadingMessages = false;
      update();
    }
  }

  void closeConversation() {
    activeChatId = null;
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
    update();
  }

  void clearSelection() {
    selectedMessageIds.clear();
    isSelectionMode.value = false;
    update();
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
