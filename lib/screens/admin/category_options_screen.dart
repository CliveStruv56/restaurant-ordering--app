import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/option_group.dart';
import '../../services/menu_service.dart';
import '../../services/user_service.dart';

class CategoryOptionsScreen extends StatefulWidget {
  const CategoryOptionsScreen({Key? key}) : super(key: key);

  @override
  State<CategoryOptionsScreen> createState() => _CategoryOptionsScreenState();
}

class _CategoryOptionsScreenState extends State<CategoryOptionsScreen> {
  final MenuService _menuService = MenuService();
  final UserService _userService = UserService();
  
  List<Map<String, dynamic>> _categories = [];
  List<OptionGroup> _optionGroups = [];
  Map<String, List<String>> _categoryOptionGroups = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
  }

  Future<void> _checkAdminAccess() async {
    try {
      final isAdmin = await _userService.isAdmin();
      if (!isAdmin) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Access denied. Admin privileges required.'),
              backgroundColor: Colors.red,
            ),
          );
          context.go('/home');
        }
        return;
      }
      
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
        context.go('/home');
      }
    }
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final categories = await _menuService.getCategories();
      final optionGroups = await _menuService.getOptionGroups();
      final associations = await _menuService.getCategoryOptionAssociations();

      setState(() {
        _categories = categories;
        _optionGroups = optionGroups;
        _categoryOptionGroups = associations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAssignOptionsDialog(Map<String, dynamic> category) {
    final categoryId = category['id'] as String;
    final selectedGroups = List<String>.from(_categoryOptionGroups[categoryId] ?? []);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Assign Options to ${category['name']}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select which option groups should be available for items in this category:',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                ..._optionGroups.map((group) => CheckboxListTile(
                  title: Text(group.name),
                  subtitle: Text(
                    '${group.selectionType == 'single' ? 'Single' : 'Multiple'} selection'
                    '${group.isRequired ? ' (Required)' : ''}',
                  ),
                  value: selectedGroups.contains(group.id),
                  onChanged: (value) {
                    setDialogState(() {
                      if (value == true) {
                        selectedGroups.add(group.id);
                      } else {
                        selectedGroups.remove(group.id);
                      }
                    });
                  },
                )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _menuService.updateCategoryOptionGroups(
                    categoryId, 
                    selectedGroups,
                  );
                  
                  Navigator.pop(context);
                  await _loadData();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Options updated for category'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Option Assignment'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
              ? const Center(
                  child: Text('No categories found'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final categoryId = category['id'] as String;
                    final assignedGroups = _categoryOptionGroups[categoryId] ?? [];
                    final assignedOptionGroups = _optionGroups
                        .where((g) => assignedGroups.contains(g.id))
                        .toList();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ExpansionTile(
                        title: Text(
                          category['name'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '${assignedGroups.length} option group${assignedGroups.length == 1 ? '' : 's'} assigned',
                        ),
                        children: [
                          if (assignedOptionGroups.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'No options assigned to this category',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            )
                          else
                            ...assignedOptionGroups.map((group) => ListTile(
                              leading: Icon(
                                group.selectionType == 'single' 
                                    ? Icons.radio_button_checked 
                                    : Icons.check_box,
                                color: Colors.blue,
                              ),
                              title: Text(group.name),
                              subtitle: Text(
                                '${group.options.length} option${group.options.length == 1 ? '' : 's'}'
                                '${group.isRequired ? ' • Required' : ''}',
                              ),
                              dense: true,
                            )),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _showAssignOptionsDialog(category),
                                icon: const Icon(Icons.settings),
                                label: const Text('Configure Options'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}