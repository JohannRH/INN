import 'package:flutter/material.dart';
import '../models/business.dart';
import '../components/business_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/session.dart';
import './login_page.dart';
import './edit_profile_page.dart';
import '../services/user_cache.dart';

class ProfilePage extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const ProfilePage({
    super.key,
    required this.toggleTheme,
    required this.isDarkMode,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _session;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final session = await SessionService.getSession();
    if (session == null) return;

    // Load cache
    final cachedProfile = await UserCache.getProfile();
    if (cachedProfile != null) {
      session["user"].addAll(cachedProfile);
      if (mounted) {
        setState(() => _session = session);
      }
      
      // Check if cache is recent
      final isCacheRecent = await UserCache.isCacheRecent();
      if (isCacheRecent) {
        return;
      }
    }

    // Call Supabase to get complete profile data
    final userId = session["user"]["id"];
    final response = await Supabase.instance.client
        .from("profiles")
        .select("id,name,email,role,avatar_url,phone")
        .eq("id", userId)
        .maybeSingle();

    if (response != null) {
      session["user"].addAll(response);
      await UserCache.saveProfile(response);
      
      // Also fetch and cache business data if user is business
      if (response["role"] == "negocio") {
        final business = await Supabase.instance.client
            .from("businesses")
            .select("id,name,nit,address,description,logo_url,latitude,longitude,type_id,opening_hours,user_id")
            .eq("user_id", userId)
            .maybeSingle();
        
        if (business != null) {
          await UserCache.saveBusiness(business);
        }
      }
    }

    if (!mounted) return;
    setState(() => _session = session);
  }

  Future<List<Business>> fetchFavoriteBusinesses() async {
    final response = await Supabase.instance.client
        .from('businesses')
        .select()
        .limit(2);

    final data = response as List<dynamic>;
    return data.map((json) => Business.fromJson(json)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final userName = _session?['user']?['name'] ?? 'Guest';
    final userEmail = _session?['user']?['email'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            onPressed: () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfilePage()),
              );

              if (updated == true) {
                _loadSession();
              }
            },
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    backgroundImage: _session?['user']?['avatar_url'] != null
                        ? NetworkImage(_session!['user']!['avatar_url'])
                        : null,
                    child: _session?['user']?['avatar_url'] == null
                        ? const Icon(Icons.person, size: 40, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              userName,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (_session?['user']?['role'] == 'negocio')
                              const Icon(Icons.store, color: Colors.white, size: 20),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userEmail,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Settings Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildSettingsItem(
                    icon: Icons.brightness_6,
                    title: 'Theme',
                    subtitle: widget.isDarkMode ? 'Dark Mode' : 'Light Mode',
                    trailing: Switch(
                      value: widget.isDarkMode,
                      onChanged: (value) {
                        widget.toggleTheme();
                      },
                    ),
                  ),
                  _buildDivider(),
                  _buildSettingsItem(
                    icon: Icons.notifications,
                    title: 'Notifications',
                    subtitle: 'Manage your notifications'
                  ),
                  _buildDivider(),
                  _buildSettingsItem(
                    icon: Icons.privacy_tip,
                    title: 'Privacy Policy',
                    subtitle: 'Read our privacy policy'
                  ),
                  _buildDivider(),
                  _buildSettingsItem(
                    icon: Icons.help,
                    title: 'Help & Support',
                    subtitle: 'Get help and contact support'
                  ),
                  _buildDivider(),
                  _buildSettingsItem(
                    icon: Icons.local_offer,
                    title: 'Discounts',
                    subtitle: 'View available discounts'
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Favorite Businesses Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.favorite,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Favorite Businesses',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            
                          },
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                  ),
                  FutureBuilder<List<Business>>(
                    future: fetchFavoriteBusinesses(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text("Error loading favorites: ${snapshot.error}"),
                        );
                      }

                      final favorites = snapshot.data ?? [];

                      if (favorites.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.favorite_border,
                                  size: 48,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No favorite businesses yet',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      // mostrar solo 2 favoritos como preview
                      return Column(
                        children: favorites.take(2).map((b) => BusinessCard(business: b)).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Sign Out Button
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _showSignOutDialog();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Sign Out',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 56,
      endIndent: 16,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
    );
  }

  void _showSignOutDialog() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Sign Out'),
      content: const Text('Are you sure you want to sign out?'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            // Store the navigator before the async operation
            final navigator = Navigator.of(context);
            
            // Clear session and cache
            await Future.wait([
              SessionService.clearSession(),
              UserCache.clearAll(),
            ]);
            
            navigator.pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginPage()),
              (route) => false,
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Sign Out'),
        ),
      ],
    ),
  );
}
}