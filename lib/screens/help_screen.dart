import 'package:flutter/material.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final List<Item> _data = generateItems();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help'),
      ),
      body: SingleChildScrollView(
        child: ExpansionPanelList(
          expansionCallback: (int index, bool isExpanded) {
            setState(() {
              _data[index].isExpanded = isExpanded;
            });
          },
          children: _data.map<ExpansionPanel>((Item item) {
            return ExpansionPanel(
              headerBuilder: (BuildContext context, bool isExpanded) {
                return ListTile(
                  title: Text(item.headerValue),
                );
              },
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  item.expandedValue,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              isExpanded: item.isExpanded,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class Item {
  Item({
    required this.expandedValue,
    required this.headerValue,
    this.isExpanded = false,
  });

  String expandedValue;
  String headerValue;
  bool isExpanded;
}

List<Item> generateItems() {
  return [
    Item(
      headerValue: 'How to Take a Backup',
      expandedValue: '''
Step 1: Open Settings Menu
• Tap the menu icon (⚙️) at the top right
• Select 'Backup & Restore'

Step 2: Export Backup
• Tap 'Export Backup' button
• Share sheet will appear

Step 3: Save Your Backup
• Choose where to save:
  - Save to Files (iCloud or local)
  - Email to yourself
  - Save to Google Drive/Dropbox
  - Share to other apps

💡 Tip: Each backup includes a timestamp in the filename!
''',
    ),
    Item(
        headerValue: 'How to Restore a Backup',
        expandedValue: '''
Step 1: Prepare Backup File
• Download your backup file from:
  - Files app (iCloud/local)
  - Email attachment
  - Cloud storage (Drive/Dropbox)

Step 2: Open Backup & Restore
• Tap menu icon (⚙️)
• Select 'Backup & Restore'

Step 3: Import Backup
• Tap 'Import Backup' button
• Navigate to your backup file
• Select the .json file
• Confirm restore

⚠️ Warning: This will replace ALL current data!
💡 Tip: Look for files named expense_tracker_backup_*.json
'''),
    Item(
        headerValue: 'How to Add Expenses',
        expandedValue: '''
• Tap 'Add New Expense' from home
• Or tap the + button at bottom right
• Enter amount and select category
• Choose payment method
• Add optional notes
• Tap Save

💡 Tip: Date is automatically set to today!
'''),
    Item(
        headerValue: 'How to Use Dashboard',
        expandedValue: '''
Set Budget:
• Enter budget amount in budget card
• Tap ✓ button to save

View Charts:
• Toggle between Pie Chart and Trend Graph
• Pie Chart: See spending by category
• Trend Graph: Track spending over time
• Use filters to select month/year
'''),
    Item(
        headerValue: 'How to Track Investments',
        expandedValue: '''
• When adding expense, select 'Investment' category
• View all investments in 'View Investments'
• Filter by month or year
• Track total investments over time

💡 Investments are expenses tracked separately!
'''),
  ];
}
