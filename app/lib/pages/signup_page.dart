import 'package:flutter/material.dart';
import '../services/auth.dart';
import '../main.dart';
import '../services/session.dart';
import 'package:country_code_picker/country_code_picker.dart';
import './map_location_picker_page.dart';
import '../components/business_type_selector.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> with TickerProviderStateMixin {
  int _currentStep = 0;
  String? _selectedType;
  bool _termsAccepted = false;
  bool _isLoading = false;

  // Controllers
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _nitController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  double? _latitude;
  double? _longitude;

  int? _selectedBusinessTypeId;

  // Password visibility
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Password strength tracking
  int _passwordStrength = 0;
  List<bool> _passwordCriteria = List.filled(5, false);

  // Error states
  String? _fullNameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _businessNameError;
  String? _nitError;
  String? _addressError;
  String? _phoneError;

  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    // Add listeners for real-time validation
    _fullNameController.addListener(_validateFullName);
    _emailController.addListener(_validateEmail);
    _passwordController.addListener(_validatePassword);
    _confirmPasswordController.addListener(_validateConfirmPassword);
    _phoneController.addListener(_validatePhone);
    _nitController.addListener(_validateNit);
    _addressController.addListener(_validateAddress);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _businessNameController.dispose();
    _nitController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Validation methods
  void _validateFullName() {
    setState(() {
      if (_fullNameController.text.isEmpty) {
        _fullNameError = "Este campo es obligatorio";
      } else {
        _fullNameError = null;
      }
    });
  }

  void _validateEmail() {
    setState(() {
      if (_emailController.text.isEmpty) {
        _emailError = null;
      } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
          .hasMatch(_emailController.text)) {
        _emailError = "Ingresa un correo válido";
      } else {
        _emailError = null;
      }
    });
  }

  void _validatePassword() {
    setState(() {
      String password = _passwordController.text;
      _passwordCriteria = List.filled(5, false);
      _passwordStrength = 0;
      
      if (password.isEmpty) {
        _passwordError = null;
        return;
      }

      // Check each criteria
      if (password.length >= 8) {
        _passwordCriteria[0] = true;
        _passwordStrength++;
      }
      
      if (RegExp(r'[a-z]').hasMatch(password)) {
        _passwordCriteria[1] = true;
        _passwordStrength++;
      }
      
      if (RegExp(r'[A-Z]').hasMatch(password)) {
        _passwordCriteria[2] = true;
        _passwordStrength++;
      }
      
      if (RegExp(r'\d').hasMatch(password)) {
        _passwordCriteria[3] = true;
        _passwordStrength++;
      }
      
      if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
        _passwordCriteria[4] = true;
        _passwordStrength++;
      }

      // Password is valid if it meets at least 4 out of 5 criteria (80%)
      if (_passwordStrength >= 4) {
        _passwordError = null;
      } else {
        _passwordError = null; // Don't show error, just show progress
      }
    });
  }

  void _validateConfirmPassword() {
    setState(() {
      if (_confirmPasswordController.text.isEmpty) {
        _confirmPasswordError = null;
      } else if (_passwordController.text != _confirmPasswordController.text) {
        _confirmPasswordError = "Las contraseñas no coinciden";
      } else {
        _confirmPasswordError = null;
      }
    });
  }

  void _validatePhone() {
    setState(() {
      if (_phoneController.text.isEmpty) {
        _phoneError = null;
      } else if (!RegExp(r'^\d{10}$').hasMatch(_phoneController.text)) {
        _phoneError = "Ingresa un número de 10 dígitos";
      } else {
        _phoneError = null;
      }
    });
  }

  void _validateNit() {
    setState(() {
      if (_nitController.text.isEmpty) {
        _nitError = null;
      } else if (!RegExp(r'^\d{8,15}$').hasMatch(_nitController.text)) {
        _nitError = "NIT debe tener entre 8-15 dígitos";
      } else {
        _nitError = null;
      }
    });
  }

  void _validateAddress() {
    setState(() {
      if (_addressController.text.isEmpty) {
        _addressError = "Este campo es obligatorio";
      } else {
        _addressError = null;
      }
    });
  }

  Future<void> _openMapForAddress() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapLocationPickerPage(
          initialLat: _latitude ?? 6.25184, // Default to Medellín
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

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _nextStep() {
    if (_canProceed()) {
      setState(() {
        _currentStep++;
      });
      _animationController.reset();
      _animationController.forward();
    }
    // No need for else block - individual field validations already show specific errors
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _animationController.reset();
      _animationController.forward();
    }
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _selectedType != null;
      case 1:
        return _emailController.text.isNotEmpty &&
            _passwordController.text.isNotEmpty &&
            _confirmPasswordController.text.isNotEmpty &&
            _passwordController.text == _confirmPasswordController.text &&
            _emailError == null &&
            _passwordStrength >= 4 &&
            _confirmPasswordError == null;
      case 2:
        if (_selectedType == "Cliente") {
          return _phoneController.text.isNotEmpty && 
                _termsAccepted &&
                _phoneError == null;
        } else {
          return _businessNameController.text.isNotEmpty &&
              _nitController.text.isNotEmpty &&
              _addressController.text.isNotEmpty &&
              _phoneController.text.isNotEmpty &&
              _selectedBusinessTypeId != null && 
              _termsAccepted &&
              _businessNameError == null &&
              _nitError == null &&
              _addressError == null &&
              _phoneError == null;
        }
      default:
        return true;
    }
  }

  String _selectedDialCode = "+57"; // por defecto Colombia

  Future<void> _register() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    final body = {
      "name": _fullNameController.text.trim(),
      "email": _emailController.text.trim(),
      "password": _passwordController.text.trim(),
      "role": _selectedType?.toLowerCase(), // "cliente" o "negocio"
      "phone": "$_selectedDialCode${_phoneController.text.trim()}",
      if (_selectedType == "Negocio") ...{
        "business_name": _businessNameController.text.trim(),
        "type_id": _selectedBusinessTypeId,
        "nit": _nitController.text.trim(),
        "address": _addressController.text.trim(),
        "latitude": _latitude,
        "longitude": _longitude,
      }
    };

    try {
     final result = await _authService.register(body);

      if (!mounted) return;

      final token = result['access_token'];
      final refreshToken = result['refresh_token'];
      final user = result['user'];

      await SessionService.saveSession(
        token, 
        user,
        refreshToken: refreshToken,
      );

      if (!mounted) return;

      _showSuccessSnackBar("¡Cuenta creada exitosamente!");
      
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => MainScreen(
            toggleTheme: () {},
            isDarkMode: false,
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      
      // Only show meaningful error messages from server responses
      _showErrorSnackBar(_parseError(e.toString()));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // This method provides meaningful error messages based on server responses
  String _parseError(String error) {
    if (error.contains('email already exists')) {
      return 'Este correo ya está registrado';
    } else if (error.contains('network')) {
      return 'Error de conexión. Verifica tu internet';
    } else if (error.contains('timeout')) {
      return 'La solicitud tardó demasiado. Inténtalo de nuevo';
    }
    return 'Error al crear la cuenta: $error';
  }

  Widget _buildStepIndicator() {
    final theme = Theme.of(context);
    int totalSteps = 3;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalSteps, (index) {
          bool isActive = index <= _currentStep;
          bool isCurrent = index == _currentStep;
          return Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline.withValues(alpha: 0.3),
                  border: isCurrent
                      ? Border.all(color: theme.colorScheme.primary, width: 3)
                      : null,
                ),
                child: Center(
                  child: isActive
                      ? Icon(
                          index < _currentStep ? Icons.check : Icons.circle,
                          color: Colors.white,
                          size: 16,
                        )
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              if (index < totalSteps - 1)
                Container(
                  width: 40,
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: index < _currentStep
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildUserTypeSelection() {
    return Column(
      children: [
        const Text("¿Cómo quieres usar la app?",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 32),
        _buildTypeCard("Cliente", Icons.person_outline,
            "Soy Cliente", "Quiero descubrir negocios locales"),
        const SizedBox(height: 16),
        _buildTypeCard("Negocio", Icons.store_outlined, "Tengo un Negocio",
            "Quiero hacer visible mi negocio"),
      ],
    );
  }

  Widget _buildTypeCard(
      String type, IconData icon, String title, String subtitle) {
    final theme = Theme.of(context);
    bool isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
              color:
                  isSelected ? theme.colorScheme.primary : theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isSelected ? theme.colorScheme.primary : Colors.grey),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : Colors.black)),
                Text(subtitle,
                    style: TextStyle(color: Colors.grey.shade600)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    String? errorText,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? prefixIcon,
    Widget? suffixIcon,
    int? maxLines = 1,
    bool enabled = true,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLines: maxLines,
          enabled: enabled && !_isLoading,
          readOnly: readOnly,
          onTap: onTap,
          decoration: InputDecoration(
            labelText: labelText,
            hintText: hintText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            filled: true,
            fillColor: theme.colorScheme.surface,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: errorText != null ? Colors.red : theme.colorScheme.primary,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 12),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    errorText,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    if (_passwordController.text.isEmpty) return const SizedBox.shrink();
    
    String strengthText;
    Color strengthColor;
    
    if (_passwordStrength <= 2) {
      strengthText = "Débil";
      strengthColor = Colors.red;
    } else if (_passwordStrength == 3) {
      strengthText = "Regular";
      strengthColor = Colors.orange;
    } else if (_passwordStrength == 4) {
      strengthText = "Buena";
      strengthColor = Colors.green;
    } else {
      strengthText = "Excelente";
      strengthColor = Colors.green.shade600;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Seguridad",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              strengthText,
              style: TextStyle(
                fontSize: 12,
                color: strengthColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(3),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: _passwordStrength / 5,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: [
            _buildRequirementItem("Al menos 8 caracteres", _passwordCriteria[0]),
            _buildRequirementItem("Una letra minúscula (a-z)", _passwordCriteria[1]),
            _buildRequirementItem("Una letra mayúscula (A-Z)", _passwordCriteria[2]),
            _buildRequirementItem("Un número (0-9)", _passwordCriteria[3]),
            _buildRequirementItem("Un símbolo (!@#\$%^&*)", _passwordCriteria[4]),
          ],
        ),
      ],
    );
  }

  Widget _buildRequirementItem(String text, bool met) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: met ? Colors.green : Colors.grey.shade400,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: met ? Colors.grey.shade700 : Colors.grey.shade500,
                fontWeight: met ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfo() {
    return Column(
      children: [
        _buildTextField(
          controller: _fullNameController,
          labelText: _selectedType == "Cliente"
              ? "Nombre completo"
              : "Nombre del representante",
          errorText: _fullNameError,
          prefixIcon: const Icon(Icons.person_outline),
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _emailController,
          labelText: "Correo electrónico",
          hintText: "ejemplo@correo.com",
          errorText: _emailError,
          keyboardType: TextInputType.emailAddress,
          prefixIcon: const Icon(Icons.email_outlined),
        ),
        const SizedBox(height: 20),
        Column(
          children: [
            _buildTextField(
              controller: _passwordController,
              labelText: "Contraseña",
              errorText: _passwordError,
              obscureText: _obscurePassword,
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: _isLoading ? null : () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            _buildPasswordStrengthIndicator(),
          ],
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _confirmPasswordController,
          labelText: "Confirmar contraseña",
          errorText: _confirmPasswordError,
          obscureText: _obscureConfirmPassword,
          prefixIcon: const Icon(Icons.lock_outlined),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
            onPressed: _isLoading ? null : () {
              setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outline),
                borderRadius: BorderRadius.circular(16),
                color: theme.colorScheme.surface,
              ),
              child: CountryCodePicker(
                onChanged: (country) {
                  setState(() {
                    _selectedDialCode = country.dialCode ?? "+57";
                  });
                },
                initialSelection: 'CO',
                favorite: ['+57'],
                showFlag: true,
                showDropDownButton: true,
                alignLeft: false,
                enabled: !_isLoading,
                flagWidth: 25,
                padding: const EdgeInsets.symmetric(horizontal: 0),
                textStyle: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTextField(
                controller: _phoneController,
                labelText: "Teléfono",
                errorText: _phoneError,
                keyboardType: TextInputType.phone,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildClientFinalStep() {
    return Column(
      children: [
        _buildPhoneField(),
        const SizedBox(height: 20),
        _buildTermsCheckbox(),
      ],
    );
  }

  Widget _buildBusinessFinalStep() {
    return Column(
      children: [
        _buildTextField(
          controller: _businessNameController,
          labelText: "Nombre del negocio",
          errorText: _businessNameError,
          prefixIcon: const Icon(Icons.store_outlined),
        ),
        const SizedBox(height: 20),
        BusinessTypeSelector(
          selectedTypeId: _selectedBusinessTypeId,
          onChanged: (typeId, typeName) {
            setState(() {
              _selectedBusinessTypeId = typeId;
            });
          },
          enabled: !_isLoading,
          errorText: _selectedBusinessTypeId == null
              ? "Selecciona el tipo de negocio"
              : null,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _nitController,
          labelText: "NIT / Documento",
          errorText: _nitError,
          keyboardType: TextInputType.number,
          prefixIcon: const Icon(Icons.numbers),
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _addressController,
          labelText: "Dirección",
          errorText: _addressError,
          readOnly: true,
          prefixIcon: const Icon(Icons.location_on_outlined),
          suffixIcon: IconButton(
            icon: const Icon(Icons.map),
            onPressed: _isLoading ? null : _openMapForAddress,
          ),
          onTap: _isLoading ? null : _openMapForAddress,
        ),
        const SizedBox(height: 20),
        _buildPhoneField(),
        const SizedBox(height: 20),
        _buildTermsCheckbox(),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return CheckboxListTile(
      value: _termsAccepted,
      onChanged: _isLoading
          ? null
          : (val) => setState(() => _termsAccepted = val ?? false),
      title: const Text("Acepto los términos y condiciones"),
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: Theme.of(context).colorScheme.primary,
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildUserTypeSelection();
      case 1:
        return _buildAccountInfo();
      case 2:
        return _selectedType == "Cliente"
            ? _buildClientFinalStep()
            : _buildBusinessFinalStep();
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    int totalSteps = 3;
    bool isLastStep = _currentStep == totalSteps - 1;

    return Scaffold(
      appBar: AppBar(title: const Text("Crear cuenta")),
      body: SafeArea(
        child: Column(
          children: [
            _buildStepIndicator(),
            const SizedBox(height: 30),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SlideTransition(
                  position: _slideAnimation.drive(
                    Tween(begin: const Offset(0.3, 0), end: Offset.zero),
                  ),
                  child: FadeTransition(
                    opacity: _slideAnimation,
                    child: _buildCurrentStep(),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    SizedBox(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _previousStep,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        child: const Text("Atrás"),
                      ),
                    ),
                  const Spacer(),
                  SizedBox(
                    child: ElevatedButton(
                      onPressed: (_canProceed() && !_isLoading)
                          ? () {
                              if (isLastStep) {
                                _register();
                              } else {
                                _nextStep();
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.onPrimary,
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  isLastStep ? "Crear cuenta" : "Siguiente",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  isLastStep ? Icons.check : Icons.arrow_forward, 
                                  size: 18
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}