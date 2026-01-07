import 'package:flutter/material.dart';
import 'package:talkbingo_app/models/notice.dart';
import 'package:talkbingo_app/styles/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

class NoticeScreen extends StatefulWidget {
  const NoticeScreen({super.key});

  @override
  State<NoticeScreen> createState() => _NoticeScreenState();
}

class _NoticeScreenState extends State<NoticeScreen> {
  @override
  Widget build(BuildContext context) {
    final notices = NoticeRepository().getNotices();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: SvgPicture.asset(
          'assets/images/Logo Vector.svg',
          height: 30,
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: notices.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final notice = notices[index];
          return ExpansionTile(
            tilePadding: EdgeInsets.zero,
            leading: Icon(
              notice.isRead ? Icons.mark_email_read : Icons.mark_email_unread,
              color: notice.isRead ? Colors.grey : AppColors.hostPrimary,
            ),
            title: Text(
              notice.title,
              style: TextStyle(
                fontWeight: notice.isRead ? FontWeight.normal : FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            subtitle: Text(notice.date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(notice.content, style: const TextStyle(fontSize: 14, height: 1.5)),
              ),
            ],
            onExpansionChanged: (expanded) {
              if (expanded && !notice.isRead) {
                setState(() {
                  NoticeRepository().markAsRead(notice.id);
                });
              }
            },
          );
        },
      ),
    );
  }
}
