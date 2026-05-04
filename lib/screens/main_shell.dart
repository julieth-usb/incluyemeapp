import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../main.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';
import 'auth_screen.dart';
import 'disabilities_list_screen.dart';
import 'home_screen.dart';
import 'strategies_screen.dart';
import '../widgets/app_logo.dart';
import '../widgets/disability_search_delegate.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  Uint8List? _profileBytes;
  String? _selectedEmoji;
  Color _avatarBgColor = AppColors.blue;
  final TextEditingController _phoneController = TextEditingController(text: '+57 300 000 0000');
  final TextEditingController _countryController = TextEditingController(text: 'Colombia');

  static const List<Widget> _pages = [
    HomeScreen(),
    DisabilitiesListScreen(),
    StrategiesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  elevation: 0,
  toolbarHeight: 72,
  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
  foregroundColor: Theme.of(context).colorScheme.onSurface,
  centerTitle: true,
  titleSpacing: 20,
  title: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const AppLogo(size: 32),
      const SizedBox(width: 8),
      Text(
        'Inclúyeme',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    ],
  ),
  leadingWidth: 120,
  leading: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        icon: const Icon(Icons.search_rounded, color: AppColors.blue),
        tooltip: 'Buscar discapacidad',
        onPressed: () {
          showSearch(
            context: context,
            delegate: DisabilitySearchDelegate(),
          );
        },
      ),
      ValueListenableBuilder<ThemeMode>(
        valueListenable: themeNotifier,
        builder: (context, mode, child) {
          final isDark = mode == ThemeMode.dark;
          return IconButton(
            icon: Icon(isDark ? Icons.nights_stay : Icons.wb_sunny, color: AppColors.blue),
            tooltip: 'Modo Día/Noche',
            onPressed: () {
              themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
            },
          );
        },
      ),
    ],
  ),
  actions: [
    Builder(
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: InkWell(
          onTap: () {
            Scaffold.of(context).openEndDrawer();
          },
          borderRadius: BorderRadius.circular(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: _avatarBgColor.withAlpha(50),
                backgroundImage: _profileBytes != null ? MemoryImage(_profileBytes!) : null,
                child: _profileBytes == null
                    ? (_selectedEmoji != null
                        ? Text(_selectedEmoji!, style: const TextStyle(fontSize: 18))
                        : Icon(Icons.person, size: 18, color: _avatarBgColor))
                    : null,
              ),
              const SizedBox(width: 6),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    FirebaseAuth.instance.currentUser?.email?.split('@').first ?? 'Docente',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.blue,
                      height: 1.2,
                    ),
                  ),
                  const Text(
                    'Docente Principal',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textMid,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
    Padding(
      padding: const EdgeInsets.only(right: 8),
      child: IconButton(
        icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
        tooltip: 'Salir',
        onPressed: _handleLogout,
      ),
    ),
  ],
),




      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeIn,
        switchOutCurve: Curves.easeOut,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        child: KeyedSubtree(
          key: ValueKey(_currentIndex),
          child: _pages[_currentIndex],
        ),
      ),
      endDrawer: _buildProfileDrawer(context),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Future<void> _handleLogout() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Cerrar sesión'),
          content: const Text('¿Quieres salir y volver a la pantalla de acceso?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Salir'),
            ),
          ],
        );
      },
    );

    if (shouldExit != true) return;

    await AuthService.logout();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const AuthScreen(),
        transitionsBuilder: (_, animation, __, child) {
          final curve = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          );
          return FadeTransition(opacity: curve, child: child);
        },
        transitionDuration: const Duration(milliseconds: 320),
      ),
      (route) => false,
    );
  }

  Widget _buildProfileDrawer(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'docente@incluyeme.com';
    final name = email.split('@').first;
    final isDark = themeNotifier.value == ThemeMode.dark;

    final avatarOptions = ['👨', '👩', '🧑‍🦱', '👩‍🦰', '🧔‍♂️', '👱‍♀️'];

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
      CircleAvatar(
        radius: 48,
        backgroundColor: _avatarBgColor.withAlpha(50),
        backgroundImage: _profileBytes != null ? MemoryImage(_profileBytes!) : null,
        child: _profileBytes == null
            ? (_selectedEmoji != null
                ? Text(_selectedEmoji!, style: const TextStyle(fontSize: 56))
                : Icon(Icons.person, size: 56, color: _avatarBgColor))
            : null,
      ),
                        GestureDetector(
                          onTap: () async {
                            final picker = ImagePicker();
                            final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                            if (pickedFile != null) {
                              final bytes = await pickedFile.readAsBytes();
                              setState(() => _profileBytes = bytes);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppColors.darkGreen,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('O elige un avatar:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: avatarOptions.map((emoji) {
                      final isSelected = _selectedEmoji == emoji;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedEmoji = emoji;
                            _profileBytes = null;
                          });
                        },
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: isSelected ? _avatarBgColor : Colors.grey.shade200,
                          child: Text(emoji, style: const TextStyle(fontSize: 24)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => _mostrarEstudioAvatar(context),
                    icon: const Icon(Icons.palette),
                    label: const Text('Estudio de Avatar (Creativo)'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.blue,
                      side: const BorderSide(color: AppColors.blue),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      name,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.blue),
                    ),
                  ),
                  const Center(
                    child: Text(
                      'Docente Principal',
                      style: TextStyle(fontSize: 14, color: AppColors.textMid, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(email, style: const TextStyle(fontSize: 15, color: Colors.grey)),
                  ),
                  const SizedBox(height: 24),
                  const Text('Información', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Número de Teléfono',
                      prefixIcon: Icon(Icons.phone_android),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _countryController,
                    decoration: const InputDecoration(
                      labelText: 'País / Ubicación',
                      prefixIcon: Icon(Icons.location_on),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Perfil guardado.')),
                  );
                },
                icon: const Icon(Icons.save),
                label: const Text('Guardar Cambios.'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: AppColors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarEstudioAvatar(BuildContext context) {
    final customEmojis = ['👨', '👩', '🧑‍🦱', '👩‍🦰', '🧔‍♂️', '👱‍♀️', '👨‍🦲', '👩‍🦲', '🧕', '👲', '🧑‍🎤', '👩‍🎤'];
    final colors = [AppColors.blue, AppColors.limeGreen, Colors.purple, Colors.orange, Colors.pink, Colors.teal];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('🎨 Estudio de Avatar', textAlign: TextAlign.center),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: _avatarBgColor.withAlpha(50),
                    child: Text(_selectedEmoji ?? '👨', style: const TextStyle(fontSize: 50)),
                  ),
                  const SizedBox(height: 24),
                  const Text('1. Elige tu estilo de cabello y género:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: customEmojis.map((emoji) {
                      return InkWell(
                        onTap: () {
                          setDialogState(() => _selectedEmoji = emoji);
                          setState(() {
                            _selectedEmoji = emoji;
                            _profileBytes = null;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _selectedEmoji == emoji ? Colors.grey.shade200 : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(emoji, style: const TextStyle(fontSize: 28)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  const Text('2. Color de fondo:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: colors.map((color) {
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() => _avatarBgColor = color);
                          setState(() => _avatarBgColor = color);
                        },
                        child: CircleAvatar(
 
                          backgroundColor: color,
                          child: _avatarBgColor == color ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('¡Listo!'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildNavBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.lightbulb_outline),
            selectedIcon: Icon(Icons.lightbulb_rounded),
            label: 'Estrategias',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'Novedades',
          ),
        ],
      ),
    );
  }
}

