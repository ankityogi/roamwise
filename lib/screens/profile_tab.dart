import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/theme.dart';
import '../providers/auth_provider.dart';

class ProfileTab extends ConsumerStatefulWidget {
  const ProfileTab({super.key});

  @override
  ConsumerState<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<ProfileTab> {
  bool _offlineMode = false;

  @override
  Widget build(BuildContext context) {
    // Watch the authentication state from Riverpod
    final authState = ref.watch(authProvider);
    final user = authState.user;

    // Fallback local constants if user session data is not yet fully parsed
    final userName = user?.name ?? 'Adventurer';
    final userEmail = user?.email ?? 'explore@roamwise.com';
    final userAvatar = user?.profilePic ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&q=80';
    
    final tripsCount = user?.tripsCount ?? 0;
    final countriesCount = user?.countriesCount ?? 0;
    final savedCount = user?.savedItemsCount ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 12),
          // User Avatar with glowing gradient ring
          Center(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: CircleAvatar(
                radius: 54,
                backgroundImage: NetworkImage(userAvatar),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            userName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            userEmail,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          // User Stats Row loaded directly from MongoDB User model parameters
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard(tripsCount.toString(), 'Trips'),
              _buildStatCard(countriesCount.toString(), 'Countries'),
              _buildStatCard(savedCount.toString(), 'Saved'),
            ],
          ),
          const SizedBox(height: 32),

          // Preference Options & Settings list
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'App Preferences',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language, color: AppColors.accent),
                  title: const Text('Primary Language', style: TextStyle(color: AppColors.textPrimary)),
                  trailing: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('English', style: TextStyle(color: AppColors.textSecondary)),
                      Icon(Icons.chevron_right, color: AppColors.textSecondary),
                    ],
                  ),
                  onTap: () {},
                ),
                const Divider(height: 1, color: AppColors.cardBorder),
                SwitchListTile(
                  secondary: const Icon(Icons.offline_pin, color: AppColors.accent),
                  title: const Text('Offline Map Mode', style: TextStyle(color: AppColors.textPrimary)),
                  value: _offlineMode,
                  onChanged: (bool value) {
                    setState(() {
                      _offlineMode = value;
                    });
                  },
                  activeThumbColor: AppColors.accent,
                ),
                const Divider(height: 1, color: AppColors.cardBorder),
                ListTile(
                  leading: const Icon(Icons.security, color: AppColors.accent),
                  title: const Text('Security & Privacy', style: TextStyle(color: AppColors.textPrimary)),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Account Options
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text('Sign Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  onTap: () async {
                    // Call the logout function in Riverpod authProvider
                    await ref.read(authProvider.notifier).logout();
                    
                    if (context.mounted) {
                      // Navigate back to the authorization/login screen
                      Navigator.of(context).pushReplacementNamed('/auth');
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
