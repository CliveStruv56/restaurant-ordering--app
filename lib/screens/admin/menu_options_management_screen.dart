import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/option_group.dart';
import '../../services/menu_service.dart';
import '../../services/user_service.dart';

class MenuOptionsManagementScreen extends StatefulWidget {
  const MenuOptionsManagementScreen({Key? key}) : super(key: key);

  @override
  State<MenuOptionsManagementScreen> createState() => _MenuOptionsManagementScreenState();
}

class _MenuOptionsManagementScreenState extends State<MenuOptionsManagementScreen> {
  final MenuService _menuService = MenuService();
  final UserService _userService = UserService();
  
  List<OptionGroup> _optionGroups = [];
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

      print('[DEBUG AdminScreen] Starting to load option groups...');
      
      // Load option groups
      final groups = await _menuService.getOptionGroups();

      print('[DEBUG AdminScreen] Loaded ${groups.length} option groups');
      for (final group in groups) {
        print('[DEBUG AdminScreen] Group: ${group.name} (ID: ${group.id})');
      }

      setState(() {
        _optionGroups = groups;
        _isLoading = false;
      });
      
      print('[DEBUG AdminScreen] UI updated with ${_optionGroups.length} groups');
    } catch (e) {
      print('[ERROR AdminScreen] Failed to load data: $e');
      print('[ERROR AdminScreen] Error type: ${e.runtimeType}');
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

  void _showAddEditGroupDialog([OptionGroup? group]) {
    final nameController = TextEditingController(text: group?.name);
    final descriptionController = TextEditingController(text: group?.description);
    String selectionType = group?.selectionType ?? 'single';
    bool isRequired = group?.isRequired ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(group == null ? 'Add Option Group' : 'Edit Option Group'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Group Name',
                    hintText: 'e.g., Milk Types, Sizes',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectionType,
                  decoration: const InputDecoration(
                    labelText: 'Selection Type',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'single', child: Text('Single Selection')),
                    DropdownMenuItem(value: 'multiple', child: Text('Multiple Selection')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectionType = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Required'),
                  subtitle: const Text('Customer must select from this group'),
                  value: isRequired,
                  onChanged: (value) {
                    setDialogState(() {
                      isRequired = value;
                    });
                  },
                ),
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
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a group name'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  print('[DEBUG AdminDialog] Attempting to create/update option group');
                  print('[DEBUG AdminDialog] Name: ${nameController.text.trim()}');
                  print('[DEBUG AdminDialog] Selection Type: $selectionType');
                  print('[DEBUG AdminDialog] Is Required: $isRequired');
                  
                  if (group == null) {
                    print('[DEBUG AdminDialog] Creating new option group...');
                    final result = await _menuService.createOptionGroup(
                      name: nameController.text.trim(),
                      description: descriptionController.text.trim(),
                      selectionType: selectionType,
                      isRequired: isRequired,
                    );
                    print('[DEBUG AdminDialog] Created option group with ID: ${result.id}');
                  } else {
                    await _menuService.updateOptionGroup(
                      id: group.id,
                      name: nameController.text.trim(),
                      description: descriptionController.text.trim(),
                      selectionType: selectionType,
                      isRequired: isRequired,
                    );
                  }

                  Navigator.pop(context);
                  print('[DEBUG AdminDialog] Successfully saved, now reloading data...');
                  await _loadData();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(group == null ? 'Option group created successfully!' : 'Option group updated successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  print('[ERROR AdminDialog] Failed to save: $e');
                  print('[ERROR AdminDialog] Error details: ${e.toString()}');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error saving option group: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text(group == null ? 'Add' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteGroup(OptionGroup group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Option Group'),
        content: Text('Are you sure you want to delete "${group.name}"? This will also delete all options in this group.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _menuService.deleteOptionGroup(group.id);
        await _loadData();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Option group deleted'),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Options Management'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/admin');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: () {
              context.go('/admin/category-options');
            },
            tooltip: 'Assign to Categories',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _optionGroups.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.tune, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No option groups yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Add option groups to configure menu customizations',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _showAddEditGroupDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Add First Group'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _optionGroups.length,
                  itemBuilder: (context, index) {
                    final group = _optionGroups[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ExpansionTile(
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                group.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Chip(
                              label: Text(
                                group.selectionType == 'single' ? 'Single' : 'Multiple',
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor: group.selectionType == 'single' 
                                  ? Colors.blue[100] 
                                  : Colors.green[100],
                            ),
                            const SizedBox(width: 8),
                            if (group.isRequired)
                              Chip(
                                label: const Text(
                                  'Required',
                                  style: TextStyle(fontSize: 12, color: Colors.white),
                                ),
                                backgroundColor: Colors.red,
                              ),
                          ],
                        ),
                        subtitle: group.description != null 
                            ? Text(group.description!)
                            : null,
                        children: [
                          // Options list
                          if (group.options.isNotEmpty) ...[
                            const Divider(),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Options:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...group.options.map((option) => ListTile(
                                    leading: option.iconUrl != null
                                        ? Image.network(
                                            option.iconUrl!,
                                            width: 24,
                                            height: 24,
                                            errorBuilder: (_, __, ___) => 
                                                const Icon(Icons.circle, size: 24),
                                          )
                                        : const Icon(Icons.circle, size: 24),
                                    title: Text(option.name),
                                    subtitle: option.description != null
                                        ? Text(option.description!)
                                        : null,
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (option.priceAdjustment != 0)
                                          Text(
                                            option.priceAdjustment > 0
                                                ? '+\$${option.priceAdjustment.toStringAsFixed(2)}'
                                                : '-\$${(-option.priceAdjustment).toStringAsFixed(2)}',
                                            style: TextStyle(
                                              color: option.priceAdjustment > 0
                                                  ? Colors.green
                                                  : Colors.red,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        if (option.isDefault)
                                          Container(
                                            margin: const EdgeInsets.only(left: 8),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.orange,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Text(
                                              'Default',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  )),
                                ],
                              ),
                            ),
                          ],
                          
                          // Action buttons
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () {
                                    context.go('/admin/menu-options/${group.id}');
                                  },
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Manage Options'),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: () => _showAddEditGroupDialog(group),
                                  icon: const Icon(Icons.settings),
                                  label: const Text('Edit Group'),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: () => _deleteGroup(group),
                                  icon: const Icon(Icons.delete),
                                  label: const Text('Delete'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: _optionGroups.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _showAddEditGroupDialog(),
              backgroundColor: Colors.red[700],
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}