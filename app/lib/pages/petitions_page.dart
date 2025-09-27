import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/petition.dart';
import '../components/petition_card.dart';
import '../services/session.dart';
import 'messages_page.dart';
import '../services/user_cache.dart';

class PetitionsPage extends StatefulWidget {
  const PetitionsPage({super.key});

  @override
  PetitionsPageState createState() => PetitionsPageState();
}

class PetitionsPageState extends State<PetitionsPage> {
  List<Map<String, dynamic>> _categories = [];
  int? _selectedCategoryId;
  String? _role; // cliente o negocio
  int? _businessCategoryId;
  String? _userId;
  
  List<Petition> _petitions = [];
  bool _isLoading = true;
  RealtimeChannel? _realtimeChannel;

  @override
  void initState() {
    super.initState();
    log('PetitionsPage: initState called');
    _initializePage();
  }

  @override
  void dispose() {
    log('PetitionsPage: dispose called');
    _disposeRealtime();
    super.dispose();
  }

  Future<void> _initializePage() async {
    await _loadUserRole();
    await _fetchCategories();
    await _loadInitialPetitions();
    _setupRealtime();
  }

  void _disposeRealtime() {
    if (_realtimeChannel != null) {
      Supabase.instance.client.removeChannel(_realtimeChannel!);
      _realtimeChannel = null;
    }
  }

  Future<void> _loadUserRole() async {
    final session = await SessionService.getSession();
    final userId = session?["user"]?["id"];
    
    final profile = await UserCache.getProfile();
    if (profile == null) {
      setState(() {
        _role = null;
        _businessCategoryId = null;
        _userId = userId;
      });
      return;
    }

    final role = profile["role"];
    int? categoryId;

    if (role == "negocio") {
      final business = await UserCache.getBusiness();
      if (business != null && business["type_id"] != null) {
        final typeResponse = await Supabase.instance.client
            .from('business_types')
            .select('category_id')
            .eq('id', business["type_id"])
            .maybeSingle();

        categoryId = typeResponse?['category_id'] as int?;
        log("Business type_id: ${business["type_id"]}");
        log("Found category_id: $categoryId");
      }
    }

    setState(() {
      _role = role;
      _businessCategoryId = categoryId;
      _userId = userId;
    });
  }

