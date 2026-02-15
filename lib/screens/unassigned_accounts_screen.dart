import 'package:flutter/material.dart';
import 'package:moni/models/transaction.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/account_provider.dart';
import '../services/unassigned_accounts.dart';
import '../models/account.dart';

class UnassignedAccountsScreen extends StatefulWidget {
  const UnassignedAccountsScreen({super.key});

  @override
  State<UnassignedAccountsScreen> createState() => _UnassignedAccountsScreenState();
}

class _UnassignedAccountsScreenState extends State<UnassignedAccountsScreen> {
  List<Map<String, dynamic>> _unassignedAccounts = [];
  bool _isLoading = true;
  List<bool> _selectedAccounts = [];

  @override
  void initState() {
    super.initState();
    _loadUnassignedAccounts();
  }

  Future<void> _loadUnassignedAccounts() async {
    final transactionProvider = context.read<TransactionProvider>();
    final accountProvider = context.read<AccountProvider>();
    
    await accountProvider.loadAccounts();
    
    setState(() {
      _unassignedAccounts = UnassignedAccountsService.getUnassignedAccountsWithDetails(
        transactionProvider,
        accountProvider,
      );
      _selectedAccounts = List.generate(_unassignedAccounts.length, (index) => false);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unassigned Accounts'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_unassignedAccounts.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _selectedAccounts.any((selected) => selected)
                  ? () => _assignSelectedAccounts()
                  : null,
              tooltip: 'Assign Selected',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _unassignedAccounts.isEmpty
              ? _buildEmptyState()
              : _buildUnassignedAccountsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, size: 80, color: Colors.green),
          const SizedBox(height: 20),
          const Text(
            'All accounts are assigned!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'No unassigned accounts found in your transactions.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildUnassignedAccountsList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Colors.blue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Unassigned Accounts Found',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${_unassignedAccounts.length} accounts need categorization',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        Expanded(
          child: ListView.builder(
            itemCount: _unassignedAccounts.length,
            itemBuilder: (context, index) {
              final account = _unassignedAccounts[index];
              final String accountNumber = account['accountNumber'];
              final double totalAmount = account['totalAmount'];
              final int transactionCount = account['transactionCount'];
              final String commonDescription = account['commonDescription'];
              final String suggestedCategory = account['suggestedCategory'];
              final List<BankTransaction> sampleTransactions = account['sampleTransactions'];
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    ListTile(
                      leading: Checkbox(
                        value: _selectedAccounts[index],
                        onChanged: (value) {
                          setState(() {
                            _selectedAccounts[index] = value!;
                          });
                        },
                      ),
                      title: Text(
                        'Account: $accountNumber',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            'Total: ₮${totalAmount.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('$transactionCount transactions'),
                          if (commonDescription.isNotEmpty)
                            Text(
                              'Common: $commonDescription',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showEditAccountDialog(accountNumber, suggestedCategory),
                      ),
                    ),
                    
                    // Sample transactions
                    if (sampleTransactions.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(),
                            const Text(
                              'Sample Transactions:',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            ...sampleTransactions.map((transaction) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                '• ${transaction.description.length > 40 ? 
                                  '${transaction.description.substring(0, 40)}...' : 
                                  transaction.description}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            )).toList(),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        
        // Bulk actions
        if (_selectedAccounts.any((selected) => selected))
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _assignAllWithSuggested(),
                    child: const Text('Assign All (Suggested)'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _assignSelectedAccounts(),
                    child: const Text('Assign Selected'),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _showEditAccountDialog(String accountNumber, String suggestedCategory) async {
    final formKey = GlobalKey<FormState>();
    final TextEditingController nameController = TextEditingController(
      text: 'Account $accountNumber',
    );
    String selectedCategory = suggestedCategory;
    Color selectedColor = Colors.blue;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Account'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Account Number'),
                  subtitle: Text(accountNumber),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Account Name',
                    hintText: 'e.g., Supplier, Client, Family Member',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter account name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'family', child: Text('Family')),
                    DropdownMenuItem(value: 'education', child: Text('Education')),
                    DropdownMenuItem(value: 'personal', child: Text('Personal')),
                    DropdownMenuItem(value: 'business', child: Text('Business')),
                    DropdownMenuItem(value: 'investment', child: Text('Investment')),
                    DropdownMenuItem(value: 'shopping', child: Text('Shopping')),
                    DropdownMenuItem(value: 'utilities', child: Text('Utilities')),
                    DropdownMenuItem(value: 'subscriptions', child: Text('Subscriptions')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (value) {
                    selectedCategory = value!;
                  },
                ),
                const SizedBox(height: 16),
                StatefulBuilder(
                  builder: (context, setState) {
                    return Row(
                      children: [
                        const Text('Color: '),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () async {
                            final Color? pickedColor = await showDialog<Color>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Pick a color'),
                                content: SingleChildScrollView(
                                  child: _ColorPicker(
                                    pickerColor: selectedColor,
                                    onColorChanged: (color) {
                                      setState(() {
                                        selectedColor = color;
                                      });
                                    },
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, selectedColor),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                            if (pickedColor != null) {
                              setState(() {
                                selectedColor = pickedColor;
                              });
                            }
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: selectedColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Skip'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                _assignAccount(
                  accountNumber,
                  nameController.text.trim(),
                  selectedCategory,
                  selectedColor,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }

  Future<void> _assignAccount(
    String accountNumber,
    String name,
    String category,
    Color color,
  ) async {
    final newAccount = AccountCategory(
      accountNumber: accountNumber,
      category: category,
      name: name,
      color: color,
    );
    
    await context.read<AccountProvider>().addAccount(newAccount);
    
    // Remove from unassigned list
    setState(() {
      int index = _unassignedAccounts.indexWhere(
        (account) => account['accountNumber'] == accountNumber,
      );
      if (index != -1) {
        _unassignedAccounts.removeAt(index);
        _selectedAccounts.removeAt(index);
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Account $accountNumber assigned as $name'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _assignSelectedAccounts() async {
    for (int i = _selectedAccounts.length - 1; i >= 0; i--) {
      if (_selectedAccounts[i]) {
        final account = _unassignedAccounts[i];
        final accountNumber = account['accountNumber'];
        final suggestedCategory = account['suggestedCategory'];
        
        // Use default naming and color
        await context.read<AccountProvider>().addAccount(
          AccountCategory(
            accountNumber: accountNumber,
            category: suggestedCategory,
            name: 'Account $accountNumber',
            color: _getColorForCategory(suggestedCategory),
          ),
        );
        
        _unassignedAccounts.removeAt(i);
        _selectedAccounts.removeAt(i);
      }
    }
    
    setState(() {});
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_selectedAccounts.where((s) => s).length} accounts assigned'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _assignAllWithSuggested() async {
    for (var account in _unassignedAccounts) {
      final accountNumber = account['accountNumber'];
      final suggestedCategory = account['suggestedCategory'];
      
      await context.read<AccountProvider>().addAccount(
        AccountCategory(
          accountNumber: accountNumber,
          category: suggestedCategory,
          name: 'Account $accountNumber',
          color: _getColorForCategory(suggestedCategory),
        ),
      );
    }
    
    setState(() {
      _unassignedAccounts.clear();
      _selectedAccounts.clear();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('All accounts assigned with suggested categories'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Color _getColorForCategory(String category) {
    switch (category) {
      case 'family': return Colors.pink;
      case 'education': return Colors.blue;
      case 'personal': return Colors.green;
      case 'business': return Colors.orange;
      case 'investment': return Colors.purple;
      case 'shopping': return Colors.teal;
      case 'utilities': return Colors.brown;
      case 'subscriptions': return Colors.indigo;
      default: return Colors.grey;
    }
  }
}

// Simple Color Picker Widget (copied from accounts_screen)
class _ColorPicker extends StatefulWidget {
  final Color pickerColor;
  final ValueChanged<Color> onColorChanged;

  const _ColorPicker({
    required this.pickerColor,
    required this.onColorChanged,
  });

  @override
  __ColorPickerState createState() => __ColorPickerState();
}

class __ColorPickerState extends State<_ColorPicker> {
  late Color _currentColor;

  @override
  void initState() {
    super.initState();
    _currentColor = widget.pickerColor;
  }

  final List<Color> _colors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _colors.map((color) {
        return GestureDetector(
          onTap: () {
            setState(() {
              _currentColor = color;
            });
            widget.onColorChanged(color);
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: _currentColor.value == color.value ? Colors.black : Colors.transparent,
                width: 2,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}