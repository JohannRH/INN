import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/business.dart';
import '../themes/business_icons.dart';

class BusinessDetailsSheet extends StatelessWidget {
  final Business business;
  final VoidCallback? onClose;
  final ScrollController? scrollController;

  const BusinessDetailsSheet({
    super.key,
    required this.business,
    this.onClose,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final style = categoryStyles[business.categoryId ?? 16] ?? categoryStyles[16]!;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: ListView(
        controller: scrollController,
        padding: EdgeInsets.zero,
        children: [
          // Drag handle - same as ExpandableInfoPanel
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 6),
            child: Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          // Header with back button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outlineVariant,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.arrow_back),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.surfaceContainer,
                    foregroundColor: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Detalles del negocio',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content with padding - same structure as ExpandableInfoPanel
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Business header
                _buildBusinessHeader(context, style),
                const SizedBox(height: 32),
                
                // Description section
                if (business.description != null && business.description!.isNotEmpty) ...[
                  _buildDescriptionSection(context),
                  const SizedBox(height: 32),
                ],
                
                // Contact Information
                _buildContactSection(context),
                const SizedBox(height: 32),
                
                // Opening Hours
                if (business.openingHours != null && business.openingHours!.isNotEmpty) ...[
                  _buildHoursSection(context),
                  const SizedBox(height: 32),
                ],
              ],
            ),
          ),
          