  Future<void> _loadInitialPetitions() async {
    if (_role == null || _userId == null) {
      setState(() {
        _isLoading = false;
        _petitions = [];
      });
      return;
    }

    try {
      List<Map<String, dynamic>> data;
      
      if (_role == "cliente") {
        final response = await Supabase.instance.client
            .from('requests')
            .select()
            .eq('user_id', _userId!)
            .order('created_at', ascending: false);
        data = List<Map<String, dynamic>>.from(response);
      } else if (_role == "negocio" && _businessCategoryId != null) {
        final response = await Supabase.instance.client
            .from('requests')
            .select()
            .eq('category_id', _businessCategoryId!)
            .order('created_at', ascending: false);
        data = List<Map<String, dynamic>>.from(response);
      } else {
        data = [];
      }

      setState(() {
        _petitions = data.map((json) => Petition.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      log('Error loading petitions: $e');
      setState(() {
        _petitions = [];
        _isLoading = false;
      });
    }
  }

  void _setupRealtime() {
    if (_role == null || _userId == null) return;

    // Dispose previous channel if exists
    _disposeRealtime();

    // Create new channel
    _realtimeChannel = Supabase.instance.client
        .channel('requests_${DateTime.now().millisecondsSinceEpoch}');

    // Listen to all changes in requests table
    _realtimeChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'requests',
          callback: _handleRealtimeChange,
        )
        .subscribe();
  }

  void _handleRealtimeChange(PostgresChangePayload payload) {
    log('Realtime change received: ${payload.eventType}');
    
    final Map<String, dynamic> newRecord = payload.newRecord;
    final Map<String, dynamic> oldRecord = payload.oldRecord;

    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
        if (newRecord.isNotEmpty) {
          _handleInsert(newRecord);
        }
        break;
      case PostgresChangeEvent.update:
        if (newRecord.isNotEmpty) {
          _handleUpdate(newRecord);
        }
        break;
      case PostgresChangeEvent.delete:
        if (oldRecord.isNotEmpty) {
          _handleDelete(oldRecord);
        }
        break;
      case PostgresChangeEvent.all:
        // This case shouldn't occur since we're listening to specific events
        log('Received PostgresChangeEvent.all - ignoring');
        break;
    }
  }

  void _handleInsert(Map<String, dynamic> record) {
    // Check if this petition should be visible to current user
    bool shouldShow = false;
    
    if (_role == "cliente" && record['user_id'] == _userId) {
      shouldShow = true;
    } else if (_role == "negocio" && record['category_id'] == _businessCategoryId) {
      shouldShow = true;
    }

    if (shouldShow) {
      final newPetition = Petition.fromJson(record);
      setState(() {
        _petitions.insert(0, newPetition); // Add to beginning
      });
    }
  }

  void _handleUpdate(Map<String, dynamic> record) {
    final petitionId = record['id'];
    final index = _petitions.indexWhere((p) => p.id == petitionId);
    
    if (index != -1) {
      final updatedPetition = Petition.fromJson(record);
      setState(() {
        _petitions[index] = updatedPetition;
      });
    }
  }

  void _handleDelete(Map<String, dynamic> record) {
    final petitionId = record['id'];
    setState(() {
      _petitions.removeWhere((p) => p.id == petitionId);
    });
  }

  /// Public method to refresh when needed (can be called from outside)
  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
    });
    
    await _loadUserRole();
    await _loadInitialPetitions();
    _setupRealtime(); // Reset realtime connection
  }

  Future<void> _fetchCategories() async {
    try {
      final res = await Supabase.instance.client
          .from("business_categories")
          .select("id, name")
          .order("name");

      setState(() {
        _categories = List<Map<String, dynamic>>.from(res);
      });
    } catch (e) {
      log('Error fetching categories: $e');
    }
  }

  Future<void> _createPetition(String title, String? description) async {
    final session = await SessionService.getSession();
    if (session == null) throw Exception("No hay sesión activa");

    if (_selectedCategoryId == null) {
      throw Exception("Debes seleccionar una categoría");
    }

    final userId = session["user"]["id"];

    await Supabase.instance.client.from('requests').insert({
      'user_id': userId,
      'category_id': _selectedCategoryId,
      'title': title,
      'description': description,
      'status': 'pendiente',
    });

    // No need to manually update the list - realtime will handle it
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _role == "cliente" ? "Mis Peticiones" : "Peticiones",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: refresh,
          ),
          IconButton(
            icon: const Icon(Icons.message_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MessagesPage()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
      // Show floating button only for clients (regardless of empty state)
      floatingActionButton: _role == "cliente"
          ? FloatingActionButton.extended(
              onPressed: () => _showCreatePetitionDialog(),
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text("Nueva Petición"),
            )
          : null,
    );
  }

  Widget _buildContent() {
    if (_petitions.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        if (_role == "negocio") _buildBusinessHeader(_petitions.length),
        Expanded(
          child: RefreshIndicator(
            onRefresh: refresh,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _petitions.length,
              itemBuilder: (context, index) {
                return PetitionCard(
                  petition: _petitions[index],
                  isBusinessView: _role == "negocio",
                  onTap: () {},
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _role == "cliente" ? Icons.assignment_outlined : Icons.store_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _role == "cliente" 
                        ? "No tienes peticiones aún"
                        : "No hay peticiones disponibles",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _role == "cliente"
                        ? "Crea tu primera petición para conectar con negocios locales"
                        : "Las peticiones de clientes aparecerán aquí cuando estén disponibles",
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBusinessHeader(int totalPetitions) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.business_center,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "$totalPetitions ${totalPetitions == 1 ? 'petición disponible' : 'peticiones disponibles'}",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "Actualizaciones en tiempo real",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Rest of the methods remain the same...
  void _showCreatePetitionDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    int? selectedCategoryId;
    String? selectedCategoryName;

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Nueva Petición",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                
                // Form Content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: "Título",
                          hintText: "¿Qué necesitas?",
                          prefixIcon: Icon(Icons.title),
                        ),
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 16),
                      
                      StatefulBuilder(
                        builder: (context, setDialogState) {
                          return GestureDetector(
                            onTap: () async {
                              final result = await _showCategorySelector();
                              if (result != null) {
                                setDialogState(() {
                                  selectedCategoryId = result['id'];
                                  selectedCategoryName = result['name'];
                                });
                              }
                            },
                            child: AbsorbPointer(
                              child: TextField(
                                decoration: const InputDecoration(
                                  labelText: "Categoría",
                                  hintText: "Selecciona una categoría",
                                  prefixIcon: Icon(Icons.category),
                                  suffixIcon: Icon(Icons.arrow_drop_down),
                                ),
                                controller: TextEditingController(
                                  text: selectedCategoryName ?? '',
                                ),
                              ),
                            ),
                          );
                        }
                      ),
                      const SizedBox(height: 16),
                      
                      TextField(
                        controller: descController,
                        decoration: const InputDecoration(
                          labelText: "Descripción (opcional)",
                          hintText: "Más detalles...",
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ],
                  ),
                ),
                
                // Footer
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Cancelar",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (titleController.text.trim().isEmpty) {
                              _showErrorSnackBar("Ingresa un título");
                              return;
                            }
                            
                            if (selectedCategoryId == null) {
                              _showErrorSnackBar("Selecciona una categoría");
                              return;
                            }

                            final navigator = Navigator.of(context);
                            
                            try {
                              setState(() {
                                _selectedCategoryId = selectedCategoryId;
                              });
                              
                              await _createPetition(
                                titleController.text.trim(),
                                descController.text.trim().isEmpty 
                                  ? null 
                                  : descController.text.trim(),
                              );
                              
                              if (!mounted) return;

                              navigator.pop();
                              _showSuccessSnackBar("Petición creada");
                            } catch (e) {
                              if (!mounted) return;
                              _showErrorSnackBar("Error: $e");
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Crear",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _showCategorySelector() async {
    return await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CategorySelectorModal(categories: _categories),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
    );
  }
}

