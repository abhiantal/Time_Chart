// lib/features/settings/screen/appearance_settings_screen.dart

import 'package:flutter/material.dart' hide ThemeMode, ColorScheme;
import 'package:provider/provider.dart';
import '../models/settings_model.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_widgets.dart';

class AppearanceSettingsScreen extends StatelessWidget {
  const AppearanceSettingsScreen({super.key});


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: AppBar(title: const Text('Appearance'), centerTitle: true),
        body: Consumer<SettingsProvider>(
          builder: (context, provider, child) {
            return ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [


                // Theme Mode
                const SettingsSectionHeader(
                  title: 'Theme',
                  icon: Icons.dark_mode_outlined,
                ),
                SettingsCard(
                  children: [
                    SettingsRadioTile<ThemeMode>(
                      icon: Icons.wb_sunny_outlined,
                      title: 'Light',
                      subtitle: 'Always use light theme',
                      value: ThemeMode.light,
                      groupValue: provider.themeMode,
                      onChanged: (value) => provider.setThemeMode(value!),
                    ),
                    SettingsRadioTile<ThemeMode>(
                      icon: Icons.dark_mode_outlined,
                      title: 'Dark',
                      subtitle: 'Always use dark theme',
                      value: ThemeMode.dark,
                      groupValue: provider.themeMode,
                      onChanged: (value) => provider.setThemeMode(value!),
                    ),
                    SettingsRadioTile<ThemeMode>(
                      icon: Icons.settings_suggest_outlined,
                      title: 'System',
                      subtitle: 'Follow system settings',
                      value: ThemeMode.system,
                      groupValue: provider.themeMode,
                      onChanged: (value) => provider.setThemeMode(value!),
                    ),
                  ],
                ),

                // Typography
                const SettingsSectionHeader(
                  title: 'App Typography',
                  icon: Icons.text_format_outlined,
                ),
                SettingsCard(
                  children: [
                    SettingsDropdownTile<String>(
                      icon: Icons.font_download_outlined,
                      title: 'Font Family',
                      value: provider.appearance.fontFamily,
                      items: const [
                        DropdownMenuItem(value: 'system', child: Text('System Default')),
                        DropdownMenuItem(value: 'Inter', child: Text('Inter (Modern)')),
                        DropdownMenuItem(value: 'Poppins', child: Text('Poppins (Geometric)')),
                        DropdownMenuItem(value: 'Roboto', child: Text('Roboto (Classic)')),
                        DropdownMenuItem(value: 'Lato', child: Text('Lato (Elegant)')),
                        DropdownMenuItem(value: 'Montserrat', child: Text('Montserrat (Clean)')),
                        DropdownMenuItem(value: 'Open Sans', child: Text('Open Sans (Readable)')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          provider.updateAppearance(
                            provider.appearance.copyWith(fontFamily: value),
                          );
                        }
                      },
                    ),
                  ],
                ),

                // Font Size
                const SettingsSectionHeader(
                  title: 'Font Size',
                  icon: Icons.format_size_outlined,
                ),
                SettingsCard(
                  children: [
                    SettingsChoiceChips<FontSize>(
                      title: 'Text size',
                      subtitle: 'Adjust the size of text throughout the app',
                      value: provider.appearance.fontSize,
                      choices: const [
                        SettingsChoice(value: FontSize.small, label: 'Small'),
                        SettingsChoice(value: FontSize.medium, label: 'Medium'),
                        SettingsChoice(value: FontSize.large, label: 'Large'),
                        SettingsChoice(
                          value: FontSize.extraLarge,
                          label: 'Extra Large',
                        ),
                      ],
                      onChanged: (value) => provider.setFontSize(value),
                    ),
                  ],
                ),

                // Display Options
                const SettingsSectionHeader(
                  title: 'Display',
                  icon: Icons.visibility_outlined,
                ),
                SettingsCard(
                  children: [
                    SettingsSwitchTile(
                      icon: Icons.view_compact_outlined,
                      title: 'Compact mode',
                      subtitle: 'Show more content on screen',
                      value: provider.appearance.compactMode,
                      onChanged: (value) {
                        provider.updateAppearance(
                          provider.appearance.copyWith(compactMode: value),
                        );
                      },
                    ),
                    SettingsSwitchTile(
                      icon: Icons.animation_outlined,
                      title: 'Reduce motion',
                      subtitle: 'Minimize animations',
                      value: provider.appearance.reduceMotion,
                      onChanged: (value) {
                        provider.updateAppearance(
                          provider.appearance.copyWith(reduceMotion: value),
                        );
                      },
                    ),
                    SettingsSwitchTile(
                      icon: Icons.contrast_outlined,
                      title: 'High contrast',
                      subtitle: 'Increase visibility',
                      value: provider.appearance.highContrast,
                      onChanged: (value) {
                        provider.updateAppearance(
                          provider.appearance.copyWith(highContrast: value),
                        );
                      },
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

}
