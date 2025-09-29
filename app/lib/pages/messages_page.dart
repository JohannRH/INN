import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/session.dart';
import 'chat_page.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  String? _userId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final session = await SessionService.getSession();
      if (mounted) {
        setState(() {
          _userId = session?['user']?['id'];
          _isLoading = false;
        });
      }
    } catch (e) {
      log('Error loading user: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Stream<List<Map<String, dynamic>>> _conversationsStream() {
    if (_userId == null) return const Stream.empty();

    return Supabase.instance.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) {
      // Filter messages where user is involved
      final filtered = rows.where((row) =>
          row['sender_id'] == _userId || row['recipient_id'] == _userId);

      // Group by request_id and keep only the latest message
      final Map<String, Map<String, dynamic>> latestByRequest = {};
      for (var row in filtered) {
        final requestId = row['request_id'];
        if (requestId != null) {
          if (!latestByRequest.containsKey(requestId) ||
              DateTime.parse(row['created_at'])
                  .isAfter(DateTime.parse(latestByRequest[requestId]!['created_at']))) {
            latestByRequest[requestId] = row;
          }
        }
      }

      // Sort by created_at descending
      final sortedList = latestByRequest.values.toList()
        ..sort((a, b) => DateTime.parse(b['created_at'])
            .compareTo(DateTime.parse(a['created_at'])));

      return sortedList;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          "Mensajes",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userId == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: theme.colorScheme.error.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error al cargar usuario',
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                )
              : StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _conversationsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      log('Stream error: ${snapshot.error}');
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: theme.colorScheme.error.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error al cargar conversaciones',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${snapshot.error}',
                              style: theme.textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    final conversations = snapshot.data ?? [];

                    if (conversations.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer
                                    .withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.chat_bubble_outline,
                                size: 48,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              "No tienes conversaciones aún",
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Las conversaciones aparecerán aquí",
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: conversations.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        indent: 72,
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                      ),
                      itemBuilder: (context, index) {
                        final convo = conversations[index];
                        final lastMessage = convo['content'] ?? '';
                        final requestId = convo['request_id'];
                        final otherUserId = convo['sender_id'] == _userId
                            ? convo['recipient_id']
                            : convo['sender_id'];
                        final isFromMe = convo['sender_id'] == _userId;

                        return FutureBuilder(
                          future: Supabase.instance.client
                              .from('requests')
                              .select('title')
                              .eq('id', requestId)
                              .maybeSingle(),
                          builder: (context, titleSnapshot) {
                            final title = titleSnapshot.data?['title'] as String? ??
                                "Conversación";

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: CircleAvatar(
                                radius: 28,
                                backgroundColor: theme.colorScheme.primary,
                                child: const Icon(
                                  Icons.chat,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              title: Text(
                                titleSnapshot.connectionState ==
                                        ConnectionState.waiting
                                    ? "Cargando..."
                                    : title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  isFromMe ? 'Tú: $lastMessage' : lastMessage,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.7),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _formatDate(convo['created_at']),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.5),
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (!isFromMe) ...[
                                    const SizedBox(height: 4),
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatPage(
                                      requestId: requestId,
                                      otherUserId: otherUserId,
                                      title: title,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                ),
    );
  }

  String _formatDate(String? isoString) {
    if (isoString == null) return "";
    try {
      final date = DateTime.parse(isoString);
      final now = DateTime.now();

      if (date.day == now.day &&
          date.month == now.month &&
          date.year == now.year) {
        return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
      } else if (date.year == now.year) {
        return "${date.day}/${date.month}";
      } else {
        return "${date.day}/${date.month}/${date.year.toString().substring(2)}";
      }
    } catch (e) {
      log('Error formatting date: $e');
      return "";
    }
  }
}