import 'package:flutter/material.dart';
import '../models/petition.dart';

class PetitionCard extends StatelessWidget {
  final Petition petition;
  final VoidCallback? onTap;
  final bool isBusinessView;

  const PetitionCard({
    super.key,
    required this.petition,
    this.onTap,
    this.isBusinessView = false,
  });

  Color _statusColor(PetitionStatus status, BuildContext context) {
    switch (status) {
      case PetitionStatus.pending:
        return Colors.orange;
      case PetitionStatus.responded:
        return Colors.blue;
      case PetitionStatus.completed:
        return Colors.green;
    }
  }

  String _statusText(PetitionStatus status) {
    switch (status) {
      case PetitionStatus.pending:
        return "Pendiente";
      case PetitionStatus.responded:
        return "Respondida";
      case PetitionStatus.completed:
        return "Finalizada";
    }
  }

  IconData _getStatusIcon(PetitionStatus status) {
    switch (status) {
      case PetitionStatus.pending:
        return Icons.schedule;
      case PetitionStatus.responded:
        return Icons.mark_email_read;
      case PetitionStatus.completed:
        return Icons.check_circle;
    }
  }

  String _getBusinessMessage(PetitionStatus status) {
    switch (status) {
      case PetitionStatus.pending:
        return "Nueva oportunidad";
      case PetitionStatus.responded:
        return "Ya respondiste";
      case PetitionStatus.completed:
        return "Completada";
    }
  }

  String _getClientMessage(PetitionStatus status) {
    switch (status) {
      case PetitionStatus.pending:
        return "Esperando respuestas";
      case PetitionStatus.responded:
        return "Tienes respuestas";
      case PetitionStatus.completed:
        return "Completada";
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return "${difference.inDays}d";
    } else if (difference.inHours > 0) {
      return "${difference.inHours}h";
    } else {
      return "${difference.inMinutes}m";
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(petition.status, context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Status indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(petition.status),
                            size: 14,
                            color: statusColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _statusText(petition.status),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatDate(petition.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  petition.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                if (petition.description != null && petition.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    petition.description!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 16),
                // Action section
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isBusinessView ? 
                          (petition.status == PetitionStatus.pending ? Icons.reply : Icons.visibility) :
                          (petition.status == PetitionStatus.pending ? Icons.hourglass_empty : 
                           petition.status == PetitionStatus.responded ? Icons.notifications_active : Icons.check),
                        size: 16,
                        color: statusColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isBusinessView ? _getBusinessMessage(petition.status) : _getClientMessage(petition.status),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}