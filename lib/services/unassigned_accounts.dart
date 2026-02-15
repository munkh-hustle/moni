import 'package:moni/models/transaction.dart';

import '../providers/transaction_provider.dart';
import '../providers/account_provider.dart';
import '../models/account.dart';

class UnassignedAccountsService {
  static Map<String, double> getUnassignedAccounts(
    TransactionProvider transactionProvider,
    AccountProvider accountProvider,
  ) {
    final spendingByAccount = transactionProvider.getSpendingByAccount();
    final allAccounts = accountProvider.getAllCategories();
    
    Map<String, double> unassignedAccounts = {};
    
    // Check each account in transactions
    for (var entry in spendingByAccount.entries) {
      String accountNumber = entry.key;
      double amount = entry.value;
      
      // Skip if account number is empty or unknown
      if (accountNumber.isEmpty || 
          accountNumber == 'Unknown' || 
          accountNumber == '0' ||
          accountNumber.length < 4) {
        continue;
      }
      
      // Check if this account is already assigned
      bool isAssigned = false;
      for (var account in allAccounts) {
        if (accountNumber.contains(account.accountNumber) ||
            account.accountNumber.contains(accountNumber)) {
          isAssigned = true;
          break;
        }
      }
      
      // If not assigned and has significant transactions, add to unassigned
      if (!isAssigned && amount > 0) {
        unassignedAccounts[accountNumber] = amount;
      }
    }
    
    return unassignedAccounts;
  }
  
  static List<Map<String, dynamic>> getUnassignedAccountsWithDetails(
    TransactionProvider transactionProvider,
    AccountProvider accountProvider,
  ) {
    final unassignedAccounts = getUnassignedAccounts(transactionProvider, accountProvider);
    final transactions = transactionProvider.transactions;
    
    List<Map<String, dynamic>> result = [];
    
    for (var entry in unassignedAccounts.entries) {
      String accountNumber = entry.key;
      double totalAmount = entry.value;
      
      // Get sample transactions for this account
      List<BankTransaction> accountTransactions = transactions
          .where((t) => 
              (t.relatedAccount?.contains(accountNumber) == true) ||
              (t.description.contains(accountNumber)))
          .take(3) // Limit to 3 sample transactions
          .toList();
      
      // Extract common description patterns
      String commonDescription = _extractCommonDescription(accountTransactions);
      
      result.add({
        'accountNumber': accountNumber,
        'totalAmount': totalAmount,
        'transactionCount': accountTransactions.length,
        'sampleTransactions': accountTransactions,
        'commonDescription': commonDescription,
        'suggestedCategory': _suggestCategory(commonDescription, accountTransactions),
      });
    }
    
    // Sort by total amount (highest first)
    result.sort((a, b) => b['totalAmount'].compareTo(a['totalAmount']));
    
    return result;
  }
  
  static String _extractCommonDescription(List<BankTransaction> transactions) {
    if (transactions.isEmpty) return 'No description';
    
    // Find common words in descriptions
    List<String> allWords = [];
    for (var transaction in transactions) {
      allWords.addAll(transaction.description.split(' '));
    }
    
    // Count word frequency
    Map<String, int> wordCount = {};
    for (var word in allWords) {
      word = word.trim().toLowerCase();
      if (word.length > 3 && !_isCommonWord(word)) {
        wordCount[word] = (wordCount[word] ?? 0) + 1;
      }
    }
    
    // Get top 3 words
    var sortedWords = wordCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    if (sortedWords.isEmpty) {
      return transactions.first.description.length > 50
          ? '${transactions.first.description.substring(0, 50)}...'
          : transactions.first.description;
    }
    
    return sortedWords.take(3).map((e) => e.key).join(' ');
  }
  
  static bool _isCommonWord(String word) {
    const commonWords = [
      'байна', 'бол', 'нийт', 'гүйлгээ', 'данс', 'хүргэх',
      'the', 'and', 'for', 'from', 'to', 'with', 'payment',
      'qpay', 'card', 'transfer', 'bank', 'mnt'
    ];
    return commonWords.contains(word.toLowerCase());
  }
  
  static String _suggestCategory(String description, List<BankTransaction> transactions) {
    description = description.toLowerCase();
    
    // Category detection logic
    if (description.contains('школ') || description.contains('сургууль') || 
        description.contains('education') || description.contains('school')) {
      return 'education';
    } else if (description.contains('гэр бүл') || description.contains('ээж') || 
               description.contains('ах') || description.contains('family')) {
      return 'family';
    } else if (description.contains('бизнес') || description.contains('компани') || 
               description.contains('business') || description.contains('company')) {
      return 'business';
    } else if (description.contains('хүргэлт') || description.contains('доставк') || 
               description.contains('delivery') || description.contains('ship')) {
      return 'shopping';
    } else if (description.contains('уулзалт') || description.contains('холбоо') || 
               description.contains('meeting') || description.contains('contact')) {
      return 'personal';
    } else if (description.contains('орлог') || description.contains('инвест') || 
               description.contains('income') || description.contains('invest')) {
      return 'investment';
    } else if (description.contains('төлбөр') || description.contains('хураамж') || 
               description.contains('payment') || description.contains('fee')) {
      return 'utilities';
    } else if (description.contains('захиалг') || description.contains('subscription')) {
      return 'subscriptions';
    }
    
    // Default based on transaction amount patterns
    if (transactions.isNotEmpty) {
      double avgAmount = transactions.fold(0.0, (sum, t) => sum + t.debit) / transactions.length;
      if (avgAmount > 1000000) {
        return 'investment';
      } else if (avgAmount > 100000) {
        return 'business';
      } else if (avgAmount > 10000) {
        return 'shopping';
      }
    }
    
    return 'other';
  }
  
  static String getCategoryDisplayName(String category) {
    switch (category) {
      case 'family': return 'Family';
      case 'education': return 'Education';
      case 'personal': return 'Personal';
      case 'business': return 'Business';
      case 'investment': return 'Investment';
      case 'shopping': return 'Shopping';
      case 'utilities': return 'Utilities';
      case 'subscriptions': return 'Subscriptions';
      default: return 'Other';
    }
  }
}