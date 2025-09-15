import 'package:flutter/material.dart';

class OpeningHoursEditor extends StatefulWidget {
  final Map<String, Map<String, String>> openingHours;
  final ValueChanged<Map<String, Map<String, String>>> onChanged;

  const OpeningHoursEditor({
    super.key,
    required this.openingHours,
    required this.onChanged,
  });

  @override
  State<OpeningHoursEditor> createState() => _OpeningHoursEditorState();
}

class _OpeningHoursEditorState extends State<OpeningHoursEditor> {
  late Map<String, Map<String, String>> _hours;
  
  // Ordered list of days to maintain consistent display
  final List<String> _dayOrder = [
    'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'
  ];
  
  // Map for better day name display
  final Map<String, String> _dayNames = {
    'monday': 'Lunes',
    'tuesday': 'Martes', 
    'wednesday': 'Miércoles',
    'thursday': 'Jueves',
    'friday': 'Viernes',
    'saturday': 'Sábado',
    'sunday': 'Domingo',
  };

  @override
  void initState() {
    super.initState();
    _hours = Map.from(widget.openingHours);
  }

  // Convert 24h format to 12h format with AM/PM
  String _formatTimeToAmPm(String time24) {
    if (time24.isEmpty) return "";
    
    final parts = time24.split(":");
    final hour24 = int.parse(parts[0]);
    final minute = parts[1];
    
    if (hour24 == 0) {
      return "12:$minute AM";
    } else if (hour24 < 12) {
      return "$hour24:$minute AM";
    } else if (hour24 == 12) {
      return "12:$minute PM";
    } else {
      return "${hour24 - 12}:$minute PM";
    }
  }

  // Convert TimeOfDay to 24h format string
  String _formatTimeTo24h(TimeOfDay time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }

