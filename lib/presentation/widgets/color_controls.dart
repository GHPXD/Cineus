import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/color_training_session.dart';
import '../../l10n/app_l10n.dart';
import '../visuals/cineus_assets.dart';
import 'cineus_icon.dart';

class ColorControls extends StatefulWidget {
  final ColorSelection selection;
  final ValueChanged<ColorSelection> onChanged;
  final VoidCallback? onChangeEnd;
  final bool enabled;
  final bool compact;
  const ColorControls({
    super.key,
    required this.selection,
    required this.onChanged,
    this.onChangeEnd,
    this.enabled = true,
    this.compact = false,
  });
  @override
  State<ColorControls> createState() => _ColorControlsState();
}

class _ColorControlsState extends State<ColorControls> {
  bool _editing = false;
  int _channel = 0;
  String _number(double value) => NumberFormat(
    '0.##',
    Localizations.localeOf(context).languageCode,
  ).format(value);
  void _choose(double value, ColorSelection Function(double) next) {
    if (!widget.enabled) return;
    widget.onChanged(next(value));
    widget.onChangeEnd?.call();
  }

  Future<void> _exact(
    String id,
    String label,
    double value,
    double max,
    ColorSelection Function(double) next,
  ) async {
    if (_editing || !widget.enabled) return;
    _editing = true;
    try {
      final result = await showDialog<double>(
        context: context,
        builder: (_) => _ColorValueDialog(
          id: id,
          label: label,
          value: Localizations.localeOf(context).languageCode == 'en'
              ? value.toString()
              : value.toString().replaceAll('.', ','),
          max: max,
        ),
      );
      if (result != null && mounted) _choose(result, next);
    } finally {
      _editing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context), s = widget.selection;
    final hsv = HSVColor.fromAHSV(
      1,
      s.hue,
      s.saturation / 100,
      s.brightness / 100,
    );
    return Column(
      children: [
        if (widget.compact) ...[
          LayoutBuilder(
            builder: (context, c) {
              final stacked = MediaQuery.textScalerOf(context).scale(14) > 22;
              Widget tab(int index, String label) => TextButton(
                key: ValueKey('colors-channel-$index'),
                onPressed: widget.enabled
                    ? () => setState(() => _channel = index)
                    : null,
                style: TextButton.styleFrom(
                  foregroundColor: _channel == index
                      ? AppColors.obsidian950
                      : AppColors.textSecondary,
                  backgroundColor: _channel == index
                      ? AppColors.gold200
                      : Colors.transparent,
                  minimumSize: const Size(48, 40),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  textStyle: AppTypography.bodySmall.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Semantics(
                  selected: _channel == index,
                  child: Text(label, textAlign: TextAlign.center),
                ),
              );
              final labels = [l.colorHue, l.colorSaturation, l.colorBrightness];
              return Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFF14223B),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: AppColors.obsidian600),
                ),
                child: stacked
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final e in labels.indexed) tab(e.$1, e.$2),
                        ],
                      )
                    : Row(
                        children: [
                          for (final e in labels.indexed)
                            Expanded(child: tab(e.$1, e.$2)),
                        ],
                      ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
        if (!widget.compact || _channel == 0)
          _slider(
            'hue',
            l.colorHue,
            s.hue,
            360,
            [
              for (final h in [0.0, 60.0, 120.0, 180.0, 240.0, 300.0, 360.0])
                HSVColor.fromAHSV(1, h, 1, 1).toColor(),
            ],
            (v) => ColorSelection(
              v,
              widget.selection.saturation,
              widget.selection.brightness,
            ),
            degrees: true,
          ),
        if (!widget.compact || _channel == 1)
          _slider(
            'saturation',
            l.colorSaturation,
            s.saturation,
            100,
            [hsv.withSaturation(0).toColor(), hsv.withSaturation(1).toColor()],
            (v) => ColorSelection(
              widget.selection.hue,
              v,
              widget.selection.brightness,
            ),
          ),
        if (!widget.compact || _channel == 2)
          _slider(
            'brightness',
            l.colorBrightness,
            s.brightness,
            100,
            [hsv.withValue(0).toColor(), hsv.withValue(1).toColor()],
            (v) => ColorSelection(
              widget.selection.hue,
              widget.selection.saturation,
              v,
            ),
          ),
      ],
    );
  }

  Widget _slider(
    String id,
    String label,
    double value,
    double max,
    List<Color> gradient,
    ColorSelection Function(double) next, {
    bool degrees = false,
  }) {
    final l = AppL10n.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final number = TextButton(
                key: ValueKey('colors-$id-exact'),
                onPressed: widget.enabled
                    ? () => _exact(id, label, value, max, next)
                    : null,
                child: Text(
                  '${_number(value)}${degrees ? '°' : '%'}',
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: widget.compact ? 22 : 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gold200,
                  ),
                ),
              );
              if (widget.compact) {
                return Row(
                  children: [
                    _nudge(id, label, value, max, next, false),
                    Expanded(child: number),
                    _nudge(id, label, value, max, next, true),
                  ],
                );
              }
              if (MediaQuery.textScalerOf(context).scale(16) > 22 ||
                  constraints.maxWidth < 300) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(label, style: AppTypography.bodyMedium),
                    Row(
                      children: [
                        _nudge(id, label, value, max, next, false),
                        Expanded(child: number),
                        _nudge(id, label, value, max, next, true),
                      ],
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: Text(label, style: AppTypography.bodyMedium)),
                  _nudge(id, label, value, max, next, false),
                  Flexible(child: number),
                  _nudge(id, label, value, max, next, true),
                ],
              );
            },
          ),
          Semantics(
            label: label,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: widget.compact ? 12 : 6,
                thumbShape: RoundSliderThumbShape(
                  enabledThumbRadius: widget.compact ? 13 : 10,
                ),
                activeTrackColor: Colors.transparent,
                inactiveTrackColor: Colors.transparent,
                thumbColor: AppColors.obsidian0,
                overlayColor: AppColors.gold300.withValues(alpha: .12),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: 24,
                    right: 24,
                    child: Container(
                      height: widget.compact ? 12 : 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(colors: gradient),
                      ),
                    ),
                  ),
                  Slider(
                    key: ValueKey('colors-$id'),
                    value: value,
                    min: 0,
                    max: max,
                    divisions: max.toInt(),
                    semanticFormatterCallback: (v) =>
                        l.colorExactSemantic(max.toInt(), _number(v)),
                    onChanged: widget.enabled
                        ? (v) => widget.onChanged(next(v))
                        : null,
                    onChangeEnd: widget.enabled && widget.onChangeEnd != null
                        ? (_) => widget.onChangeEnd!()
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _nudge(
    String id,
    String label,
    double value,
    double max,
    ColorSelection Function(double) next,
    bool increase,
  ) {
    final l = AppL10n.of(context);
    return IconButton(
      key: ValueKey('colors-$id-${increase ? 'more' : 'less'}'),
      style: widget.compact
          ? IconButton.styleFrom(
              backgroundColor: const Color(0xFF17243A),
              side: const BorderSide(color: AppColors.obsidian600),
              shape: const CircleBorder(),
            )
          : null,
      tooltip: increase ? l.colorIncrease(label) : l.colorDecrease(label),
      onPressed: !widget.enabled || (increase ? value >= max : value <= 0)
          ? null
          : () => _choose((value + (increase ? 1 : -1)).clamp(0, max), next),
      icon: Transform.rotate(
        angle: increase ? 0 : 3.141592653589793,
        child: const CineusIcon(CineusAssetId.chevron, size: 20),
      ),
    );
  }
}

