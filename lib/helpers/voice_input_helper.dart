/// Result of parsing voice input for expense
class VoiceExpenseResult {
  final double? amount;
  final String? category;
  final String? paymentMethod;
  final String? notes;
  final DateTime? date;
  final bool isValid;
  final String? errorMessage;
  final double confidence;

  VoiceExpenseResult({
    this.amount,
    this.category,
    this.paymentMethod,
    this.notes,
    this.date,
    this.isValid = false,
    this.errorMessage,
    this.confidence = 0.0,
  });

  @override
  String toString() {
    return 'Amount: $amount, Category: $category, Payment: $paymentMethod, Date: $date, Notes: $notes';
  }
}

class VoiceInputHelper {
  /// Advanced Heuristic Intent Parser
  static VoiceExpenseResult parseVoiceInput(String input) {
    if (input.trim().isEmpty) {
      return VoiceExpenseResult(isValid: false, errorMessage: 'No input provided');
    }

    final originalInput = input.trim();
    final lowerInput = originalInput.toLowerCase();
    
    // 1. Precise Amount Extraction (Handles 5k, 2.5 lakh, word-numbers)
    final amountData = _extractAmount(lowerInput);
    
    // 2. Intelligent Category Recognition (Priority weighted matching)
    final categoryData = _extractCategory(lowerInput);
    
    // 3. Payment Method detection
    final paymentData = _extractPaymentMethod(lowerInput);
    
    // 4. Temporal parsing (today, yesterday, dates)
    final date = _extractDate(lowerInput);

    // 5. Context-aware Notes cleanup
    final cleanNotes = _generateCleanNotes(originalInput, amountData.rawMatch, categoryData.rawMatch, paymentData.rawMatch);

    bool isValid = amountData.value != null && amountData.value! > 0;
    
    return VoiceExpenseResult(
      amount: amountData.value,
      category: categoryData.value ?? 'Other',
      paymentMethod: paymentData.value ?? 'Cash',
      notes: cleanNotes,
      date: date,
      isValid: isValid,
      confidence: isValid ? 0.95 : 0.2,
      errorMessage: isValid ? null : 'Could not understand the amount. Try "Spent 500 on groceries"',
    );
  }

  static _EntityMatch<double> _extractAmount(String input) {
    // 1. Multiplier Notation (5k, 1.2 Lakh, 50cr)
    final multiplierRegex = RegExp(r'(\d+\.?\d*)\s*(k|m|lakh|lac|cr|crore)\b');
    final mMatch = multiplierRegex.firstMatch(input);
    if (mMatch != null) {
      double val = double.tryParse(mMatch.group(1)!) ?? 0;
      String unit = mMatch.group(2)!;
      if (unit == 'k') val *= 1000;
      if (unit == 'm') val *= 1000000;
      if (unit == 'lakh' || unit == 'lac') val *= 100000;
      if (unit == 'cr' || unit == 'crore') val *= 10000000;
      return _EntityMatch(val, mMatch.group(0)!);
    }

    // 2. Natural Word Numbers (five hundred, one thousand)
    final wordVal = _parseEnglishNumbers(input);
    if (wordVal != null) return _EntityMatch(wordVal, ''); 

    // 3. Explicit Currency Symbols (₹500, Rs. 200, 100 dollars)
    final currencyRegex = RegExp(r'(?:rs\.?|rupees?|inr|₹|\$|dollars?)\s*(\d+\.?\d*)|\b(\d+\.?\d*)\s*(?:rs\.?|rupees?|inr|₹|\$|dollars?)');
    final cMatch = currencyRegex.firstMatch(input);
    if (cMatch != null) {
      final val = double.tryParse(cMatch.group(1) ?? cMatch.group(2) ?? '');
      if (val != null) return _EntityMatch(val, cMatch.group(0)!);
    }

    // 4. Raw Numerical Fallback (Any number >= 10)
    final rawRegex = RegExp(r'\b\d{2,}\b');
    final rMatch = rawRegex.firstMatch(input);
    if (rMatch != null) return _EntityMatch(double.parse(rMatch.group(0)!), rMatch.group(0)!);

    return _EntityMatch(null, '');
  }

  static double? _parseEnglishNumbers(String input) {
    final numberMap = {
      'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5, 'six': 6, 'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10,
      'eleven': 11, 'twelve': 12, 'thirteen': 13, 'fourteen': 14, 'fifteen': 15, 'sixteen': 16, 'seventeen': 17, 'eighteen': 18, 'nineteen': 19,
      'twenty': 20, 'thirty': 30, 'forty': 40, 'fifty': 50, 'sixty': 60, 'seventy': 70, 'eighty': 80, 'ninety': 90,
      'hundred': 100, 'thousand': 1000, 'lakh': 100000, 'crore': 10000000,
    };
    
    final words = input.split(RegExp(r'\s+'));
    double total = 0;
    double current = 0;
    bool found = false;

    for (var word in words) {
      final val = numberMap[word.replaceAll(RegExp(r'[,.]'), '')];
      if (val != null) {
        found = true;
        if (val >= 100) {
          current = current == 0 ? val.toDouble() : current * val;
          if (val >= 1000) {
            total += current;
            current = 0;
          }
        } else {
          current += val;
        }
      }
    }
    return found ? total + current : null;
  }

