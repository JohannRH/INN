import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/session.dart';
import '../components/image_editor.dart';
import 'dart:io';
import './map_location_picker_page.dart';
import '../components/business_type_selector.dart';
import '../widgets/opening_hours_editor.dart';
import '../services/user_cache.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  // Solo negocio
  final _businessNameController = TextEditingController();
  final _nitController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();

  double? _latitude;
  double? _longitude;

  bool _isLoading = false;
  String? _role;
  String? _userId;
  String? _avatarUrl;

  int? _selectedBusinessTypeId;

  Map<String, Map<String, String>> _openingHours = {
    "monday": {"open": "", "close": ""},
    "tuesday": {"open": "", "close": ""},
    "wednesday": {"open": "", "close": ""},
    "thursday": {"open": "", "close": ""},
    "friday": {"open": "", "close": ""},
    "saturday": {"open": "", "close": ""},
    "sunday": {"open": "", "close": ""},
  };

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final session = await SessionService.getSession();
    if (session == null) return;

    _userId = session["user"]["id"];

    // Try cache first
    final cachedProfile = await UserCache.getProfile();
    if (cachedProfile != null && await UserCache.isCacheRecent()) {
      // Use cached data
      _nameController.text = cachedProfile["name"] ?? "";
      _phoneController.text = cachedProfile["phone"] ?? "";
      _avatarUrl = cachedProfile["avatar_url"];
      _role = cachedProfile["role"];

      if (_role == "negocio") {
        final cachedBusiness = await UserCache.getBusiness();
        if (cachedBusiness != null) {
          _businessNameController.text = cachedBusiness["name"] ?? "";
          _nitController.text = cachedBusiness["nit"] ?? "";
          _addressController.text = cachedBusiness["address"] ?? "";
          _descriptionController.text = cachedBusiness["description"] ?? "";
          _avatarUrl = cachedBusiness["logo_url"] ?? _avatarUrl;
          _latitude = (cachedBusiness["latitude"] as num?)?.toDouble();
          _longitude = (cachedBusiness["longitude"] as num?)?.toDouble();
          _selectedBusinessTypeId = cachedBusiness["type_id"];
          
          if (cachedBusiness["opening_hours"] != null) {
            _openingHours = Map<String, Map<String, String>>.from(
              (cachedBusiness["opening_hours"] as Map).map(
                (key, value) => MapEntry(key, Map<String, String>.from(value as Map)),
              ),
            );
          }
        }
      }

      if (mounted) setState(() {});
      return;
    }

    // Fetch from database if cache is missing or old
    await _fetchFromDatabase();
  }

  Future<void> _fetchFromDatabase() async {
    try {
      final response = await Supabase.instance.client
          .from("profiles")
          .select("id,name,phone,avatar_url,role,email")
          .eq("id", _userId!)
          .maybeSingle();

      if (response != null) {
        _nameController.text = response["name"] ?? "";
        _phoneController.text = response["phone"] ?? "";
        _avatarUrl = response["avatar_url"];
        _role = response["role"];
        
        // Save to cache
        await UserCache.saveProfile(response);
      }

      if (_role == "negocio") {
        final business = await Supabase.instance.client
            .from("businesses")
            .select("id,name,nit,address,description,logo_url,latitude,longitude,type_id,opening_hours,user_id")
            .eq("user_id", _userId!)
            .maybeSingle();

        if (business != null) {
          _businessNameController.text = business["name"] ?? "";
          _nitController.text = business["nit"] ?? "";
          _addressController.text = business["address"] ?? "";
          _descriptionController.text = business["description"] ?? "";
          _avatarUrl = business["logo_url"] ?? _avatarUrl;
          _latitude = (business["latitude"] as num?)?.toDouble();
          _longitude = (business["longitude"] as num?)?.toDouble();
          _selectedBusinessTypeId = business["type_id"];
          
          if (business["opening_hours"] != null) {
            _openingHours = Map<String, Map<String, String>>.from(
              (business["opening_hours"] as Map).map(
                (key, value) => MapEntry(key, Map<String, String>.from(value as Map)),
              ),
            );
          }
          
          // Save to cache
          await UserCache.saveBusiness(business);
        }
      }
    } catch (e) {
      debugPrint("Error fetching data: $e");
    }

    if (mounted) setState(() {});
  }

  /// Sube la imagen a Supabase Storage y devuelve la URL pública
  Future<String?> _uploadImage(File file) async {
    try {
      final fileBytes = await file.readAsBytes();
      final fileName =
          '${_userId}_${DateTime.now().millisecondsSinceEpoch}.png';

      await Supabase.instance.client.storage
          .from('avatars')
          .uploadBinary(fileName, fileBytes,
              fileOptions: const FileOptions(upsert: true));

      return Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(fileName);
    } catch (e) {
      debugPrint("Error subiendo imagen: $e");
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _userId == null) return;

    setState(() => _isLoading = true);

    try {
      // Update database
      await Supabase.instance.client.from("profiles").update({
        "name": _nameController.text,
        "phone": _phoneController.text,
        "avatar_url": _avatarUrl,
      }).eq("id", _userId!);

      if (_role == "negocio") {
        await Supabase.instance.client.from("businesses").update({
          "name": _businessNameController.text,
          "nit": _nitController.text,
          "address": _addressController.text,
          "description": _descriptionController.text,
          "logo_url": _avatarUrl,
          "latitude": _latitude,
          "longitude": _longitude,
          "type_id": _selectedBusinessTypeId,
          "opening_hours": _openingHours,
        }).eq("user_id", _userId!);
      }

      // Update cache with new data
      await _updateCache();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully"), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateCache() async {
    // Get existing cache to preserve all fields
    final existingProfile = await UserCache.getProfile() ?? {};
    
    // Update profile cache with new data
    final updatedProfile = {
      ...existingProfile, // Keep all existing fields (email, id, etc.)
      "name": _nameController.text,
      "phone": _phoneController.text,
      "avatar_url": _avatarUrl,
      "role": _role,
      "id": _userId,
    };
    await UserCache.saveProfile(updatedProfile);

    // Update business cache if needed
    if (_role == "negocio") {
      final existingBusiness = await UserCache.getBusiness() ?? {};
      
      final updatedBusiness = {
        ...existingBusiness, // Keep all existing fields
        "name": _businessNameController.text,
        "nit": _nitController.text,
        "address": _addressController.text,
        "description": _descriptionController.text,
        "logo_url": _avatarUrl,
        "latitude": _latitude,
        "longitude": _longitude,
        "type_id": _selectedBusinessTypeId,
        "opening_hours": _openingHours,
        "user_id": _userId,
      };
      await UserCache.saveBusiness(updatedBusiness);
    }
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _openMapForAddress() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapLocationPickerPage(
          initialLat: _latitude ?? 6.25184,
          initialLng: _longitude ?? -75.56359,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _addressController.text = result["address"] ?? "";
        _latitude = result["lat"];
        _longitude = result["lng"];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Editar perfil")),
      body: _role == null
          ? Center(
              child: CircularProgressIndicator(color: theme.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: ProfileImageSelector(
                          radius: 55,
                          networkImageUrl: _avatarUrl,
                          baseUrl: "",
                          onImageSelected: (file) async {
                            final url = await _uploadImage(file);
                            if (url != null && mounted) {
                              setState(() {
                                _avatarUrl = url;
                              });
                            }
                          }),
                    ),
                    const SizedBox(height: 20),

                    // Personal Information
                    _buildSectionHeader(
                        "Información Personal", Icons.person_outline),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: "Nombre completo",
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? "Requerido" : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: "Teléfono",
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),

                    // Business Information
                    if (_role == "negocio") ...[
                      _buildSectionHeader(
                          "Información del Negocio", Icons.business),
                      TextFormField(
                        controller: _businessNameController,
                        decoration: const InputDecoration(
                          labelText: "Nombre del negocio",
                          prefixIcon: Icon(Icons.store),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? "Requerido" : null,
                      ),
                      const SizedBox(height: 16),
                      BusinessTypeSelector(
                        selectedTypeId: _selectedBusinessTypeId,
                        onChanged: (typeId, typeName) {
                          setState(() {
                            _selectedBusinessTypeId = typeId;
                          });
                        },
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nitController,
                        decoration: const InputDecoration(
                          labelText: "NIT",
                          prefixIcon: Icon(Icons.numbers),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),

                      // Dirección con botón para mapa
                      GestureDetector(
                        onTap: _openMapForAddress,
                        child: AbsorbPointer(
                          child: TextFormField(
                            controller: _addressController,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: "Dirección",
                              prefixIcon: const Icon(Icons.location_on),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.map),
                                onPressed: _openMapForAddress,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: "Descripción",
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 3,
                      ),

                      // Horarios
                      _buildSectionHeader(
                          "Horario de Atención", Icons.access_time),
                      OpeningHoursEditor(
                        openingHours: _openingHours,
                        onChanged: (hours) {
                          setState(() {
                            _openingHours = hours;
                          });
                        },
                      ),
                    ],

                    const SizedBox(height: 30),

                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text("Guardar"),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _businessNameController.dispose();
    _nitController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}