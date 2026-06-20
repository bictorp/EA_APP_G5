import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/universidad_service.dart';
import '../controllers/chat_controller.dart';
import '../constants/app_colors.dart';
import 'chat_detail_screen.dart';

class UniversitiesScreen extends StatefulWidget {
  const UniversitiesScreen({super.key});

  @override
  State<UniversitiesScreen> createState() => _UniversitiesScreenState();
}

class _UniversitiesScreenState extends State<UniversitiesScreen> {
  final UniversidadService _uniService = UniversidadService();
  final ChatController _chatController = Get.find<ChatController>();

  List<dynamic> _universidades = [];
  bool _isLoading = true;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final unis = await _uniService.getAllUniversidades();
    await _chatController.fetchContacts();
    setState(() {
      _universidades = unis;
      _isLoading = false;
    });
  }

  List<dynamic> get _filteredUniversidades {
    if (_searchQuery.trim().isEmpty) return _universidades;
    return _universidades.where((uni) {
      final name = (uni['nombre'] ?? '').toString().toLowerCase();
      final location = (uni['ubicacion'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || location.contains(query);
    }).toList();
  }

  bool _isChatJoined(String? chatGeneralId) {
    if (chatGeneralId == null) return false;
    return _chatController.contacts.any((c) => c['_id'] == chatGeneralId);
  }

  Future<void> _joinUniversityChat(String uniId) async {
    final success = await _uniService.joinChat(uniId);
    if (success) {
      Get.snackbar(
        'success'.tr,
        'universities_page.join_success_msg'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      await _loadData();
    } else {
      Get.snackbar(
        'error'.tr,
        'universities_page.join_error'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _leaveUniversityChat(String uniId) async {
    final success = await _uniService.leaveChat(uniId);
    if (success) {
      Get.snackbar(
        'success'.tr,
        'universities_page.leave_success_msg'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      await _loadData();
    } else {
      Get.snackbar(
        'error'.tr,
        'universities_page.leave_error'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          'universities_page.title'.tr,
          style: TextStyle(color: AppColors.textHeader, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textHeader),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          // Buscador
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.containerBg.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border.withOpacity(0.2)),
              ),
              child: TextField(
                style: TextStyle(color: AppColors.textHeader),
                decoration: InputDecoration(
                  hintText: 'universities_page.search_placeholder'.tr,
                  hintStyle: TextStyle(color: AppColors.textMuted.withOpacity(0.5)),
                  prefixIcon: Icon(Icons.search, color: AppColors.textMuted),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
          ),
          
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: AppColors.accent))
                : _filteredUniversidades.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.school_outlined, size: 64, color: AppColors.textMuted.withOpacity(0.2)),
                            const SizedBox(height: 16),
                            Text(
                              'universities_page.empty_state'.tr,
                              style: TextStyle(color: AppColors.textMuted, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        color: AppColors.accent,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredUniversidades.length,
                          itemBuilder: (context, index) {
                            final uni = _filteredUniversidades[index];
                            final String uniId = uni['_id'];
                            final String name = uni['nombre'] ?? 'Universidad';
                            final String location = uni['ubicacion'] ?? 'Ubicación';
                            final int members = uni['numIntegrantes'] ?? 0;
                            final String? chatGeneralId = uni['chatGeneral'];
                            final bool joined = _isChatJoined(chatGeneralId);

                            return Card(
                              color: AppColors.containerBg,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: joined
                                      ? AppColors.accent.withOpacity(0.4)
                                      : AppColors.border.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 16),
                              child: ExpansionTile(
                                shape: const Border(),
                                collapsedShape: const Border(),
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.school, color: AppColors.accent),
                                ),
                                title: Text(
                                  name,
                                  style: TextStyle(
                                    color: AppColors.textHeader,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            location,
                                            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(Icons.people_outline, size: 14, color: AppColors.textMuted),
                                        const SizedBox(width: 4),
                                        Text(
                                          'universities_page.members_count'.trParams({'count': members.toString()}),
                                          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: joined
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.green.withOpacity(0.5)),
                                        ),
                                        child: Text(
                                          'universities_page.member_tag'.tr,
                                          style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      )
                                    : const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                                childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (joined) ...[
                                        TextButton.icon(
                                          onPressed: () {
                                            if (chatGeneralId != null) {
                                              Get.to(() => ChatDetailScreen(
                                                    contactId: chatGeneralId,
                                                    contactName: '$name (General)',
                                                    contactAvatar: null,
                                                  ));
                                            }
                                          },
                                          icon: const Icon(Icons.message_outlined, color: Colors.blue),
                                          label: Text(
                                            'universities_page.btn_go_to_chat'.tr.isEmpty
                                                ? 'Ir al chat'
                                                : 'universities_page.btn_go_to_chat'.tr,
                                            style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        TextButton.icon(
                                          onPressed: () => _leaveUniversityChat(uniId),
                                          icon: const Icon(Icons.exit_to_app, color: Colors.redAccent),
                                          label: Text(
                                            'universities_page.btn_leave_chat'.tr.isEmpty
                                                ? 'Abandonar chat'
                                                : 'universities_page.btn_leave_chat'.tr,
                                            style: const TextStyle(color: Colors.redAccent),
                                          ),
                                        ),
                                      ] else ...[
                                        ElevatedButton.icon(
                                          onPressed: () => _joinUniversityChat(uniId),
                                          icon: const Icon(Icons.add, color: Colors.white),
                                          label: Text(
                                            'universities_page.btn_join_chat'.tr.isEmpty
                                                ? 'Unirme ahora'
                                                : 'universities_page.btn_join_chat'.tr,
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.accent,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                      ]
                                    ],
                                  )
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