  static _EntityMatch<String> _extractCategory(String input) {
    String? bestCat;
    double maxWeight = 0;
    String matchedRaw = '';

    for (var entry in _catRules.entries) {
      for (var keyword in entry.value) {
        if (input.contains(keyword)) {
          // Weight by length of match to favor "petrol" over "pet"
          double weight = 1.0 + (keyword.length * 0.2);
          if (weight > maxWeight) {
            maxWeight = weight;
            bestCat = entry.key;
            matchedRaw = keyword;
          }
        }
      }
    }
    return _EntityMatch(bestCat, matchedRaw);
  }

  static _EntityMatch<String> _extractPaymentMethod(String input) {
    for (var entry in _payRules.entries) {
      for (var kw in entry.value) {
        if (input.contains(kw)) return _EntityMatch(entry.key, kw);
      }
    }
    return _EntityMatch(null, '');
  }

  static DateTime _extractDate(String input) {
    final now = DateTime.now();
    if (input.contains('yesterday')) return now.subtract(const Duration(days: 1));
    if (input.contains('day before yesterday')) return now.subtract(const Duration(days: 2));
    if (input.contains('last week')) return now.subtract(const Duration(days: 7));
    return now;
  }

  static String _generateCleanNotes(String original, String amtRaw, String catRaw, String payRaw) {
    String res = original;
    // Strip common "Stop words" and command triggers
    res = res.replaceAll(RegExp(r'\b(add|spent|spend|paid|pay|for|on|using|via|through|with|by|rupees?|rs\.?|inr|₹|amount|price|cost)\b', caseSensitive: false), '');
    
    // Remove exactly what was parsed as entities
    if (amtRaw.isNotEmpty) res = res.replaceFirst(amtRaw, '');
    if (catRaw.isNotEmpty) res = res.replaceFirst(catRaw, '');
    if (payRaw.isNotEmpty) res = res.replaceFirst(payRaw, '');
    
    // Final polish
    res = res.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (res.isEmpty) return '';
    return res[0].toUpperCase() + res.substring(1);
  }

  static const Map<String, List<String>> _catRules = {
    'Groceries': ['grocery', 'groceries', 'vegetable', 'fruit', 'milk', 'egg', 'supermarket', 'market', 'provisions', 'kirana'],
    'Food & Dining': ['food', 'lunch', 'dinner', 'breakfast', 'brunch', 'restaurant', 'hotel', 'cafe', 'coffee', 'tea', 'starbucks', 'snacks', 'pizza', 'burger', 'swiggy', 'zomato', 'eat'],
    'Transport': ['taxi', 'cab', 'uber', 'ola', 'auto', 'bus', 'metro', 'train', 'travel', 'ride', 'commute'],
    'Fuel': ['petrol', 'diesel', 'gas', 'cng', 'fuel', 'filling station'],
    'Shopping': ['shopping', 'amazon', 'flipkart', 'myntra', 'clothes', 'clothing', 'shoes', 'dress', 'shirt', 'watch', 'online'],
    'Healthcare': ['health', 'hospital', 'doctor', 'clinic', 'medicine', 'pharmacy', 'checkup', 'medical', 'dentist'],
    'Entertainment': ['movie', 'netflix', 'prime', 'cinema', 'theatre', 'gaming', 'ps5', 'xbox', 'fun', 'outing', 'party'],
    'Bills': ['bill', 'electricity', 'rent', 'wifi', 'internet', 'broadband', 'recharge', 'mobile', 'phone bill', 'water bill'],
    'Investment': ['investment', 'sip','crypto', 'fd', 'fixed deposit'],
    'Gold':['gold','gold cheat','GRT'],
    'Stock':['Stock','shares'],
    'Sip':['sip','mutual fund'],
    'Savings': ['savings', 'save', 'saving'],
    'EMI': ['emi', 'loan', 'installment', 'credit card bill'],
    'Personal Care': ['salon', 'haircut', 'spa', 'beauty', 'makeup', 'gym', 'fitness', 'workout'],
  };

  static const Map<String, List<String>> _payRules = {
    'UPI': ['upi', 'gpay', 'phonepe', 'paytm', 'bhim', 'online', 'scan', 'barcode'],
    'Cash': ['cash', 'hand', 'money', 'pocket'],
    'Credit Card': ['credit card', 'credit', 'cc', 'hdfc', 'sbi', 'icici', 'axis'],
    'Debit Card': ['debit card', 'debit', 'dc', 'atm', 'card'],
    'Bank Transfer': ['bank transfer', 'neft', 'imps', 'rtgs', 'transfer'],
  };
}

class _EntityMatch<T> {
  final T? value;
  final String rawMatch;
  _EntityMatch(this.value, this.rawMatch);
}
