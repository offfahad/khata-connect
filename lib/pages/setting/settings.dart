import 'package:flutter/material.dart';
import 'package:khata_connect/helpers/constants.dart';
import 'package:provider/provider.dart';
import 'package:share/share.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../helpers/appLocalizations.dart';
import '../../providers/my_theme_provider.dart';
import '../../providers/stateNotifier.dart';
import '../businesses/businessInformation.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeStatus = Provider.of<MyThemeProvider>(context);

    return Scaffold(
      body: Column(
        children: <Widget>[
          // Header Section
          Container(
            height: 150,
            decoration: const BoxDecoration(
              //color: theme.primaryColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: const Image(
                    image: AssetImage('assets/images/logo_crop.png'),
                    width: 200,
                    height: 100,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    AppLocalizations.of(context)!.translate('appInfo'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Settings List
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 10),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20)),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                  ),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
                    physics: const BouncingScrollPhysics(),
                    children: <Widget>[
                      // Theme Toggle
                      _buildSettingsItem(
                        context,
                        icon: Icon(
                          themeStatus.themeType
                              ? Icons.dark_mode_outlined
                              : Icons.light_mode_outlined,
                          size: 28,
                          color: theme.colorScheme.secondary,
                        ),
                        title: AppLocalizations.of(context)!.translate('theme'),
                        subtitle: AppLocalizations.of(context)!
                            .translate('themeSubtitle'),
                        trailing: Switch(
                          value: themeStatus.themeType,
                          onChanged: (value) => themeStatus.setTheme = value,
                          activeColor: theme.colorScheme.secondary,
                        ),
                      ),

                      // Business Information
                      _buildSettingsItem(
                        context,
                        icon: Image.asset(
                          "assets/images/business.png",
                          width: 28,
                          height: 28,
                          color: theme.colorScheme.secondary,
                        ),
                        title: AppLocalizations.of(context)!
                            .translate('businessInfo'),
                        subtitle: AppLocalizations.of(context)!
                            .translate('businessInfoMeta'),
                        onTap: () async {
                          final updatedBusinessInfo = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BusinessInformation(),
                            ),
                          );
                          if (updatedBusinessInfo != null) {
                            setState(() {});
                          }
                        },
                      ),

                      // Language Selection
                      _buildSettingsItem(
                        context,
                        icon: Image.asset(
                          "assets/images/lang.png",
                          width: 28,
                          height: 28,
                          color: theme.colorScheme.secondary,
                        ),
                        title: AppLocalizations.of(context)!
                            .translate('languageInfo'),
                        subtitle: AppLocalizations.of(context)!
                            .translate('languageInfoMeta'),
                        trailing: DropdownButton<String>(
                          dropdownColor: theme.cardColor,
                          icon: Icon(Icons.arrow_drop_down,
                              color: theme.colorScheme.secondary),
                          value:
                              Provider.of<AppStateNotifier>(context).appLocale,
                          onChanged: (String? newValue) async {
                            await changeLanguage(context, newValue!);
                          },
                          items: <String>["en", "ur"]
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Row(
                                children: [
                                  Image(
                                    image:
                                        AssetImage("assets/images/$value.png"),
                                    width: 18,
                                    //color: theme.colorScheme.onSurface,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    value == "en" ? "English" : "اردو",
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      // Currency Selection

                      _buildSettingsItem(
                        context,
                        icon: Image.asset(
                          "assets/images/currency.png",
                          width: 28,
                          height: 28,
                          color: theme.colorScheme.secondary,
                        ),
                        title: AppLocalizations.of(context)!
                            .translate('changeCurrency'),
                        subtitle: AppLocalizations.of(context)!
                            .translate('changeCurrencyMeta'),
                        trailing: Text(
                          Provider.of<AppStateNotifier>(context).currency,
                          style: TextStyle(
                            fontSize: 16,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        onTap: () => _showCurrencyBottomSheet(context),
                      ),

                      // Share App
                      // _buildSettingsItem(
                      //   context,
                      //   icon: Image.asset(
                      //     "assets/images/share.png",
                      //     width: 28,
                      //     height: 28,
                      //     color: theme.colorScheme.secondary,
                      //   ),
                      //   title: AppLocalizations.of(context)!
                      //       .translate('shareInfo'),
                      //   subtitle: AppLocalizations.of(context)!
                      //       .translate('shareInfoMeta'),
                      //   onTap: () {
                      //     Share.share(
                      //         'Check out my portfolio: https://offfahad.netlify.app');
                      //   },
                      //),

                      // Privacy Policy
                      _buildSettingsItem(
                        context,
                        icon: Icon(Icons.privacy_tip_outlined,
                            size: 30, color: theme.colorScheme.secondary),
                        title: AppLocalizations.of(context)!
                            .translate('privacyPolicy'),
                        subtitle: AppLocalizations.of(context)!
                            .translate('privacyPolicyMeta'),
                        onTap: () => _launchUrl(privacyPolicyUrl),
                      ),

                      // Terms of Use
                      _buildSettingsItem(
                        context,
                        icon: Icon(Icons.description_outlined,
                            size: 30, color: theme.colorScheme.secondary),
                        title: AppLocalizations.of(context)!
                            .translate('termsOfUse'),
                        subtitle: AppLocalizations.of(context)!
                            .translate('termsOfUseMeta'),
                        onTap: () => _launchUrl(termsOfUseUrl),
                      ),

                      _buildSettingsItem(
                        context,
                        icon: Icon(Icons.help_outline,
                            size: 30, color: theme.colorScheme.secondary),
                        title:
                            AppLocalizations.of(context)!.translate('support'),
                        subtitle: AppLocalizations.of(context)!
                            .translate('supportMeta'),
                        onTap: () => _launchUrl(portfolioUrl),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url),
        mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
    }
  }

// Add this new method to your class:
  Future<void> _showCurrencyBottomSheet(BuildContext context) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final notifier = Provider.of<AppStateNotifier>(context, listen: false);

    // Get current currency
    final prefs = await SharedPreferences.getInstance();
    String currentCurrency = prefs.getString('currency') ?? 'Rs';

    // Controller for text field
    final TextEditingController controller =
        TextEditingController(text: currentCurrency);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.translate('changeCurrency'),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: colorScheme.onSurface),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller,
              decoration: InputDecoration(
                labelText:
                    AppLocalizations.of(context)!.translate('currencySymbol'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colorScheme.surfaceVariant.withOpacity(0.4),
                prefixIcon:
                    Icon(Icons.currency_exchange, color: colorScheme.primary),
                hintText: 'Rs, \$, €, £, etc.',
              ),
              style: TextStyle(color: colorScheme.onSurface),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(context)!
                      .translate('currencyRequired');
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (controller.text.trim().isNotEmpty) {
                    final newCurrency = controller.text.trim();
                    await changeCurrency(context, newCurrency);
                    if (mounted) Navigator.pop(context);

                    // Show success feedback
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!
                              .translate('currencyUpdated'),
                        ),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: colorScheme.primary,
                ),
                child: Text(
                  AppLocalizations.of(context)!.translate('updateCurrency'),
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required Widget icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            if (theme.brightness == Brightness.light)
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            if (theme.brightness == Brightness.dark)
              BoxShadow(
                color: Colors.white.withOpacity(0.1),
                blurRadius: 2,
                offset: const Offset(0, 0),
              ),
          ],
        ),
        child: ListTile(
          leading: icon,
          title: Text(
            title,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          trailing: trailing,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          minVerticalPadding: 12,
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
