// lib/features/settings/presentation/pages/settings_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../settings/data/settings_storage.dart';
import '../../../../main.dart' show ThemeCubit; // reuse ThemeCubit

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _sheetFormKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _line1Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();

  String _appVersion = '';
  String _deviceInfo = '';

  @override
  void initState() {
    super.initState();
    _loadAddress();
    _loadAppInfo();
    _loadDeviceInfo();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _line1Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _loadAddress() async {
    final saved = await SettingsStorage.loadAddress();
    if (saved != null && mounted) {
      setState(() {
        _nameController.text = saved.name;
        _phoneController.text = saved.phone;
        _line1Controller.text = saved.line1;
        _cityController.text = saved.city;
        _stateController.text = saved.state ?? '';
        _pincodeController.text = saved.pincode ?? '';
      });
    }
  }

  Future<void> _loadAppInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = '${info.version} (${info.buildNumber})';
        });
      }
    } catch (_) {
      if (mounted) setState(() => _appVersion = 'Unknown');
    }
  }

  Future<void> _loadDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    String infoStr = '';
    try {
      if (Platform.isAndroid) {
        final android = await deviceInfo.androidInfo;
        final model = android.model;
        final manufacturer = android.manufacturer;
        final release = android.version.release;
        infoStr = '$manufacturer $model (Android $release)';
      } else if (Platform.isIOS) {
        final ios = await deviceInfo.iosInfo;
        final machine = ios.utsname.machine;
        final sysVer = ios.systemVersion;
        infoStr = '$machine (iOS $sysVer)';
      } else {
        infoStr = '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
      }
    } catch (_) {
      infoStr = 'Unavailable';
    }

    if (mounted) setState(() => _deviceInfo = infoStr);
  }

  Future<void> _saveAddressFromControllers() async {
    final addr = UserAddress(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      line1: _line1Controller.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim().isEmpty ? null : _stateController.text.trim(),
      pincode: _pincodeController.text.trim().isEmpty ? null : _pincodeController.text.trim(),
    );
    await SettingsStorage.saveAddress(addr);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address saved successfully')),
      );
      setState(() {});
    }
  }

  Future<void> _clearAddress() async {
    await SettingsStorage.clearAddress();
    _nameController.clear();
    _phoneController.clear();
    _line1Controller.clear();
    _cityController.clear();
    _stateController.clear();
    _pincodeController.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address cleared')),
      );
      setState(() {});
    }
  }

  Future<void> _showAddressEditorBottomSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(14))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Form(
              key: _sheetFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 16),
                  Text('Edit Address',
                      style: Theme.of(ctx).textTheme.titleLarge),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Name required' : null,
                  ),
                  const SizedBox(height: 8),

                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Phone'),
                    keyboardType: TextInputType.phone,
                    validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Phone required' : null,
                  ),
                  const SizedBox(height: 8),

                  TextFormField(
                    controller: _line1Controller,
                    decoration: const InputDecoration(labelText: 'Address'),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Address required'
                        : null,
                  ),
                  const SizedBox(height: 8),

                  TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(labelText: 'City'),
                    validator: (v) =>
                    v == null || v.trim().isEmpty ? 'City required' : null,
                  ),
                  const SizedBox(height: 8),

                  TextFormField(
                    controller: _stateController,
                    decoration:
                    const InputDecoration(labelText: 'State (optional)'),
                  ),
                  const SizedBox(height: 8),

                  TextFormField(
                    controller: _pincodeController,
                    decoration:
                    const InputDecoration(labelText: 'Pincode (optional)'),
                    keyboardType: TextInputType.number,
                  ),

                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.save),
                          label: const Text('Save'),
                          onPressed: () async {
                            if (_sheetFormKey.currentState?.validate() ??
                                false) {
                              await _saveAddressFromControllers();
                              Navigator.of(ctx).pop();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.cancel_outlined),
                          label: const Text('Cancel'),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (mounted) setState(() {});
  }

  Widget _buildAddressCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasAddress =
        _line1Controller.text.trim().isNotEmpty || _cityController.text.trim().isNotEmpty;
    final displayName =
    _nameController.text.trim().isEmpty ? 'No name set' : _nameController.text.trim();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: cs.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _showAddressEditorBottomSheet,
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            children: [
              const Icon(Icons.person_pin_circle, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayName,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    if (hasAddress)
                      Text(
                        '${_line1Controller.text}, ${_cityController.text}${_stateController.text.isNotEmpty ? ', ${_stateController.text}' : ''}${_pincodeController.text.isNotEmpty ? ' - ${_pincodeController.text}' : ''}',
                        style: Theme.of(context).textTheme.bodySmall,
                      )
                    else
                      Text('Tap to add your address',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: cs.onSurface.withOpacity(0.7))),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Clear address',
                icon: const Icon(Icons.delete_outline),
                onPressed: _clearAddress,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Address / profile card
          _buildAddressCard(context),
          const SizedBox(height: 10),

          // Phone + City row
          if (_phoneController.text.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12, left: 6),
              child: Row(
                children: [
                  const Icon(Icons.phone, size: 18),
                  const SizedBox(width: 6),
                  Text(_phoneController.text.trim(),
                      style: Theme.of(context).textTheme.bodyLarge),
                  if (_cityController.text.trim().isNotEmpty) ...[
                    const SizedBox(width: 10),
                    Container(width: 1, height: 18, color: cs.onSurface.withOpacity(0.4)),
                    const SizedBox(width: 10),
                    Text(_cityController.text.trim(),
                        style: Theme.of(context).textTheme.bodyLarge),
                  ],
                ],
              ),
            ),

          Divider(color: cs.surfaceVariant),

          // App Info
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text("App Info"),
            subtitle: Text("Version: $_appVersion"),
          ),
          Divider(color: cs.surfaceVariant),

          // Device Info
          ListTile(
            leading: const Icon(Icons.devices_other),
            title: const Text("Device Info"),
            subtitle: Text(_deviceInfo.isNotEmpty ? _deviceInfo : "Loading..."),
          ),
          Divider(color: cs.surfaceVariant),

          // Theme toggle icon
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text("Toggle Theme"),
            onTap: () => context.read<ThemeCubit>().toggle(),
          ),
        ],
      ),
    );
  }
}