  Future<void> _pickTime(BuildContext context, String day, String field) async {
    final current = _hours[day]?[field];
    final initialTime = current != null && current.isNotEmpty
        ? TimeOfDay(
            hour: int.parse(current.split(":")[0]),
            minute: int.parse(current.split(":")[1]),
          )
        : const TimeOfDay(hour: 9, minute: 0);

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      setState(() {
        _hours[day]?[field] = _formatTimeTo24h(picked);
      });
      widget.onChanged(_hours);
    }
  }

  bool _isDayClosed(String day) {
    final open = _hours[day]!["open"] ?? "";
    final close = _hours[day]!["close"] ?? "";
    return open.isEmpty || close.isEmpty;
  }

  void _toggleDayStatus(String day) {
    setState(() {
      if (_isDayClosed(day)) {
        // Open the day with default hours
        _hours[day]!["open"] = "09:00";
        _hours[day]!["close"] = "18:00";
      } else {
        // Close the day
        _hours[day]!["open"] = "";
        _hours[day]!["close"] = "";
      }
    });
    widget.onChanged(_hours);
  }

  Widget _buildTimeButton(String day, String field, String time) {
    final isClosed = _isDayClosed(day);
    final isOpen = field == "open";
    final label = isOpen ? "Apertura" : "Cierre";
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton(
            onPressed: isClosed ? null : () => _pickTime(context, day, field),
            style: OutlinedButton.styleFrom(
              backgroundColor: isClosed 
                  ? Theme.of(context).colorScheme.surface
                  : null,
              foregroundColor: isClosed
                  ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)
                  : null,
            ),
            child: Text(
              isClosed ? "—" : (time.isEmpty ? "Seleccionar" : _formatTimeToAmPm(time)),
              style: TextStyle(
                fontWeight: isClosed ? FontWeight.normal : FontWeight.w500,
                fontSize: 13, // Slightly smaller to fit better
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 20,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Configurar horarios de atención",
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _showQuickSetupDialog(),
                  icon: Icon(
                    Icons.auto_fix_high,
                    color: theme.colorScheme.primary,
                  ),
                  tooltip: "Configuración rápida",
                ),
              ],
            ),
          ),
          
          // Days list (using ordered list)
          ...List.generate(_dayOrder.length, (index) {
            final day = _dayOrder[index];
            final open = _hours[day]!["open"] ?? "";
            final close = _hours[day]!["close"] ?? "";
            final isClosed = _isDayClosed(day);
            final isLast = index == _dayOrder.length - 1;
            
            return Container(
              decoration: BoxDecoration(
                border: isLast ? null : Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Day name and controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _dayNames[day] ?? day,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isClosed 
                                  ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              isClosed ? "Cerrado" : "Abierto",
                              style: TextStyle(
                                fontSize: 12,
                                color: isClosed 
                                    ? theme.colorScheme.error
                                    : theme.colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Switch(
                              value: !isClosed,
                              onChanged: (_) => _toggleDayStatus(day),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    if (!isClosed) ...[
                      const SizedBox(height: 12),
                      // Time buttons
                      Row(
                        children: [
                          Expanded(
                            child: _buildTimeButton(day, "open", open),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTimeButton(day, "close", close),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showQuickSetupDialog() {
    showDialog(
      context: context,
      builder: (context) => _QuickSetupDialog(
        onSetup: (openTime, closeTime, selectedDays) {
          setState(() {
            for (final day in selectedDays) {
              _hours[day]!["open"] = openTime;
              _hours[day]!["close"] = closeTime;
            }
          });
          widget.onChanged(_hours);
        },
      ),
    );
  }
}

// Dialog for quick setup
class _QuickSetupDialog extends StatefulWidget {
  final Function(String openTime, String closeTime, List<String>) onSetup;

  const _QuickSetupDialog({required this.onSetup});

  @override
  State<_QuickSetupDialog> createState() => _QuickSetupDialogState();
}

class _QuickSetupDialogState extends State<_QuickSetupDialog> {
  TimeOfDay _openTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _closeTime = const TimeOfDay(hour: 18, minute: 0);
  final Set<String> _selectedDays = {'monday', 'tuesday', 'wednesday', 'thursday', 'friday'};

  final Map<String, String> _dayNames = {
    'monday': 'Lunes',
    'tuesday': 'Martes',
    'wednesday': 'Miércoles', 
    'thursday': 'Jueves',
    'friday': 'Viernes',
    'saturday': 'Sábado',
    'sunday': 'Domingo',
  };

  final List<String> _dayOrder = [
    'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'
  ];

  String _formatTimeTo24h(TimeOfDay time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Configuración rápida"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Horario:", style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            
            // Responsive time picker layout
            LayoutBuilder(
              builder: (context, constraints) {
                // If width is less than 300px, stack vertically
                final isSmallWidth = constraints.maxWidth < 300;
                
                if (isSmallWidth) {
                  return Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: _openTime,
                            );
                            if (time != null) {
                              setState(() => _openTime = time);
                            }
                          },
                          child: Text(
                            "Apertura: ${_openTime.format(context)}",
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: _closeTime,
                            );
                            if (time != null) {
                              setState(() => _closeTime = time);
                            }
                          },
                          child: Text(
                            "Cierre: ${_closeTime.format(context)}",
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  );
                }
                
                // Original horizontal layout for wider displays
                return Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: _openTime,
                          );
                          if (time != null) {
                            setState(() => _openTime = time);
                          }
                        },
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _openTime.format(context),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.arrow_forward, size: 16),
                    ),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: _closeTime,
                          );
                          if (time != null) {
                            setState(() => _closeTime = time);
                          }
                        },
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _closeTime.format(context),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 16),
            const Text("Días:", style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ..._dayOrder.map((day) => CheckboxListTile(
                  title: Text(_dayNames[day]!),
                  value: _selectedDays.contains(day),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedDays.add(day);
                      } else {
                        _selectedDays.remove(day);
                      }
                    });
                  },
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                )),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancelar"),
        ),
        FilledButton(
          onPressed: _selectedDays.isEmpty
              ? null
              : () {
                  widget.onSetup(
                    _formatTimeTo24h(_openTime), 
                    _formatTimeTo24h(_closeTime), 
                    _selectedDays.toList()
                  );
                  Navigator.pop(context);
                },
          child: const Text("Aplicar"),
        ),
      ],
    );
  }
}