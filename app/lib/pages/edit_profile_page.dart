import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/session.dart';
import '../components/image_editor.dart';
import 'dart:io';

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

  bool _isLoading = false;
  String? _role;
  String? _userId;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final session = await SessionService.getSession();
    if (session == null) return;

    final userId = session["user"]["id"];
    final response = await Supabase.instance.client
        .from("profiles")
        .select("name,phone,avatar_url,role")
        .eq("id", userId)
        .maybeSingle();

    if (response != null) {
      _nameController.text = response["name"] ?? "";
      _phoneController.text = response["phone"] ?? "";
      _avatarUrl = response["avatar_url"];
      _role = response["role"];
      _userId = userId;
    }

    // Si es negocio → cargar datos de businesses
    if (_role == "negocio") {
      final business = await Supabase.instance.client
          .from("businesses")
          .select("name,nit,address,description,logo_url")
          .eq("user_id", userId)
          .maybeSingle();

      if (business != null) {
        _businessNameController.text = business["name"] ?? "";
        _nitController.text = business["nit"] ?? "";
        _addressController.text = business["address"] ?? "";
        _descriptionController.text = business["description"] ?? "";
        _avatarUrl = business["logo_url"] ?? _avatarUrl;
      }
    }

    if (!mounted) return;
    setState(() {});
  }

  /// Sube la imagen a Supabase Storage y devuelve la URL pública
  Future<String?> _uploadImage(File file) async {
    try {
      final fileBytes = await file.readAsBytes();
      final fileName =
          '${_userId}_${DateTime.now().millisecondsSinceEpoch}.png';

      await Supabase.instance.client.storage
          .from('avatars')
          .uploadBinary(fileName, fileBytes, fileOptions: const FileOptions(upsert: true));

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
      // update profiles
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
        }).eq("user_id", _userId!);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al guardar: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                        }
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Personal Information
                    _buildSectionHeader("Información Personal", Icons.person_outline),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: "Nombre completo",
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (v) => v == null || v.isEmpty ? "Requerido" : null,
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
                      _buildSectionHeader("Información del Negocio", Icons.business),
                      TextFormField(
                        controller: _businessNameController,
                        decoration: const InputDecoration(
                          labelText: "Nombre del negocio",
                          prefixIcon: Icon(Icons.store),
                        ),
                        validator: (v) => v == null || v.isEmpty ? "Requerido" : null,
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
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: "Dirección",
                          prefixIcon: Icon(Icons.location_on),
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
                                child: CircularProgressIndicator(strokeWidth: 2),
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