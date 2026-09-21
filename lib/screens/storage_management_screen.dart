import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class StorageManagementScreen extends StatefulWidget {
  const StorageManagementScreen({super.key});

  @override
  State<StorageManagementScreen> createState() => _StorageManagementScreenState();
}

class _StorageManagementScreenState extends State<StorageManagementScreen> {
  bool _isLoading = false;
  final int _databaseSize = 0;
  int _cacheSize = 0;
  int _tempFilesSize = 0;
  int _totalSize = 0;

  @override
  void initState() {
    super.initState();
    _loadStorageInfo();
  }

  Future<void> _loadStorageInfo() async {
    setState(() => _isLoading = true);

    try {
      // Get database size

      // Get cache directory size
      final cacheDir = await getTemporaryDirectory();
      _cacheSize = await _getDirectorySize(cacheDir);

      // Get app documents directory size (for backup files)
      final docsDir = await getApplicationDocumentsDirectory();
      _tempFilesSize = await _getBackupFilesSize(docsDir);

      _totalSize = _databaseSize + _cacheSize + _tempFilesSize;
    } catch (e) {
      // Ignore errors
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<int> _getDirectorySize(Directory directory) async {
    int size = 0;
    try {
      if (await directory.exists()) {
        await for (final entity in directory.list(recursive: true)) {
          if (entity is File) {
            try {
              size += await entity.length();
            } catch (e) {
              // Skip files we can't access
            }
          }
        }
      }
    } catch (e) {
      // Ignore errors
    }
    return size;
  }

  Future<int> _getBackupFilesSize(Directory directory) async {
    int size = 0;
    try {
      if (await directory.exists()) {
        await for (final entity in directory.list()) {
          if (entity is File && entity.path.contains('expense_tracker_backup_')) {
            try {
              size += await entity.length();
            } catch (e) {
              // Skip files we can't access
            }
          }
        }
      }
    } catch (e) {
      // Ignore errors
    }
    return size;
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  Future<void> _optimizeDatabase() async {
    setState(() => _isLoading = true);

    try {
      final sizeBefore = _databaseSize;

      // Reload storage info
      await _loadStorageInfo();

      final savedBytes = sizeBefore - _databaseSize;

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            savedBytes > 0
              ? 'Database optimized! Reclaimed ${_formatBytes(savedBytes)}'
              : 'Database already optimized',
          ),
          backgroundColor: savedBytes > 0 ? Colors.green : Colors.blue,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Optimization failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Cache?'),
        content: const Text('This will clear temporary files and cache. Your data will not be affected.'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          TextButton(
            child: const Text('Clear'),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      // Clear cache directory
      final cacheDir = await getTemporaryDirectory();
      if (await cacheDir.exists()) {
        await for (final entity in cacheDir.list()) {
          try {
            await entity.delete(recursive: true);
          } catch (e) {
            // Ignore delete errors
          }
        }
      }

      // Delete old backup files (keep only last 2)
      final docsDir = await getApplicationDocumentsDirectory();
      final backupFiles = <File>[];
      await for (final entity in docsDir.list()) {
        if (entity is File && entity.path.contains('expense_tracker_backup_')) {
          backupFiles.add(entity);
        }
      }

      if (backupFiles.length > 2) {
        backupFiles.sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified));
        for (int i = 0; i < backupFiles.length - 2; i++) {
          try {
            await backupFiles[i].delete();
          } catch (e) {
            // Ignore delete errors
          }
        }
      }

      await _loadStorageInfo();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cache cleared successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to clear cache: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Storage Management'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStorageInfo,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Storage Usage',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          _buildStorageRow('Database', _databaseSize),
                          const Divider(),
                          _buildStorageRow('Cache', _cacheSize),
                          const Divider(),
                          _buildStorageRow('Backup Files', _tempFilesSize),
                          const Divider(),
                          _buildStorageRow('Total', _totalSize, isBold: true),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.storage, color: Colors.blue),
                          title: const Text('Optimize Database'),
                          subtitle: const Text('Reclaim unused space and improve performance'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: _optimizeDatabase,
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.cleaning_services, color: Colors.orange),
                          title: const Text('Clear Cache'),
                          subtitle: const Text('Remove temporary files and old backups'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: _clearCache,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'Storage Tips',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '• Database is automatically optimized on app start\n'
                            '• Only the last 5 backup files are kept\n'
                            '• Cache files are temporary and safe to delete\n'
                            '• Regular optimization keeps app storage minimal',
                            style: TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStorageRow(String label, int size, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            _formatBytes(size),
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? Theme.of(context).primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }
}
