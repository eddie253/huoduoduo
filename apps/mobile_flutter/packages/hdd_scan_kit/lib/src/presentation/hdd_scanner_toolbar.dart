import 'package:flutter/material.dart';

class HddScannerToolbar extends StatelessWidget {
  const HddScannerToolbar({
    super.key,
    required this.torchOn,
    required this.onToggleTorch,
    required this.onManualInput,
    required this.onOpenSettings,
    this.toolRowKey,
    this.flashButtonKey,
    this.keypadButtonKey,
    this.settingButtonKey,
  });

  final bool torchOn;
  final VoidCallback onToggleTorch;
  final VoidCallback onManualInput;
  final VoidCallback onOpenSettings;

  final Key? toolRowKey;
  final Key? flashButtonKey;
  final Key? keypadButtonKey;
  final Key? settingButtonKey;

  static const Color _toolBackdropColor = Color(0x8C000000);

  @override
  Widget build(BuildContext context) {
    return Row(
      key: toolRowKey,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _ToolIconButton(
          buttonKey: flashButtonKey,
          icon: torchOn
              ? Icons.flashlight_off_outlined
              : Icons.flashlight_on_outlined,
          onPressed: onToggleTorch,
        ),
        const SizedBox(width: 20),
        _ToolIconButton(
          buttonKey: keypadButtonKey,
          icon: Icons.dialpad_outlined,
          onPressed: onManualInput,
        ),
        const SizedBox(width: 20),
        _ToolIconButton(
          buttonKey: settingButtonKey,
          icon: Icons.settings_outlined,
          onPressed: onOpenSettings,
        ),
      ],
    );
  }
}

class _ToolIconButton extends StatelessWidget {
  const _ToolIconButton({
    required this.buttonKey,
    required this.icon,
    required this.onPressed,
  });

  final Key? buttonKey;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: buttonKey,
      borderRadius: BorderRadius.circular(999),
      onTap: onPressed,
      child: Container(
        width: 60,
        height: 60,
        decoration: const BoxDecoration(
          color: HddScannerToolbar._toolBackdropColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}