class _ColorValueDialog extends StatefulWidget {
  final String id, label, value;
  final double max;
  const _ColorValueDialog({
    required this.id,
    required this.label,
    required this.value,
    required this.max,
  });
  @override
  State<_ColorValueDialog> createState() => _ColorValueDialogState();
}

class _ColorValueDialogState extends State<_ColorValueDialog> {
  late final _input = TextEditingController(text: widget.value);
  String? _error;
  bool _submitted = false;
  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _accept() {
    if (_submitted) return;
    final parsed = double.tryParse(_input.text.trim().replaceAll(',', '.'));
    if (parsed == null ||
        !parsed.isFinite ||
        parsed < 0 ||
        parsed > widget.max) {
      setState(
        () =>
            _error = AppL10n.of(context).colorExactInvalid(widget.max.toInt()),
      );
      return;
    }
    _submitted = true;
    Navigator.of(context).pop(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return AlertDialog(
      scrollable: true,
      title: Text(l.colorExactTitle(widget.label)),
      content: TextField(
        key: ValueKey('colors-${widget.id}-input'),
        controller: _input,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: widget.label,
          helperText: l.colorExactRange(widget.max.toInt()),
          errorText: _error,
          helperMaxLines: 3,
          errorMaxLines: 3,
        ),
        onSubmitted: (_) => _accept(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.colorExactCancel),
        ),
        FilledButton(
          key: const ValueKey('colors-exact-apply'),
          onPressed: _accept,
          child: Text(l.colorExactApply),
        ),
      ],
    );
  }
}
