import 'package:flutter/material.dart';

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
    
    // Add listeners to text controllers to update button state
    _emailController.addListener(_updateButtonState);
    _passwordController.addListener(_updateButtonState);
    _confirmPasswordController.addListener(_updateButtonState);
    _businessNameController.addListener(_updateButtonState);
    _nitController.addListener(_updateButtonState);
    _addressController.addListener(_updateButtonState);
    _phoneController.addListener(_updateButtonState);
    _descriptionController.addListener(_updateButtonState);
  }

  @override
  void dispose() {
    // Remove listeners before disposing
    _emailController.removeListener(_updateButtonState);
    _passwordController.removeListener(_updateButtonState);
    _confirmPasswordController.removeListener(_updateButtonState);
    _businessNameController.removeListener(_updateButtonState);
    _nitController.removeListener(_updateButtonState);
    _addressController.removeListener(_updateButtonState);
    _phoneController.removeListener(_updateButtonState);
    _descriptionController.removeListener(_updateButtonState);
    
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

  void _updateButtonState() {
    setState(() {
      // This will trigger a rebuild and update the button state
    });
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
        // Final step for both Cliente and Negocio - always require terms acceptance
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

  Widget _buildStepIndicator() {
    final theme = Theme.of(context);
    // Both Cliente and Negocio now have 3 steps total
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
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Text(
          "¿Cómo quieres usar la app?",
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        
        _buildTypeCard(
          type: "Cliente",
          title: "Soy Cliente",
          subtitle: "Quiero descubrir y conectar con negocios locales",
          icon: Icons.person_outline,
          theme: theme,
        ),
        const SizedBox(height: 16),
        
        _buildTypeCard(
          type: "Negocio",
          title: "Tengo un Negocio",
          subtitle: "Quiero hacer mi negocio más visible y conectar con clientes",
          icon: Icons.store_outlined,
          theme: theme,
        ),
      ],
    );
  }

  Widget _buildTypeCard({
    required String type,
    required String title,
    required String subtitle,
    required IconData icon,
    required ThemeData theme,
  }) {
    bool isSelected = _selectedType == type;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected 
              ? theme.colorScheme.primary 
              : theme.colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          color: isSelected 
            ? theme.colorScheme.primary.withValues(alpha: 0.1)
            : theme.colorScheme.surface,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected 
                  ? theme.colorScheme.primary.withValues(alpha: 0.2)
                  : theme.colorScheme.outline.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected 
                  ? theme.colorScheme.primary 
                  : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected 
                        ? theme.colorScheme.primary 
                        : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountInfo() {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Información de la cuenta",
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: "Correo electrónico",
            hintText: "ejemplo@correo.com",
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: "Contraseña",
            prefixIcon: const Icon(Icons.lock_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        TextField(
          controller: _confirmPasswordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: "Confirmar contraseña",
            prefixIcon: const Icon(Icons.lock_outline),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            errorText: _passwordController.text != _confirmPasswordController.text && 
                      _confirmPasswordController.text.isNotEmpty
              ? "Las contraseñas no coinciden"
              : null,
          ),
        ),
      ],
    );
  }

  Widget _buildClientFinalStep() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Información de contacto",
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),

        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: "Teléfono de contacto",
            prefixIcon: const Icon(Icons.phone_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 24),

        _buildTermsCheckbox(),
      ],
    );
  }

  Widget _buildBusinessFinalStep() {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Información del negocio",
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        
        TextField(
          controller: _businessNameController,
          decoration: InputDecoration(
            labelText: "Nombre del negocio",
            prefixIcon: const Icon(Icons.store_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        TextField(
          controller: _nitController,
          decoration: InputDecoration(
            labelText: "NIT / Documento",
            prefixIcon: const Icon(Icons.badge_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        TextField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: "Descripción del negocio",
            hintText: "Cuéntanos brevemente sobre tu negocio...",
            prefixIcon: const Icon(Icons.description_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        TextField(
          controller: _addressController,
          decoration: InputDecoration(
            labelText: "Dirección del negocio",
            prefixIcon: const Icon(Icons.location_on_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: "Teléfono de contacto",
            prefixIcon: const Icon(Icons.phone_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        _buildTermsCheckbox(),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    final theme = Theme.of(context);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _termsAccepted,
          onChanged: (val) {
            setState(() => _termsAccepted = val ?? false);
          },
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() => _termsAccepted = !_termsAccepted);
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: RichText(
                text: TextSpan(
                  style: theme.textTheme.bodyMedium,
                  children: [
                    const TextSpan(text: "Acepto los "),
                    TextSpan(
                      text: "términos y condiciones",
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const TextSpan(text: " y la "),
                    TextSpan(
                      text: "política de privacidad",
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
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
    // Both user types now have 3 steps total
    int totalSteps = 3;
    bool isLastStep = _currentStep == totalSteps - 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Crear cuenta"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
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
            
            // Navigation buttons
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: _previousStep,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("Atrás"),
                      ),
                    ),
                  
                  if (_currentStep > 0) const SizedBox(width: 16),
                  
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _canProceed() 
                        ? () {
                            if (isLastStep) {
                              // Complete registration
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("¡Cuenta creada exitosamente!"),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              _nextStep();
                            }
                          }
                        : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isLastStep ? "Crear cuenta" : "Siguiente",
                        style: const TextStyle(fontWeight: FontWeight.w600),
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
  }
}