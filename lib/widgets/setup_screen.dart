import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/timer_config.dart';
import '../models/click_position.dart';
import '../services/timer_service.dart';
import '../services/click_service.dart';
import '../services/overlay_service.dart';
import '../utils/constants.dart';
import '../utils/permissions.dart';
import 'countdown_display.dart';
import 'position_selector.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _targetDateController = TextEditingController();
  final _targetTimeController = TextEditingController();
  
  late TabController _tabController;
  
  DateTime _selectedDate = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _clickCount = AppConstants.defaultClickCount;
  int _clickInterval = 10;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _ntpSyncEnabled = true;
  
  List<String> _permissionIssues = [];
  bool _isPermissionSetupComplete = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _updateDateTimeControllers();
    _checkPermissions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _targetDateController.dispose();
    _targetTimeController.dispose();
    super.dispose();
  }

  void _updateDateTimeControllers() {
    _targetDateController.text = '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';
    _targetTimeController.text = _selectedTime.format(context);
  }

  Future<void> _checkPermissions() async {
    final issues = await PermissionHelper.validateAppFunctionality();
    setState(() {
      _permissionIssues = issues;
      _isPermissionSetupComplete = issues.isEmpty;
    });
  }

  Future<void> _setupPermissions() async {
    final success = await PermissionHelper.setupPermissions();
    if (success) {
      await _checkPermissions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppConstants.permissionGrantedMessage),
            backgroundColor: AppConstants.successColor,
          ),
        );
      }
    }
  }

  DateTime get _targetDateTime {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  void _startCountdown() {
    if (!_formKey.currentState!.validate()) return;
    if (!_isPermissionSetupComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete permission setup first'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
      return;
    }

    final clickService = context.read<ClickService>();
    if (clickService.activeSequence?.positions.isEmpty ?? true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one click position'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
      return;
    }

    final timerConfig = TimerConfig(
      targetTime: _targetDateTime,
      isNtpSynced: _ntpSyncEnabled,
      soundEnabled: _soundEnabled,
      vibrationEnabled: _vibrationEnabled,
    );

    // Configure timer service
    final timerService = context.read<TimerService>();
    timerService.configure(timerConfig);

    // Set up timer expiration callback
    timerService.setExpirationCallback(() async {
      developer.log('Timer expired, executing clicks', name: 'SetupScreen');
      await clickService.executeClicks();
    });

    // Start NTP sync if enabled
    if (_ntpSyncEnabled) {
      timerService.initializeNtpSync();
    }

    // Start timer
    timerService.startTimer();

    // Show overlay if available
    final overlayService = context.read<OverlayService>();
    overlayService.showCountdownOverlay(timerConfig);

    // Navigate to countdown display
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CountdownDisplay(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: AppConstants.onPrimaryColor,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppConstants.onPrimaryColor,
          unselectedLabelColor: AppConstants.onPrimaryColor.withOpacity(0.7),
          indicatorColor: AppConstants.onPrimaryColor,
          tabs: const [
            Tab(icon: Icon(AppConstants.timerIcon), text: 'Timer'),
            Tab(icon: Icon(AppConstants.clickIcon), text: 'Clicks'),
            Tab(icon: Icon(AppConstants.positionIcon), text: 'Positions'),
            Tab(icon: Icon(AppConstants.settingsIcon), text: 'Settings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTimerTab(),
          _buildClicksTab(),
          _buildPositionsTab(),
          _buildSettingsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startCountdown,
        backgroundColor: AppConstants.successColor,
        icon: const Icon(AppConstants.playIcon),
        label: const Text('Start'),
      ),
    );
  }

  Widget _buildTimerTab() {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.mediumSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Target Launch Time',
              style: AppConstants.headingStyle,
            ),
            AppConstants.mediumSpacing.verticalSpace,
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _targetDateController,
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (date != null) {
                        setState(() {
                          _selectedDate = date;
                          _updateDateTimeControllers();
                        });
                      }
                    },
                  ),
                ),
                AppConstants.mediumSpacing.horizontalSpace,
                Expanded(
                  child: TextFormField(
                    controller: _targetTimeController,
                    decoration: const InputDecoration(
                      labelText: 'Time',
                      prefixIcon: Icon(Icons.access_time),
                    ),
                    readOnly: true,
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _selectedTime,
                      );
                      if (time != null) {
                        setState(() {
                          _selectedTime = time;
                          _updateDateTimeControllers();
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            
            AppConstants.largeSpacing.verticalSpace,
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.mediumSpacing),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Timer Settings',
                      style: AppConstants.subheadingStyle,
                    ),
                    AppConstants.smallSpacing.verticalSpace,
                    
                    SwitchListTile(
                      title: const Text('NTP Time Sync'),
                      subtitle: const Text('Sync with internet time servers for accuracy'),
                      value: _ntpSyncEnabled,
                      onChanged: (value) => setState(() => _ntpSyncEnabled = value),
                    ),
                    
                    Consumer<TimerService>(
                      builder: (context, timerService, child) {
                        return ListTile(
                          title: const Text('Time Server Status'),
                          subtitle: Text(
                            timerService.isSyncing
                                ? 'Synchronizing...'
                                : timerService.isNtpSynced
                                    ? 'Synchronized'
                                    : 'Not synchronized',
                          ),
                          trailing: timerService.isSyncing
                              ? const CircularProgressIndicator()
                              : Icon(
                                  timerService.isNtpSynced
                                      ? Icons.check_circle
                                      : Icons.error,
                                  color: timerService.isNtpSynced
                                      ? AppConstants.successColor
                                      : AppConstants.errorColor,
                                ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            if (!_isPermissionSetupComplete) ...[
              AppConstants.largeSpacing.verticalSpace,
              Card(
                color: AppConstants.errorColor.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.mediumSpacing),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning, color: AppConstants.errorColor),
                          AppConstants.smallSpacing.horizontalSpace,
                          Text(
                            'Permissions Required',
                            style: AppConstants.subheadingStyle.copyWith(
                              color: AppConstants.errorColor,
                            ),
                          ),
                        ],
                      ),
                      AppConstants.smallSpacing.verticalSpace,
                      ..._permissionIssues.map((issue) => Text('• $issue')),
                      AppConstants.mediumSpacing.verticalSpace,
                      ElevatedButton(
                        onPressed: _setupPermissions,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.errorColor,
                        ),
                        child: const Text('Grant Permissions'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildClicksTab() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.mediumSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Click Configuration',
            style: AppConstants.headingStyle,
          ),
          AppConstants.mediumSpacing.verticalSpace,
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.mediumSpacing),
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Clicks per Position'),
                    subtitle: Text('$_clickCount rapid clicks'),
                    trailing: SizedBox(
                      width: 100,
                      child: Slider(
                        value: _clickCount.toDouble(),
                        min: AppConstants.minClickCount.toDouble(),
                        max: AppConstants.maxClickCount.toDouble(),
                        divisions: AppConstants.maxClickCount - AppConstants.minClickCount,
                        onChanged: (value) => setState(() => _clickCount = value.toInt()),
                      ),
                    ),
                  ),
                  
                  ListTile(
                    title: const Text('Click Interval'),
                    subtitle: Text('${_clickInterval}ms between clicks'),
                    trailing: SizedBox(
                      width: 100,
                      child: Slider(
                        value: _clickInterval.toDouble(),
                        min: 1,
                        max: 100,
                        divisions: 99,
                        onChanged: (value) => setState(() => _clickInterval = value.toInt()),
                      ),
                    ),
                  ),
                  
                  ListTile(
                    title: const Text('Estimated Speed'),
                    subtitle: Text(
                      '${(1000 / _clickInterval).toStringAsFixed(1)} clicks/second',
                    ),
                    trailing: Icon(
                      (1000 / _clickInterval) >= AppConstants.targetClicksPerSecond
                          ? Icons.check_circle
                          : Icons.info,
                      color: (1000 / _clickInterval) >= AppConstants.targetClicksPerSecond
                          ? AppConstants.successColor
                          : AppConstants.warningColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          AppConstants.mediumSpacing.verticalSpace,
          
          Consumer<ClickService>(
            builder: (context, clickService, child) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.mediumSpacing),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Test Clicks',
                        style: AppConstants.subheadingStyle,
                      ),
                      AppConstants.smallSpacing.verticalSpace,
                      
                      ElevatedButton.icon(
                        onPressed: clickService.isExecuting ? null : () async {
                          if (clickService.activeSequence?.positions.isNotEmpty ?? false) {
                            // Update click service configuration
                            final currentSequence = clickService.activeSequence!;
                            final updatedSequence = currentSequence.copyWith(
                              clickCount: _clickCount,
                              clickInterval: Duration(milliseconds: _clickInterval),
                            );
                            clickService.configureSequence(updatedSequence);
                            
                            await clickService.executeClicks(testMode: true);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please add click positions first'),
                                backgroundColor: AppConstants.warningColor,
                              ),
                            );
                          }
                        },
                        icon: const Icon(AppConstants.testIcon),
                        label: Text(clickService.isExecuting ? 'Testing...' : 'Test Clicks'),
                      ),
                      
                      if (clickService.isExecuting)
                        Column(
                          children: [
                            AppConstants.smallSpacing.verticalSpace,
                            const LinearProgressIndicator(
                              backgroundColor: AppConstants.surfaceColor,
                              valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
                            ),
                            AppConstants.smallSpacing.verticalSpace,
                            Text('Executed: ${clickService.executedClicks} clicks'),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPositionsTab() {
    return PositionSelector(
      onPositionsChanged: (positions) {
        final clickSequence = ClickSequence(
          positions: positions,
          clickCount: _clickCount,
          clickInterval: Duration(milliseconds: _clickInterval),
        );
        context.read<ClickService>().configureSequence(clickSequence);
      },
    );
  }

  Widget _buildSettingsTab() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.mediumSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Feedback Settings',
            style: AppConstants.headingStyle,
          ),
          AppConstants.mediumSpacing.verticalSpace,
          
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Sound Feedback'),
                  subtitle: const Text('Play sound when clicks execute'),
                  secondary: const Icon(AppConstants.soundIcon),
                  value: _soundEnabled,
                  onChanged: (value) => setState(() => _soundEnabled = value),
                ),
                
                const Divider(),
                
                SwitchListTile(
                  title: const Text('Vibration Feedback'),
                  subtitle: const Text('Vibrate when clicks execute'),
                  secondary: const Icon(AppConstants.vibrationIcon),
                  value: _vibrationEnabled,
                  onChanged: (value) => setState(() => _vibrationEnabled = value),
                ),
              ],
            ),
          ),
          
          AppConstants.largeSpacing.verticalSpace,
          
          const Text(
            'Overlay Settings',
            style: AppConstants.headingStyle,
          ),
          AppConstants.mediumSpacing.verticalSpace,
          
          Consumer<OverlayService>(
            builder: (context, overlayService, child) {
              final status = overlayService.getOverlayStatus();
              return Card(
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('Floating Overlay'),
                      subtitle: Text(
                        status['isSupported']
                            ? status['isEnabled']
                                ? 'Ready'
                                : 'Permission required'
                            : 'Not supported on this device',
                      ),
                      trailing: Icon(
                        status['isSupported']
                            ? status['isEnabled']
                                ? Icons.check_circle
                                : Icons.warning
                            : Icons.error,
                        color: status['isSupported']
                            ? status['isEnabled']
                                ? AppConstants.successColor
                                : AppConstants.warningColor
                            : AppConstants.errorColor,
                      ),
                    ),
                    
                    if (status['isSupported'] && !status['isEnabled'])
                      Padding(
                        padding: const EdgeInsets.all(AppConstants.mediumSpacing),
                        child: ElevatedButton(
                          onPressed: () => overlayService.requestOverlayPermission(),
                          child: const Text('Enable Overlay'),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}