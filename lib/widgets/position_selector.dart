import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/click_position.dart';
import '../services/click_service.dart';
import '../utils/constants.dart';

class PositionSelector extends StatefulWidget {
  final Function(List<ClickPosition>) onPositionsChanged;

  const PositionSelector({
    super.key,
    required this.onPositionsChanged,
  });

  @override
  State<PositionSelector> createState() => _PositionSelectorState();
}

class _PositionSelectorState extends State<PositionSelector> {
  final List<ClickPosition> _positions = [];
  bool _isSelectionMode = false;
  int _positionCounter = 1;

  @override
  void initState() {
    super.initState();
    _notifyPositionsChanged();
  }

  void _notifyPositionsChanged() {
    widget.onPositionsChanged(_positions);
  }

  void _enterSelectionMode() {
    setState(() {
      _isSelectionMode = true;
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
    });
  }

  void _addPosition(Offset position) {
    final newPosition = ClickPosition(
      x: position.dx,
      y: position.dy,
      label: 'Position $_positionCounter',
    );

    setState(() {
      _positions.add(newPosition);
      _positionCounter++;
    });

    _notifyPositionsChanged();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${newPosition.label} at (${position.dx.toInt()}, ${position.dy.toInt()})'),
        backgroundColor: AppConstants.successColor,
        duration: const Duration(seconds: 2),
      ),
    );

    developer.log('Added position: ${newPosition.label} at (${position.dx}, ${position.dy})', name: 'PositionSelector');
  }

  void _removePosition(int index) {
    final removedPosition = _positions[index];
    setState(() {
      _positions.removeAt(index);
    });

    _notifyPositionsChanged();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed ${removedPosition.label}'),
        backgroundColor: AppConstants.warningColor,
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _positions.insert(index, removedPosition);
            });
            _notifyPositionsChanged();
          },
        ),
      ),
    );
  }

  void _togglePosition(int index) {
    final position = _positions[index];
    setState(() {
      _positions[index] = position.copyWith(isEnabled: !position.isEnabled);
    });
    _notifyPositionsChanged();
  }

  void _editPositionLabel(int index) {
    final position = _positions[index];
    final controller = TextEditingController(text: position.label);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Position Label'),
        content: TextField(
          controller: controller,
          maxLength: AppConstants.maxPositionLabelLength,
          decoration: const InputDecoration(
            labelText: 'Position Label',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  _positions[index] = position.copyWith(label: controller.text);
                });
                _notifyPositionsChanged();
              }
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _clearAllPositions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Positions'),
        content: const Text('Are you sure you want to remove all click positions?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _positions.clear();
                _positionCounter = 1;
              });
              _notifyPositionsChanged();
              Navigator.of(context).pop();
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Future<void> _testPosition(ClickPosition position) async {
    try {
      final clickService = context.read<ClickService>();
      await clickService.testPosition(position);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tested ${position.label}'),
          backgroundColor: AppConstants.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test failed: $e'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              // Instructions
              Container(
                width: double.infinity,
                color: AppConstants.primaryColor,
                padding: const EdgeInsets.all(AppConstants.mediumSpacing),
                child: Column(
                  children: [
                    Text(
                      'Click Positions',
                      style: AppConstants.headingStyle.copyWith(
                        color: AppConstants.onPrimaryColor,
                      ),
                    ),
                    AppConstants.smallSpacing.verticalSpace,
                    Text(
                      _isSelectionMode
                          ? 'Tap anywhere on the screen to add a click position'
                          : 'Manage your click positions below',
                      style: AppConstants.bodyStyle.copyWith(
                        color: AppConstants.onPrimaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Position list
              Expanded(
                child: _positions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              AppConstants.positionIcon,
                              size: 64,
                              color: AppConstants.statusIdleColor,
                            ),
                            AppConstants.mediumSpacing.verticalSpace,
                            Text(
                              'No click positions added yet',
                              style: AppConstants.subheadingStyle.copyWith(
                                color: AppConstants.statusIdleColor,
                              ),
                            ),
                            AppConstants.smallSpacing.verticalSpace,
                            const Text(
                              'Tap "Add Position" to start',
                              style: AppConstants.captionStyle,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppConstants.mediumSpacing),
                        itemCount: _positions.length,
                        itemBuilder: (context, index) {
                          final position = _positions[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: AppConstants.smallSpacing),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: position.isEnabled
                                    ? AppConstants.successColor
                                    : AppConstants.statusIdleColor,
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(position.label),
                              subtitle: Text(
                                'X: ${position.x.toInt()}, Y: ${position.y.toInt()}',
                                style: AppConstants.captionStyle,
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  switch (value) {
                                    case 'test':
                                      _testPosition(position);
                                      break;
                                    case 'edit':
                                      _editPositionLabel(index);
                                      break;
                                    case 'toggle':
                                      _togglePosition(index);
                                      break;
                                    case 'remove':
                                      _removePosition(index);
                                      break;
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'test',
                                    child: ListTile(
                                      leading: Icon(AppConstants.testIcon),
                                      title: Text('Test'),
                                      dense: true,
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: ListTile(
                                      leading: Icon(Icons.edit),
                                      title: Text('Edit Label'),
                                      dense: true,
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'toggle',
                                    child: ListTile(
                                      leading: Icon(
                                        position.isEnabled ? Icons.visibility_off : Icons.visibility,
                                      ),
                                      title: Text(position.isEnabled ? 'Disable' : 'Enable'),
                                      dense: true,
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'remove',
                                    child: ListTile(
                                      leading: Icon(Icons.delete, color: AppConstants.errorColor),
                                      title: Text('Remove'),
                                      dense: true,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () => _togglePosition(index),
                            ),
                          );
                        },
                      ),
              ),

              // Action buttons
              Container(
                padding: const EdgeInsets.all(AppConstants.mediumSpacing),
                decoration: const BoxDecoration(
                  color: AppConstants.surfaceColor,
                  border: Border(
                    top: BorderSide(color: AppConstants.statusIdleColor, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isSelectionMode ? _exitSelectionMode : _enterSelectionMode,
                        icon: Icon(_isSelectionMode ? Icons.close : Icons.add),
                        label: Text(_isSelectionMode ? 'Cancel' : 'Add Position'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isSelectionMode 
                              ? AppConstants.errorColor 
                              : AppConstants.primaryColor,
                        ),
                      ),
                    ),
                    if (_positions.isNotEmpty) ...[
                      AppConstants.mediumSpacing.horizontalSpace,
                      ElevatedButton.icon(
                        onPressed: _clearAllPositions,
                        icon: const Icon(Icons.clear_all),
                        label: const Text('Clear All'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.warningColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // Selection overlay
          if (_isSelectionMode)
            Positioned.fill(
              child: GestureDetector(
                onTapDown: (details) {
                  _addPosition(details.globalPosition);
                  _exitSelectionMode();
                },
                child: Container(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  child: Center(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppConstants.largeSpacing),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              AppConstants.positionIcon,
                              size: 48,
                              color: AppConstants.primaryColor,
                            ),
                            AppConstants.mediumSpacing.verticalSpace,
                            const Text(
                              'Tap Anywhere',
                              style: AppConstants.subheadingStyle,
                            ),
                            AppConstants.smallSpacing.verticalSpace,
                            const Text(
                              'Touch the screen where you want clicks to occur',
                              style: AppConstants.captionStyle,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Position indicators overlay (when not in selection mode)
          if (!_isSelectionMode && _positions.isNotEmpty)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: PositionOverlayPainter(_positions),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class PositionOverlayPainter extends CustomPainter {
  final List<ClickPosition> positions;

  PositionOverlayPainter(this.positions);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < positions.length; i++) {
      final position = positions[i];
      
      // Draw position indicator
      final paint = Paint()
        ..color = position.isEnabled 
            ? AppConstants.successColor.withOpacity(0.7)
            : AppConstants.statusIdleColor.withOpacity(0.7)
        ..style = PaintingStyle.fill;

      final center = Offset(position.x, position.y);
      canvas.drawCircle(center, 20, paint);

      // Draw position number
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        center - Offset(textPainter.width / 2, textPainter.height / 2),
      );

      // Draw ripple effect for enabled positions
      if (position.isEnabled) {
        final ripplePaint = Paint()
          ..color = AppConstants.successColor.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

        canvas.drawCircle(center, 30, ripplePaint);
      }
    }
  }

  @override
  bool shouldRepaint(PositionOverlayPainter oldDelegate) {
    return oldDelegate.positions != positions;
  }
}