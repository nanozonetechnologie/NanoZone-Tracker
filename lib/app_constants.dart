import 'package:flutter/material.dart';

const List<String> categories = [
  // Essential Living
  'Groceries', 'Rent', 'Utilities', 'Bills', 'Family Health Care',
  // Transportation
  'Transport', 'Fuel', 'Vehicle Maintenance',
  // Food & Dining
  'Food & Dining', 'Dining',
  // Health & Wellness
  'Healthcare', 'Medicine', 'Fitness & Gym', 'Personal Care',
  // Education
  'Education', 'Books & Courses',
  // Shopping
  'Shopping', 'Clothing', 'Electronics', 'Home & Garden',
  // Entertainment
  'Entertainment', 'Movies & Shows', 'Travel', 'Hobbies',
  // Financial
  'Investment', 'Savings', 'Insurance', 'Loan EMI', 'Taxes', 'Stock', 'SIP', 'Gold',
  // Communication
  'Mobile Recharge', 'Internet', 'Subscriptions',
  // Social
  'Gifts', 'Donations', 'Events & Parties',
  // Special Tracking
  'Debt Repayment', 'Gift / Outside Budget',
  // Miscellaneous
  'Emergency', 'Repairs', 'Other',
];

const List<String> paymentMethods = [
  'Cash', 'Credit Card', 'Debit Card', 'UPI', 'Net Banking', 'Mobile Wallet', 'Bank Transfer', 'Cheque', 'Debt Payment', 'Other',
];

// Premium Color Palette - Sophisticated & Elegant
final Map<String, Color> categoryColors = {
  // Essential Living - Rich Greens & Earth Tones
  'Groceries': const Color(0xFF00C853),      // Vibrant Green
  'Rent': const Color(0xFF8D6E63),           // Warm Brown
  'Utilities': const Color(0xFFFF9800),      // Warm Orange
  'Bills': const Color(0xFFE53935),          // Rich Red
  'Family Health Care': const Color(0xFFEC407A), // Rose Pink

  // Transportation - Blues
  'Transport': const Color(0xFF1E88E5),      // Royal Blue
  'Fuel': const Color(0xFFFF7043),           // Deep Orange
  'Vehicle Maintenance': const Color(0xFF78909C), // Blue Grey

  // Food & Dining - Warm Tones
  'Food & Dining': const Color(0xFFFF5252),  // Coral Red
  'Dining': const Color(0xFFD32F2F),         // Deep Red

  // Health & Wellness - Calming Colors
  'Healthcare': const Color(0xFFE91E63),     // Pink
  'Medicine': const Color(0xFFF48FB1),       // Light Pink
  'Fitness & Gym': const Color(0xFFCDDC39),  // Lime
  'Personal Care': const Color(0xFFAB47BC),  // Purple

  // Education - Deep Blues & Indigos
  'Education': const Color(0xFF3949AB),      // Indigo
  'Books & Courses': const Color(0xFF5C6BC0), // Light Indigo

  // Shopping - Purple Tones
  'Shopping': const Color(0xFF7C4DFF),       // Deep Purple
  'Clothing': const Color(0xFF9575CD),       // Light Purple
  'Electronics': const Color(0xFF607D8B),    // Blue Grey
  'Home & Garden': const Color(0xFF66BB6A),  // Green

  // Entertainment - Teal & Cyan
  'Entertainment': const Color(0xFF00BFA5),  // Teal
  'Movies & Shows': const Color(0xFF26A69A), // Light Teal
  'Travel': const Color(0xFF00ACC1),         // Cyan
  'Hobbies': const Color(0xFFFFA000),        // Amber

  // Financial - Professional Blues & Greens
  'Investment': const Color(0xFF1A237E),     // Deep Indigo
  'Savings': const Color(0xFF2E7D32),        // Forest Green
  'Insurance': const Color(0xFF1565C0),      // Royal Blue
  'Loan EMI': const Color(0xFFF57C00),       // Deep Orange
  'Taxes': const Color(0xFF6A1B9A),          // Deep Purple
  'Stock': const Color(0xFF2196F3),          // Blue
  'SIP': const Color(0xFF9C27B0),            // Purple
  'Gold': const Color(0xFFFFD700),           // Gold

  // Communication - Tech Blues
  'Mobile Recharge': const Color(0xFF03A9F4), // Light Blue
  'Internet': const Color(0xFF0097A7),       // Cyan Dark
  'Subscriptions': const Color(0xFFD4AF37),  // Gold

  // Social - Warm & Inviting
  'Gifts': const Color(0xFFFFD600),          // Yellow
  'Donations': const Color(0xFF4CAF50),      // Green
  'Events & Parties': const Color(0xFFFF4081), // Pink Accent

  // Miscellaneous - Neutral & Attention
  'Emergency': const Color(0xFFC62828),      // Dark Red
  'Repairs': const Color(0xFF795548),        // Brown
  'Other': const Color(0xFF9E9E9E),          // Grey
};