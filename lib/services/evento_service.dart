import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../models/evento.dart';
import 'auth_service.dart';

class EventoService {
  final Dio _dio = AuthService.dio;

  Future<List<Evento>> getEventos({double? lat, double? lng, double? distancia}) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (lat != null && lng != null) {
        queryParams['lat'] = lat;
        queryParams['lng'] = lng;
      }
      if (distancia != null) {
        queryParams['distancia'] = distancia;
      }

      if (kDebugMode) {
        print('Fetching events from: ${ApiConstants.baseUrl}/eventos with params: $queryParams');
      }

      final response = await _dio.get(
        '${ApiConstants.baseUrl}/eventos',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List list = response.data ?? [];
        return list.map((json) => Evento.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('Error in getEventos: $e');
        if (e is DioException) {
          print('Dio error response: ${e.response?.data}');
        }
      }
      return [];
    }
  }

  Future<Evento?> createEvento(Map<String, dynamic> data) async {
    try {
      if (kDebugMode) {
        print('Creating event at: ${ApiConstants.baseUrl}/eventos with data: $data');
      }

      final response = await _dio.post(
        '${ApiConstants.baseUrl}/eventos',
        data: data,
      );

      if (response.statusCode == 201) {
        return Evento.fromJson(response.data);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error in createEvento: $e');
        if (e is DioException) {
          print('Dio error response: ${e.response?.data}');
        }
      }
      rethrow;
    }
  }

  Future<Evento?> asistirEvento(String id) async {
    try {
      if (kDebugMode) {
        print('Toggling attendance for event $id');
      }

      final response = await _dio.post(
        '${ApiConstants.baseUrl}/eventos/$id/asistir',
      );

      if (response.statusCode == 200) {
        return Evento.fromJson(response.data);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error in asistirEvento: $e');
        if (e is DioException) {
          print('Dio error response: ${e.response?.data}');
        }
      }
      rethrow;
    }
  }

  Future<bool> deleteEvento(String id) async {
    try {
      if (kDebugMode) {
        print('Deleting event $id');
      }

      final response = await _dio.delete(
        '${ApiConstants.baseUrl}/eventos/$id',
      );

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('Error in deleteEvento: $e');
        if (e is DioException) {
          print('Dio error response: ${e.response?.data}');
        }
      }
      return false;
    }
  }
}
