import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BusinessTypeSelector extends StatefulWidget {
  final int? selectedTypeId;
  final Function(int? typeId, String? typeName) onChanged;
  final String? errorText;
  final bool enabled;

  const BusinessTypeSelector({
    super.key,
    this.selectedTypeId,
    required this.onChanged,
    this.errorText,
    this.enabled = true,
  });

  @override
  State<BusinessTypeSelector> createState() => _BusinessTypeSelectorState();
}

class _BusinessTypeSelectorState extends State<BusinessTypeSelector> {
  List<Map<String, dynamic>> _groupedBusinessTypes = [];
  bool _isLoading = false;
  int? _selectedTypeId;
  String? _selectedTypeName;

  @override
  void initState() {
    super.initState();
    _selectedTypeId = widget.selectedTypeId;
    _loadBusinessData();
  }

  @override
  void didUpdateWidget(BusinessTypeSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedTypeId != widget.selectedTypeId) {
      _selectedTypeId = widget.selectedTypeId;
      _findSelectedTypeName();
    }
  }

  void _findSelectedTypeName() {
    if (_selectedTypeId == null) {
      _selectedTypeName = null;
      return;
    }
    
    final selectedType = _groupedBusinessTypes.firstWhere(
      (type) => type['id'] == _selectedTypeId,
      orElse: () => {'name': null},
    );
    _selectedTypeName = selectedType['name'];
  }

  Future<void> _loadBusinessData() async {
    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client
          .from('business_categories')
          .select('id, name, business_types(id, name)')
          .order('id');

      final data = response as List<dynamic>;

      List<Map<String, dynamic>> groupedTypes = [];

      for (var category in data) {
        final categoryName = category['name'] as String;
        final types = List<Map<String, dynamic>>.from(category['business_types']);
        
        for (var type in types) {
          groupedTypes.add({
            'id': type['id'],
            'name': type['name'],
            'category': categoryName,
          });
        }
      }

      // Sort by category first, then by type name
      groupedTypes.sort((a, b) {
        int categoryComparison = a['category'].compareTo(b['category']);
        if (categoryComparison != 0) return categoryComparison;
        return a['name'].compareTo(b['name']);
      });

      setState(() {
        _groupedBusinessTypes = groupedTypes;
        _isLoading = false;
      });
      
      _findSelectedTypeName();
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading business data: $e');
    }
  }

  void _showBusinessTypeModal() async {
    if (!widget.enabled || _isLoading) return;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BusinessTypeModal(
        businessTypes: _groupedBusinessTypes,
        selectedTypeId: _selectedTypeId,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedTypeId = result['id'];
        _selectedTypeName = result['name'];
      });
      widget.onChanged(result['id'], result['name']);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _showBusinessTypeModal,
          child: AbsorbPointer(
            child: TextFormField(
              decoration: InputDecoration(
                labelText: 'Tipo de negocio',
                hintText: 'Selecciona el tipo de negocio',
                prefixIcon: const Icon(Icons.business_outlined),
                suffixIcon: const Icon(Icons.arrow_drop_down),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.red),
                ),
              ),
              controller: TextEditingController(
                text: _isLoading 
                    ? 'Cargando...' 
                    : _selectedTypeName ?? '',
              ),
              enabled: widget.enabled && !_isLoading,
            ),
          ),
        ),
        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 12),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.errorText!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class BusinessTypeModal extends StatefulWidget {
  final List<Map<String, dynamic>> businessTypes;
  final int? selectedTypeId;

  const BusinessTypeModal({
    super.key,
    required this.businessTypes,
    this.selectedTypeId,
  });

  @override
  State<BusinessTypeModal> createState() => _BusinessTypeModalState();
}

class _BusinessTypeModalState extends State<BusinessTypeModal> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredTypes = [];

  @override
  void initState() {
    super.initState();
    _filteredTypes = widget.businessTypes;
    _searchController.addListener(_filterTypes);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterTypes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredTypes = widget.businessTypes;
      } else {
        _filteredTypes = widget.businessTypes.where((type) {
          return type['name'].toLowerCase().contains(query) ||
                 type['category'].toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Container(
      height: screenHeight * 0.75,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  'Selecciona un tipo de negocio',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar tipo de negocio...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.outline.withValues(alpha: 0.1),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // List
          Expanded(
            child: _buildBusinessTypesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessTypesList() {
    if (_filteredTypes.isEmpty) {
      return const Center(
        child: Text('No se encontraron resultados'),
      );
    }

    String? lastCategory;
    List<Widget> items = [];

    for (var type in _filteredTypes) {
      String currentCategory = type['category'];
      
      // Add category header if it's a new category
      if (lastCategory != currentCategory) {
        items.add(_buildCategoryHeader(currentCategory));
        lastCategory = currentCategory;
      }

      // Add the business type
      items.add(_buildBusinessTypeItem(type));
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: items,
    );
  }

  Widget _buildCategoryHeader(String category) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        category,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildBusinessTypeItem(Map<String, dynamic> type) {
    final theme = Theme.of(context);
    final isSelected = type['id'] == widget.selectedTypeId;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isSelected 
            ? theme.colorScheme.primary.withValues(alpha: 0.1) 
            : Colors.transparent,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        title: Text(
          type['name'],
          style: TextStyle(
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
            color: isSelected 
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface,
          ),
        ),
        trailing: isSelected 
            ? Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
                size: 18,
              )
            : null,
        onTap: () {
          Navigator.of(context).pop({
            'id': type['id'],
            'name': type['name'],
            'category': type['category'],
          });
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

// Service class to handle business data fetching
class BusinessService {
  static Future<Map<String, List<Map<String, dynamic>>>> fetchBusinessCategories() async {
    final response = await Supabase.instance.client
        .from('business_categories')
        .select('id, name, business_types(id, name)')
        .order('id');

    final data = response as List<dynamic>;

    return {
      for (var cat in data)
        cat['name']: List<Map<String, dynamic>>.from(cat['business_types'])
    };
  }

  static Future<Map<String, dynamic>?> getBusinessTypeById(int typeId) async {
    final response = await Supabase.instance.client
        .from('business_types')
        .select('id, name, business_categories(name)')
        .eq('id', typeId)
        .maybeSingle();

    return response;
  }
}