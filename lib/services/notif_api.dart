import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:logger/logger.dart';

class NotifApi {
  final String baseUrl;
  io.Socket? socket;
  final Logger logger = Logger();

  ValueNotifier<int> unreadNotifCount = ValueNotifier<int>(0);

  NotifApi({required this.baseUrl});

  void initSocket(int empId, Function(Map<String, dynamic>) onNewNotif) {
    if (socket != null && socket!.connected) {
      logger.w("⚠️ WebSocket already connected!");
      return;
    }

    socket = io.io(baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'reconnection': true,
      'reconnectionAttempts': 10, // More robust
      'reconnectionDelay': 2000,
    });

    socket!.connect();

    socket!.onConnect((_) {
      logger.i("✅ Connected to WebSocket Server");
      socket!.emit("joinRoom", empId);
    });

    socket!.on("newNotification", (data) {
      logger.i("🔔 New notification received: $data");
      onNewNotif(data);
      fetchNotifications(empId); // Auto-refresh count
    });

    socket!.onError((err) {
      logger.e("❌ WebSocket error: $err");
    });

    socket!.onDisconnect((_) => logger.w("❌ Disconnected from WebSocket"));
  }

  Future<List<Map<String, dynamic>>> fetchNotifications(int empId) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/api/notifications/$empId"));

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);

        int unreadCount = data.where((notif) => notif['READ'] == 0).length;
        unreadNotifCount.value = unreadCount;

        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception("Failed to load notifications");
      }
    } catch (e) {
      logger.e("❌ Error fetching notifications: $e");
      return [];
    }
  }

  Future<void> markAsRead(int notifId) async {
    try {
      final url = "$baseUrl/api/notifications/mark_as_read/$notifId";
      logger.i("📤 Marking notification as read: $url");

      final response = await http.put(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        logger.i("✅ Notification ID $notifId marked as read");
      } else {
        logger.e(
            "⛔ Failed to mark notification as read, Status Code: ${response.statusCode}");
        throw Exception("Failed to mark notification as read");
      }
    } catch (e) {
      logger.e("❌ Error marking notification as read: $e");
      throw Exception("Error marking notification as read");
    }
  }

  // Optional: programmatic reconnect
  void reconnect(int empId, Function(Map<String, dynamic>) onNewNotif) {
    dispose();
    initSocket(empId, onNewNotif);
  }

  void dispose() {
    socket?.disconnect();
    socket?.destroy();
    logger.w("🛑 WebSocket connection closed");
  }
}
