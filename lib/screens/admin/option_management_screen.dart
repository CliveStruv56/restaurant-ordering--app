import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/option_group.dart';
import '../../services/menu_service.dart';
import '../../services/user_service.dart';

class OptionManagementScreen extends StatefulWidget {
  final String optionGroupId;
  
  const OptionManagementScreen({
    Key? key,
    required this.optionGroupId,
  }) : super(key: key);

  @override
  State<OptionManagementScreen> createState() => _OptionManagementScreenState();
}

class _OptionManagementScreenState extends State<OptionManagementScreen> {
  final MenuService _menuService = MenuService();
  final UserService _userService = UserService();
  
  OptionGroup? _optionGroup;
  List<Option> _options = [];
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

      print('[DEBUG OptionManagement] Loading option group: ${widget.optionGroupId}');
      
      // Load option group with its options
      final optionGroup = await _menuService.getOptionGroupById(widget.optionGroupId);
      
      print('[DEBUG OptionManagement] Loaded option group: ${optionGroup.name}');
      print('[DEBUG OptionManagement] Found ${optionGroup.options.length} options');
      
      setState(() {
        _optionGroup = optionGroup;
        _options = optionGroup.options;
        _isLoading = false;
      });
    } catch (e) {
      print('[ERROR OptionManagement] Failed to load data: $e');
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

  void _showAddEditOptionDialog([Option? option]) {
    final nameController = TextEditingController(text: option?.name);
    final descriptionController = TextEditingController(text: option?.description);
    final priceController = TextEditingController(
      text: option?.priceAdjustment.toStringAsFixed(2) ?? '0.00',
    );
    final iconUrlController = TextEditingController(text: option?.iconUrl);
    bool isDefault = option?.isDefault ?? false;
    bool isAvailable = option?.isAvailable ?? true;
    String? dependsOnOptionId = option?.dependsOnOptionId;
    
    // Get other options for dependency selection
    final otherOptions = _options.where((o) => o.id != option?.id).toList();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(option == null ? 'Add Option' : 'Edit Option'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Option Name',
                    hintText: 'e.g., Oat Milk, Large Size',
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
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price Adjustment',
                    prefixText: '\$',
                    hintText: '0.00',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: iconUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Icon URL (optional)',
                    hintText: 'https://example.com/icon.png',
                  ),
                ),
                const SizedBox(height: 16),
                
                // Dependency dropdown
                if (otherOptions.isNotEmpty) ...[
                  DropdownButtonFormField<String?>(
                    value: dependsOnOptionId,
                    decoration: const InputDecoration(
                      labelText: 'Depends On (optional)',
                      helperText: 'Show this option only when another is selected',
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('No dependency'),
                      ),
                      ...otherOptions.map((opt) => DropdownMenuItem(
                        value: opt.id,
                        child: Text(opt.name),
                      )),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        dependsOnOptionId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                
                SwitchListTile(
                  title: const Text('Default Option'),
                  subtitle: Text(_optionGroup?.selectionType == 'single' 
                      ? 'Auto-selected when screen loads'
                      : 'Pre-selected in multiple choice'),
                  value: isDefault,
                  onChanged: (value) {
                    setDialogState(() {
                      isDefault = value;
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('Available'),
                  subtitle: const Text('Show this option to customers'),
                  value: isAvailable,
                  onChanged: (value) {
                    setDialogState(() {
                      isAvailable = value;
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
                      content: Text('Please enter an option name'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final priceAdjustment = double.tryParse(priceController.text) ?? 0.0;

                try {
                  print('[DEBUG OptionDialog] Attempting to save option');
                  print('[DEBUG OptionDialog] Name: ${nameController.text.trim()}');
                  print('[DEBUG OptionDialog] Price adjustment: $priceAdjustment');
                  print('[DEBUG OptionDialog] Is default: $isDefault');
                  print('[DEBUG OptionDialog] Option group ID: ${widget.optionGroupId}');
                  
                  if (option == null) {
                    print('[DEBUG OptionDialog] Creating new option...');
                    final result = await _menuService.createOption(
                      optionGroupId: widget.optionGroupId,
                      name: nameController.text.trim(),
                      description: descriptionController.text.trim(),
                      priceAdjustment: priceAdjustment,
                      iconUrl: iconUrlController.text.trim(),
                      isDefault: isDefault,
                      isAvailable: isAvailable,
                      dependsOnOptionId: dependsOnOptionId,
                    );
                    print('[DEBUG OptionDialog] Created option with ID: ${result.id}');
                  } else {
                    await _menuService.updateOption(
                      id: option.id,
                      name: nameController.text.trim(),
                      description: descriptionController.text.trim(),
                      priceAdjustment: priceAdjustment,
                      iconUrl: iconUrlController.text.trim(),
                      isDefault: isDefault,
                      isAvailable: isAvailable,
                      dependsOnOptionId: dependsOnOptionId,
                    );
                  }

                  Navigator.pop(context);
                  print('[DEBUG OptionDialog] Successfully saved, reloading data...');
                  await _loadData();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(option == null ? 'Option created successfully!' : 'Option updated successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  print('[ERROR OptionDialog] Failed to save option: $e');
                  print('[ERROR OptionDialog] Error type: ${e.runtimeType}');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error saving option: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text(option == null ? 'Add' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteOption(Option option) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Option'),
        content: Text('Are you sure you want to delete "${option.name}"?'),
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
        await _menuService.deleteOption(option.id);
        await _loadData();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Option deleted'),
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

  Future<void> _updateSortOrder(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    final List<Option> reorderedOptions = List.from(_options);
    final Option movedOption = reorderedOptions.removeAt(oldIndex);
    reorderedOptions.insert(newIndex, movedOption);
    
    setState(() {
      _options = reorderedOptions;
    });

    // Update sort orders in database
    try {
      for (int i = 0; i < reorderedOptions.length; i++) {
        await _menuService.updateOptionSortOrder(reorderedOptions[i].id, i);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order updated'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      await _loadData(); // Reload on error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_optionGroup?.name ?? 'Manage Options'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/admin/menu-options');
            }
          },
        ),
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
          : _optionGroup == null
              ? const Center(
                  child: Text('Option group not found'),
                )
              : Column(
                  children: [
                    // Group info header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: Colors.grey[100],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _optionGroup!.name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Chip(
                                label: Text(
                                  _optionGroup!.selectionType == 'single' 
                                      ? 'Single Selection' 
                                      : 'Multiple Selection',
                                ),
                                backgroundColor: _optionGroup!.selectionType == 'single'
                                    ? Colors.blue[100]
                                    : Colors.green[100],
                              ),
                            ],
                          ),
                          if (_optionGroup!.description != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _optionGroup!.description!,
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            _optionGroup!.isRequired 
                                ? 'Required - Customers must select an option'
                                : 'Optional - Customers can skip this',
                            style: TextStyle(
                              color: _optionGroup!.isRequired ? Colors.red : Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Options list
                    Expanded(
                      child: _options.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.list_alt, size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No options yet',
                                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Add options for customers to choose from',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    onPressed: () => _showAddEditOptionDialog(),
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add First Option'),
                                  ),
                                ],
                              ),
                            )
                          : ReorderableListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _options.length,
                              onReorder: _updateSortOrder,
                              itemBuilder: (context, index) {
                                final option = _options[index];
                                final dependsOnOption = option.dependsOnOptionId != null
                                    ? _options.firstWhere(
                                        (o) => o.id == option.dependsOnOptionId,
                                        orElse: () => option,
                                      )
                                    : null;

                                return Card(
                                  key: ValueKey(option.id),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    leading: ReorderableDragStartListener(
                                      index: index,
                                      child: const Icon(Icons.drag_handle),
                                    ),
                                    title: Row(
                                      children: [
                                        if (option.iconUrl != null && option.iconUrl!.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(right: 8),
                                            child: Image.network(
                                              option.iconUrl!,
                                              width: 24,
                                              height: 24,
                                              errorBuilder: (_, __, ___) => 
                                                  const Icon(Icons.circle, size: 24),
                                            ),
                                          ),
                                        Expanded(
                                          child: Text(
                                            option.name,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: option.isAvailable 
                                                  ? null 
                                                  : Colors.grey,
                                              decoration: option.isAvailable 
                                                  ? null 
                                                  : TextDecoration.lineThrough,
                                            ),
                                          ),
                                        ),
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
                                      ],
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (option.description != null && option.description!.isNotEmpty)
                                          Text(option.description!),
                                        if (dependsOnOption != null && dependsOnOption != option)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.link, size: 16, color: Colors.blue),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Shows when "${dependsOnOption.name}" is selected',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.blue,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        Wrap(
                                          spacing: 8,
                                          children: [
                                            if (option.isDefault)
                                              Chip(
                                                label: const Text('Default', style: TextStyle(fontSize: 10)),
                                                backgroundColor: Colors.orange,
                                                labelStyle: const TextStyle(color: Colors.white),
                                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              ),
                                            if (!option.isAvailable)
                                              Chip(
                                                label: const Text('Unavailable', style: TextStyle(fontSize: 10)),
                                                backgroundColor: Colors.grey,
                                                labelStyle: const TextStyle(color: Colors.white),
                                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    trailing: PopupMenuButton(
                                      icon: const Icon(Icons.more_vert),
                                      itemBuilder: (context) => [
                                        PopupMenuItem(
                                          onTap: () => Future.delayed(
                                            Duration.zero,
                                            () => _showAddEditOptionDialog(option),
                                          ),
                                          child: const Row(
                                            children: [
                                              Icon(Icons.edit),
                                              SizedBox(width: 8),
                                              Text('Edit'),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          onTap: () => Future.delayed(
                                            Duration.zero,
                                            () => _deleteOption(option),
                                          ),
                                          child: const Row(
                                            children: [
                                              Icon(Icons.delete, color: Colors.red),
                                              SizedBox(width: 8),
                                              Text('Delete', style: TextStyle(color: Colors.red)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
      floatingActionButton: _optionGroup != null && _options.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _showAddEditOptionDialog(),
              backgroundColor: Colors.red[700],
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}