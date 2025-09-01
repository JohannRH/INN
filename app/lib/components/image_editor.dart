import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class ImageEditorDialog extends StatefulWidget {
  final File imageFile;
  final Function(File) onImageSaved;

  const ImageEditorDialog({
    super.key,
    required this.imageFile,
    required this.onImageSaved,
  });

  @override
  State<ImageEditorDialog> createState() => _ImageEditorDialogState();
}

class _ImageEditorDialogState extends State<ImageEditorDialog> {
  final GlobalKey _imageKey = GlobalKey();
  final TransformationController _transformationController = TransformationController();
  
  double _rotation = 0.0;
  double _scale = 1.0;
  bool _isLoading = false;

  void _rotateImage() {
    setState(() {
      _rotation += 90;
      if (_rotation >= 360) _rotation = 0;
    });
  }

  void _resetTransformations() {
    setState(() {
      _rotation = 0;
      _scale = 1.0;
      _transformationController.value = Matrix4.identity();
    });
  }

  Future<File> _saveEditedImage() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get the render boundary
      final RenderRepaintBoundary boundary = _imageKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      
      // Capture the image
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Save to temporary file
      final tempDir = Directory.systemTemp;
      final fileName = 'edited_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pngBytes);

      return file;
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _onSave() async {
    try {
      final editedFile = await _saveEditedImage();
      widget.onImageSaved(editedFile);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar la imagen: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    
    return Dialog(
      backgroundColor: theme.surface,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Editar Imagen',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: theme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: theme.onSurface),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Image Editor Area
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.outline.withValues(alpha: 0.3)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: RepaintBoundary(
                    key: _imageKey,
                    child: InteractiveViewer(
                      transformationController: _transformationController,
                      minScale: 0.5,
                      maxScale: 3.0,
                      onInteractionUpdate: (details) {
                        setState(() {
                          _scale = _transformationController.value.getMaxScaleOnAxis();
                        });
                      },
                      child: SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                        child: Transform.rotate(
                          angle: _rotation * (3.14159 / 180),
                          child: Image.file(
                            widget.imageFile,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Controls
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Scale Slider
                  Row(
                    children: [
                      Icon(Icons.zoom_out, color: theme.onSurface),
                      Expanded(
                        child: Slider(
                          value: _scale.clamp(0.5, 3.0),
                          min: 0.5,
                          max: 3.0,
                          divisions: 25,
                          activeColor: theme.primary,
                          onChanged: (value) {
                            setState(() {
                              _scale = value;
                              final currentTranslation = _transformationController.value.getTranslation();
                              _transformationController.value = Matrix4.identity()
                                ..translate(currentTranslation.x, currentTranslation.y)
                                ..scale(value);
                            });
                          },
                        ),
                      ),
                      Icon(Icons.zoom_in, color: theme.onSurface),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        icon: Icons.rotate_right,
                        label: 'Rotar',
                        onPressed: _rotateImage,
                        theme: theme,
                      ),
                      _buildActionButton(
                        icon: Icons.refresh,
                        label: 'Restablecer',
                        onPressed: _resetTransformations,
                        theme: theme,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary,
                  foregroundColor: theme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(theme.onPrimary),
                        ),
                      )
                    : const Text(
                        'Guardar Cambios',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required ColorScheme theme,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: theme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon, color: theme.primary),
            iconSize: 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: theme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }
}

class ProfileImageSelector extends StatefulWidget {
  final File? currentImage;
  final String? networkImageUrl;
  final Function(File) onImageSelected;
  final double radius;
  final String baseUrl;

  const ProfileImageSelector({
    super.key,
    this.currentImage,
    this.networkImageUrl,
    required this.onImageSelected,
    this.radius = 40,
    required this.baseUrl,
  });

  @override
  State<ProfileImageSelector> createState() => _ProfileImageSelectorState();
}

class _ProfileImageSelectorState extends State<ProfileImageSelector> {
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _selectedImage = widget.currentImage;
  }

  Future<void> _pickAndEditImage() async {
    // First, pick an image
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    
    if (pickedFile != null && mounted) {
      final imageFile = File(pickedFile.path);
      
      // Open the image editor
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => ImageEditorDialog(
          imageFile: imageFile,
          onImageSaved: (editedFile) {
            setState(() {
              _selectedImage = editedFile;
            });
            widget.onImageSelected(editedFile);
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    
    return GestureDetector(
      onTap: _pickAndEditImage,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  theme.primary,
                  theme.primary.withValues(alpha: 0.7),
                ],
              ),
            ),
            child: CircleAvatar(
              radius: widget.radius,
              backgroundColor: theme.surface,
              backgroundImage: _selectedImage != null
                  ? FileImage(_selectedImage!)
                  : (widget.networkImageUrl != null && widget.networkImageUrl!.isNotEmpty
                      ? NetworkImage(widget.baseUrl + widget.networkImageUrl!)
                      : null),
              child: _selectedImage == null && 
                     (widget.networkImageUrl == null || widget.networkImageUrl!.isEmpty)
                  ? Icon(
                      Icons.person, 
                      size: widget.radius, 
                      color: theme.primary,
                    )
                  : null,
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.surface,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.camera_alt,
                size: 20,
                color: theme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
