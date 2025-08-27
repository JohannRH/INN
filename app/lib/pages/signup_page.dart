import 'package:flutter/material.dart';
import '../services/auth.dart';
import '../main.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> with TickerProviderStateMixin {
  int _currentStep = 0;
  String? _selectedType;
  bool _termsAccepted = false;

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _nitController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();

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
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _businessNameController.dispose();
    _nitController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_canProceed()) {
      setState(() {
        _currentStep++;
      });
      _animationController.reset();
      _animationController.forward();
    }
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
            _passwordController.text == _confirmPasswordController.text;
      case 2:
        if (_selectedType == "Cliente") {
          return _phoneController.text.isNotEmpty && _termsAccepted;
        } else {
          return _businessNameController.text.isNotEmpty &&
              _nitController.text.isNotEmpty &&
              _addressController.text.isNotEmpty &&
              _phoneController.text.isNotEmpty &&
              _termsAccepted;
        }
      default:
        return true;
    }
  }

  /// 🔹 Aquí agregamos la lógica real de registro
  Future<void> _register() async {
    final body = {
      "email": _emailController.text.trim(),
      "password": _passwordController.text.trim(),
      "role": _selectedType?.toLowerCase(), // "cliente" o "negocio"
      "phone": _phoneController.text.trim(),
      if (_selectedType == "Negocio") ...{
        "business_name": _businessNameController.text.trim(),
        "nit": _nitController.text.trim(),
        "address": _addressController.text.trim(),
        "description": _descriptionController.text.trim(),
      }
    };

    try {
      final result = await _authService.register(body);

      if (!mounted) return;

      // Ir a la pantalla principal
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MainScreen(
            toggleTheme: () {},
            isDarkMode: false,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
    }
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

  Widget _buildAccountInfo() {
    return Column(
      children: [
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(labelText: "Correo electrónico"),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: "Contraseña"),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirmPasswordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: "Confirmar contraseña"),
        ),
      ],
    );
  }

  Widget _buildClientFinalStep() {
    return Column(
      children: [
        TextField(
          controller: _phoneController,
          decoration: const InputDecoration(labelText: "Teléfono"),
        ),
        const SizedBox(height: 16),
        _buildTermsCheckbox(),
      ],
    );
  }

  Widget _buildBusinessFinalStep() {
    return Column(
      children: [
        TextField(
          controller: _businessNameController,
          decoration: const InputDecoration(labelText: "Nombre del negocio"),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nitController,
          decoration: const InputDecoration(labelText: "NIT / Documento"),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _addressController,
          decoration: const InputDecoration(labelText: "Dirección"),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _phoneController,
          decoration: const InputDecoration(labelText: "Teléfono"),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _descriptionController,
          decoration: const InputDecoration(labelText: "Descripción"),
        ),
        const SizedBox(height: 16),
        _buildTermsCheckbox(),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return CheckboxListTile(
      value: _termsAccepted,
      onChanged: (val) => setState(() => _termsAccepted = val ?? false),
      title: const Text("Acepto los términos y condiciones"),
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
    int totalSteps = 3;
    bool isLastStep = _currentStep == totalSteps - 1;

    return Scaffold(
      appBar: AppBar(title: const Text("Crear cuenta")),
      body: SafeArea(
        child: Column(
          children: [
            _buildStepIndicator(),
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
                    OutlinedButton(
                        onPressed: _previousStep, child: const Text("Atrás")),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _canProceed()
                        ? () {
                            if (isLastStep) {
                              _register(); // 🔹 ahora sí registra
                            } else {
                              _nextStep();
                            }
                          }
                        : null,
                    child:
                        Text(isLastStep ? "Crear cuenta" : "Siguiente"),
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
