import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_provider.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? AppTheme.backgroundDark : Colors.grey[50]!;
    final cardColor = isDarkMode ? AppTheme.cardDark : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final secondaryTextColor = isDarkMode ? AppTheme.textSecondary : Colors.black54;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Appearance', style: TextStyle(color: textColor)),
        backgroundColor: isDarkMode ? AppTheme.primaryGradientStart : Colors.white,
        iconTheme: IconThemeData(color: textColor),
        elevation: 0,
      ),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Theme',
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Dark Mode Option
              _buildThemeOption(
                context,
                title: 'Dark Mode',
                subtitle: 'Use dark theme for better visibility',
                icon: Icons.dark_mode,
                isSelected: themeProvider.isDarkMode,
                onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                cardColor: cardColor,
                textColor: textColor,
                secondaryTextColor: secondaryTextColor,
              ),

              const SizedBox(height: 12),

              // Light Mode Option
              _buildThemeOption(
                context,
                title: 'Light Mode',
                subtitle: 'Use light theme for daytime use',
                icon: Icons.light_mode,
                isSelected: !themeProvider.isDarkMode,
                onTap: () => themeProvider.setThemeMode(ThemeMode.light),
                cardColor: cardColor,
                textColor: textColor,
                secondaryTextColor: secondaryTextColor,
              ),

              const SizedBox(height: 32),

              Text(
                'Display',
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Font Size (Coming Soon)
              _buildSettingCard(
                context,
                title: 'Font Size',
                subtitle: 'Adjust text size',
                icon: Icons.text_fields,
                trailing: Text(
                  'Medium',
                  style: TextStyle(color: secondaryTextColor),
                ),
                cardColor: cardColor,
                textColor: textColor,
                secondaryTextColor: secondaryTextColor,
              ),

              const SizedBox(height: 12),

              // Animation (Coming Soon)
              _buildSettingCard(
                context,
                title: 'Animations',
                subtitle: 'Enable smooth transitions',
                icon: Icons.animation,
                trailing: Switch(
                  value: true,
                  onChanged: null,
                  activeColor: AppTheme.successColor,
                ),
                cardColor: cardColor,
                textColor: textColor,
                secondaryTextColor: secondaryTextColor,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required Color cardColor,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryGradientStart
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryGradientStart.withOpacity(0.2)
                    : cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? AppTheme.primaryGradientStart
                    : secondaryTextColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppTheme.successColor,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    Widget? trailing,
    required Color cardColor,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: secondaryTextColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}