          // Extra space at bottom for better draggable experience
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildBusinessHeader(BuildContext context, dynamic style) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Business logo
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).colorScheme.surfaceContainer,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: business.logoUrl != null
                ? Image.network(
                    business.logoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => 
                      Icon(
                        Icons.store_rounded, 
                        size: 40,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  )
                : Icon(
                    Icons.store_rounded, 
                    size: 40,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
          ),
        ),
        const SizedBox(width: 16),
        
        // Business info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                business.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              
              // Category badge
              if (business.typeName != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        style.icon, 
                        size: 14, 
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        business.typeName!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Acerca de'),
        const SizedBox(height: 16),
        Text(
          business.description!,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            height: 1.6,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Información de Contacto'),
        const SizedBox(height: 16),
        
        Column(
          children: [
            if (business.address != null && business.address!.isNotEmpty)
              _buildContactItem(
                context,
                Icons.location_on_rounded,
                'Dirección',
                business.address!,
              ),
            
            if (business.phone != null && business.phone!.isNotEmpty)
              _buildContactItem(
                context,
                Icons.phone_rounded,
                'Teléfono',
                business.phone!,
                onTap: () => _makePhoneCall(business.phone!),
              ),
            
            if (business.email != null && business.email!.isNotEmpty)
              _buildContactItem(
                context,
                Icons.email_rounded,
                'Email',
                business.email!,
                onTap: () => _sendEmail(business.email!),
              ),
          ].map((widget) => 
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: widget,
            )
          ).toList(),
        ),
      ],
    );
  }

  Widget _buildHoursSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Horarios de atención'),
        const SizedBox(height: 16),
        _buildCurrentHours(context, business.openingHours!),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildContactItem(
    BuildContext context, 
    IconData icon, 
    String label, 
    String value,
    {VoidCallback? onTap}
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 12),
            IconButton.filled(
              onPressed: onTap,
              icon: Icon(
                icon == Icons.phone_rounded ? Icons.call : Icons.send,
                size: 18,
              ),
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                minimumSize: const Size(40, 40),
                maximumSize: const Size(40, 40),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrentHours(BuildContext context, Map<String, dynamic> openingHours) {
    try {
      final now = DateTime.now();
      final today = _getDayName(now.weekday);
      
      final todayData = openingHours[today] as Map<String, dynamic>?;
      final openTime = todayData?['open'] as String?;
      final closeTime = todayData?['close'] as String?;
      
      final bool isClosedToday = openTime == null || openTime.isEmpty || 
                                closeTime == null || closeTime.isEmpty;
      
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isClosedToday ? [
              Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
              Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.1),
            ] : [
              Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.6),
              Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isClosedToday 
                ? Theme.of(context).colorScheme.error.withValues(alpha: 0.2)
                : Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Today's status - more compact
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isClosedToday 
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: (isClosedToday 
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.primary).withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      isClosedToday ? Icons.schedule_rounded : Icons.access_time_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isClosedToday 
                                    ? Theme.of(context).colorScheme.error
                                    : Colors.green,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _getDayDisplayName(now.weekday),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isClosedToday 
                                ? Theme.of(context).colorScheme.error
                                : Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isClosedToday ? 'CERRADO' : '${_formatTo12Hour(openTime)} - ${_formatTo12Hour(closeTime)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Divider with gradient effect
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            
            // Show all hours button - more compact
            InkWell(
              onTap: () => _showAllHours(context, openingHours),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.calendar_view_week_rounded,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Ver todos los horarios',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Text(
              'Horarios no disponibles',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }
  }

  // Helper method to format time to 12-hour format
  String _formatTo12Hour(String? time24) {
    if (time24 == null || time24.isEmpty) return '';
    
    try {
      final parts = time24.split(':');
      if (parts.length != 2) return time24;
      
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);
      
      String period = hour >= 12 ? 'PM' : 'AM';
      
      if (hour == 0) {
        hour = 12; // 00:xx becomes 12:xx AM
      } else if (hour > 12) {
        hour = hour - 12; // 13:xx becomes 1:xx PM
      }
      
      return '$hour:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return time24; // Return original if parsing fails
    }
  }

  void _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    await launchUrl(launchUri);
  }

  void _sendEmail(String email) async {
    final Uri launchUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    await launchUrl(launchUri);
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'monday';
      case 2: return 'tuesday';
      case 3: return 'wednesday';
      case 4: return 'thursday';
      case 5: return 'friday';
      case 6: return 'saturday';
      case 7: return 'sunday';
      default: return 'monday';
    }
  }

  String _getDayDisplayName(int weekday) {
    switch (weekday) {
      case 1: return 'Lunes';
      case 2: return 'Martes';
      case 3: return 'Miércoles';
      case 4: return 'Jueves';
      case 5: return 'Viernes';
      case 6: return 'Sábado';
      case 7: return 'Domingo';
      default: return 'Lunes';
    }
  }

  void _showAllHours(BuildContext context, Map<String, dynamic> openingHours) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Horarios de Atención',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            
            // Hours list
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _buildHoursList(context, openingHours),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHoursList(BuildContext context, Map<String, dynamic> openingHours) {
    final Map<String, String> dayNames = {
      'monday': 'Lun',
      'tuesday': 'Mar', 
      'wednesday': 'Mié',
      'thursday': 'Jue',
      'friday': 'Vie',
      'saturday': 'Sáb',
      'sunday': 'Dom',
    };
    
    final List<String> dayOrder = [
      'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'
    ];
    
    final now = DateTime.now();
    final today = _getDayName(now.weekday);
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1,
        childAspectRatio: 8,
        mainAxisSpacing: 4,
      ),
      itemCount: dayOrder.length,
      itemBuilder: (context, index) {
        final day = dayOrder[index];
        final dayData = openingHours[day] as Map<String, dynamic>?;
        final openTime = dayData?['open'] as String?;
        final closeTime = dayData?['close'] as String?;
        
        final bool isClosed = openTime == null || openTime.isEmpty || 
                             closeTime == null || closeTime.isEmpty;
        final bool isToday = day == today;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isToday 
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isToday ? Border.all(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
              width: 1,
            ) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dayNames[day]!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: isToday ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              Text(
                isClosed 
                    ? 'Cerrado' 
                    : '${_formatTo12Hour(openTime)} - ${_formatTo12Hour(closeTime)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isClosed 
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}