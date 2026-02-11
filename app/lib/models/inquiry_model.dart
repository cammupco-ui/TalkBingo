import 'package:supabase_flutter/supabase_flutter.dart';

class Inquiry {
  final String id;
  final String? userId; // Can be null if guest logic changes, but usually auth user
  final String category;
  final String title;
  final String content;
  final bool isPrivate;
  final String status; // 'submitted', 'in_progress', 'resolved'
  final DateTime createdAt;
  final String? answer; // For simple display of reply, though mostly in separate table
  final bool adminChecked; // Whether admin has reviewed
  final int replyCount; // Number of admin replies

  Inquiry({
    required this.id,
    this.userId,
    required this.category,
    required this.title,
    required this.content,
    required this.isPrivate,
    required this.status,
    required this.createdAt,
    this.answer,
    this.adminChecked = false,
    this.replyCount = 0,
  });

  factory Inquiry.fromJson(Map<String, dynamic> json) {
    return Inquiry(
      id: json['id'] ?? '',
      userId: json['user_id'],
      category: json['category'] ?? 'General',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      isPrivate: json['is_private'] ?? true,
      status: json['status'] ?? 'submitted',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      adminChecked: json['admin_checked'] ?? false,
      replyCount: json['reply_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (userId != null) 'user_id': userId,
      'category': category,
      'title': title,
      'content': content,
      'is_private': isPrivate,
      'status': status,
      // created_at is handled by DB default
    };
  }
}

