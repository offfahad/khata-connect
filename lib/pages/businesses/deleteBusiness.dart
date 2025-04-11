import 'package:flutter/material.dart';
import 'package:khata_connect/main.dart';
import '../../blocs/businessBloc.dart';
import '../../helpers/appLocalizations.dart';
import '../../providers/stateNotifier.dart';
import '../../models/business.dart';

class DeleteBusiness extends StatefulWidget {
  const DeleteBusiness({super.key});

  @override
  _DeleteBusinessState createState() => _DeleteBusinessState();
}

class _DeleteBusinessState extends State<DeleteBusiness> {
  final BusinessBloc _businessBloc = BusinessBloc();
  List<Business> _businesses = [];
  int _selectedIndex = 0;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadBusinesses();
  }

  Future<void> _loadBusinesses() async {
    if (!mounted) return;
    final businesses = await _businessBloc.getBusinesss();
    if (mounted) {
      setState(() => _businesses = businesses);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: Text(
          AppLocalizations.of(context)!.translate('deleteCompany'),
          style: TextStyle(color: colorScheme.onSurface),
        ),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBody(colorScheme, theme),
      bottomNavigationBar:
          SafeArea(child: _buildBottomAppBar(context, colorScheme)),
    );
  }

  Widget _buildBody(ColorScheme colorScheme, ThemeData theme) {
    if (_businesses.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: colorScheme.primary),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ListView.separated(
              itemCount: _businesses.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 16, thickness: 1),
              itemBuilder: (context, index) {
                final business = _businesses[index];
                return _buildBusinessTile(business, index, colorScheme, theme);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessTile(
      Business business, int index, ColorScheme colorScheme, ThemeData theme) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Radio<int>(
        value: index,
        groupValue: _selectedIndex,
        fillColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.onSurface.withOpacity(0.6);
        }),
        onChanged: (value) => setState(() => _selectedIndex = value!),
      ),
      title: Text(
        business.companyName ?? 'Unnamed Business',
        style: theme.textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: business.address?.isNotEmpty == true
          ? Text(
              business.address!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onTap: () => setState(() => _selectedIndex = index),
    );
  }

  Widget _buildBottomAppBar(BuildContext context, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: _isDeleting ? null : _confirmDelete,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.error,
          foregroundColor: colorScheme.onError,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isDeleting
            ? const CircularProgressIndicator()
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.translate('deleteCompany'),
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(context)!.translate('confirmDelete'),
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        content: Text(
          AppLocalizations.of(context)!.translate('deleteCompanyWarning'),
          style:
              TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              AppLocalizations.of(context)!.translate('cancel'),
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(AppLocalizations.of(context)!.translate('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteCompany();
    }
  }

  Future<void> _deleteCompany() async {
    setState(() => _isDeleting = true);
    try {
      final id = _businesses[_selectedIndex].id!;
      if (id == 0) return;

      await _businessBloc.deleteBusinessById(id);
      changeSelectedBusiness(context, 0);

      if (!mounted) return;
      Navigator.of(context).pop();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MyHomePage()),
      );
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  void dispose() {
    _businessBloc.dispose();
    super.dispose();
  }
}