// CategorySelectorModal remains the same as in your original code
class CategorySelectorModal extends StatefulWidget {
  final List<Map<String, dynamic>> categories;

  const CategorySelectorModal({
    super.key,
    required this.categories,
  });

  @override
  State<CategorySelectorModal> createState() => _CategorySelectorModalState();
}

class _CategorySelectorModalState extends State<CategorySelectorModal> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredCategories = [];

  @override
  void initState() {
    super.initState();
    _filteredCategories = widget.categories;
    _searchController.addListener(_filterCategories);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCategories() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCategories = widget.categories;
      } else {
        _filteredCategories = widget.categories.where((category) {
          return category['name'].toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Container(
      height: screenHeight * 0.6,
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
                  'Selecciona una categoría',
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
                hintText: 'Buscar categoría...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: theme.colorScheme.outline.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Categories list
          Expanded(
            child: _buildCategoriesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesList() {
    if (_filteredCategories.isEmpty) {
      return const Center(
        child: Text('No se encontraron categorías'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _filteredCategories.length,
      itemBuilder: (context, index) {
        final category = _filteredCategories[index];
        return _buildCategoryItem(category);
      },
    );
  }

  Widget _buildCategoryItem(Map<String, dynamic> category) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.transparent,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.category,
            color: theme.colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          category['name'],
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface,
          ),
        ),
        onTap: () {
          Navigator.of(context).pop({
            'id': category['id'],
            'name': category['name'],
          });
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}