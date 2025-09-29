import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/session.dart';

class UnreadMessagesBadge extends StatefulWidget {
  const UnreadMessagesBadge({super.key});

  @override
  State<UnreadMessagesBadge> createState() => _UnreadMessagesBadgeState();
}

class _UnreadMessagesBadgeState extends State<UnreadMessagesBadge> {
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final session = await SessionService.getSession();
    if (mounted) {
      setState(() {
        _userId = session?['user']?['id'];
      });
    }
  }

  Stream<int> _unreadMessagesStream() {
    if (_userId == null) return Stream.value(0);

    return Supabase.instance.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .map((rows) {
      // Filter for unread messages sent to this user
      final unreadMessages = rows.where((row) =>
          row['recipient_id'] == _userId && 
          row['is_read'] == false);
      
      // Count unique conversations with unread messages
      final Set<String> requestsWithUnread = {};
      for (var row in unreadMessages) {
        final requestId = row['request_id'];
        if (requestId != null) {
          requestsWithUnread.add(requestId);
        }
      }
      return requestsWithUnread.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return const Icon(Icons.message_outlined);
    }

    return StreamBuilder<int>(
      stream: _unreadMessagesStream(),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.message_outlined),
            if (count > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.surface,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    count > 9 ? '9+' : count.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}