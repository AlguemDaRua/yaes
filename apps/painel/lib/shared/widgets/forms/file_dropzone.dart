// Tradução fiel de _design/showcases/dropzone.jsx (componente Zone/FileDropzone).
// Estados: idle, hover, uploading, success, error.

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../theme/tokens/colors.dart';
import '../../../theme/tokens/dimensions.dart';
import '../../../theme/tokens/typography.dart';

enum FileDropzoneState { idle, hover, uploading, success, error }

/// Dropzone para ficheiros: PDF/JPG/PNG/etc.
///
/// O state é controlado pelo consumidor (página ou form). O dropzone só
/// renderiza visual + dispara `onTap` (para abrir picker) ou `onClear`
/// (no estado success). Drag-and-drop nativo é responsabilidade do caller
/// envolver com `DropTarget` (do package `desktop_drop`).
class FileDropzone extends StatefulWidget {
  const FileDropzone({
    required this.label,
    this.subtitle,
    this.state = FileDropzoneState.idle,
    this.fileName,
    this.progress = 0.0,
    this.errorMessage,
    this.onTap,
    this.onClear,
    this.fileNames = const [],
    this.onRemove,
    this.multiple = false,
    super.key,
  });

  final String label;
  final String? subtitle;
  final FileDropzoneState state;

  /// Nome do ficheiro (para uploading/success).
  final String? fileName;

  /// Progresso 0..1 (para uploading).
  final double progress;

  /// Mensagem de erro (para error).
  final String? errorMessage;

  /// Acção principal (abrir file picker).
  final VoidCallback? onTap;

  /// Limpar ficheiro carregado (botão X em success).
  final VoidCallback? onClear;

  /// Lista de ficheiros ja carregados (para estado success com multiplos).
  /// Se fornecida, tem prioridade sobre [fileName].
  final List<String> fileNames;

  /// Chamado com o indice quando o user remove um ficheiro da lista.
  final void Function(int index)? onRemove;

  /// Se true, o label/subtitulo sugere multiplos ficheiros.
  final bool multiple;

  @override
  State<FileDropzone> createState() => _FileDropzoneState();
}

class _FileDropzoneState extends State<FileDropzone> {
  bool _hovering = false;

  bool get _isInteractive =>
      widget.state == FileDropzoneState.idle ||
      widget.state == FileDropzoneState.hover;

  /// Estado efectivo: combina prop com hover interno.
  FileDropzoneState get _effective {
    if (widget.state != FileDropzoneState.idle) return widget.state;
    return _hovering ? FileDropzoneState.hover : FileDropzoneState.idle;
  }

  /// Usa [widget.fileNames] se nao estiver vazio, senao usa [widget.fileName].
  List<String> get _effectiveFileNames {
    if (widget.fileNames.isNotEmpty) return widget.fileNames;
    if (widget.fileName != null) return [widget.fileName!];
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    final state = _effective;
    final palette = _palette(colors, state);

    final body = AnimatedContainer(
      duration: YaDurations.micro,
      curve: YaDurations.easeOut,
      constraints: const BoxConstraints(minHeight: 180),
      padding: const EdgeInsets.all(YaSpacing.xxl),
      decoration: BoxDecoration(
        color: palette.bg,
        borderRadius: YaRadius.brLg,
        border: Border.all(
          color: palette.borderColor,
          width: 2,
          style: palette.dashed ? BorderStyle.solid : BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIconCircle(colors, state, palette),
          const SizedBox(height: YaSpacing.md),
          Text(
            widget.label,
            textAlign: TextAlign.center,
            style: YaText.baseMedium.copyWith(color: colors.textPrimary),
          ),
          if (widget.subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              widget.subtitle!,
              textAlign: TextAlign.center,
              style: YaText.sans(size: 12, height: 16)
                  .copyWith(color: colors.textSecondary),
            ),
          ],
          if (state == FileDropzoneState.uploading)
            _buildUploadingProgress(colors),
          if (state == FileDropzoneState.success &&
              _effectiveFileNames.isNotEmpty)
            _buildSuccessFileList(colors),
          if (state == FileDropzoneState.error &&
              widget.errorMessage != null) ...[
            const SizedBox(height: YaSpacing.md),
            Text(
              widget.errorMessage!,
              textAlign: TextAlign.center,
              style: YaText.sans(size: 12, height: 16)
                  .copyWith(color: colors.danger),
            ),
          ],
        ],
      ),
    );

    if (!_isInteractive) return body;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: body,
      ),
    );
  }

  Widget _buildIconCircle(
    YaColors colors,
    FileDropzoneState state,
    _DropzonePalette p,
  ) {
    final icon = switch (state) {
      FileDropzoneState.success => LucideIcons.check,
      FileDropzoneState.error => LucideIcons.triangleAlert,
      FileDropzoneState.uploading => LucideIcons.fileText,
      FileDropzoneState.idle || FileDropzoneState.hover => LucideIcons.arrowUp,
    };

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: p.iconBg,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 28, color: p.iconColor),
    );
  }

  Widget _buildUploadingProgress(YaColors colors) {
    final percent = (widget.progress * 100).round();
    return Padding(
      padding: const EdgeInsets.only(top: YaSpacing.md),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    widget.fileName ?? '',
                    style: YaText.mono(size: 12, height: 16)
                        .copyWith(color: colors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: YaSpacing.sm),
                Text(
                  '$percent%',
                  style: YaText.mono(size: 12, height: 16)
                      .copyWith(color: colors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(9999),
              child: SizedBox(
                height: 6,
                child: LinearProgressIndicator(
                  value: widget.progress.clamp(0.0, 1.0),
                  backgroundColor: colors.bgSubtle,
                  valueColor: AlwaysStoppedAnimation(colors.brand),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessFileList(YaColors colors) {
    final names = _effectiveFileNames;
    return Padding(
      padding: const EdgeInsets.only(top: YaSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < names.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i < names.length - 1 ? 6 : 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      names[i],
                      style: YaText.mono(size: 12, height: 16)
                          .copyWith(color: colors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.onRemove != null ||
                      (i == 0 && widget.onClear != null)) ...[
                    const SizedBox(width: YaSpacing.sm),
                    _ClearButton(
                      onTap: widget.onRemove != null
                          ? () => widget.onRemove!(i)
                          : widget.onClear,
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  _DropzonePalette _palette(YaColors c, FileDropzoneState state) {
    return switch (state) {
      FileDropzoneState.idle => _DropzonePalette(
          bg: c.bgSurface,
          borderColor: c.borderDefault,
          iconBg: c.bgSubtle,
          iconColor: c.textMuted,
          dashed: true,
        ),
      FileDropzoneState.hover => _DropzonePalette(
          bg: c.brandSubtle,
          borderColor: c.brandBorder,
          iconBg: c.bgSubtle,
          iconColor: c.brand,
          dashed: true,
        ),
      FileDropzoneState.uploading => _DropzonePalette(
          bg: c.bgSurface,
          borderColor: c.brandBorder,
          iconBg: c.bgSubtle,
          iconColor: c.brand,
          dashed: false,
        ),
      FileDropzoneState.success => _DropzonePalette(
          bg: c.successSubtle,
          borderColor: c.successBorder,
          iconBg: c.success.withValues(alpha: 0.15),
          iconColor: c.success,
          dashed: false,
        ),
      FileDropzoneState.error => _DropzonePalette(
          bg: c.dangerSubtle,
          borderColor: c.dangerBorder,
          iconBg: c.danger.withValues(alpha: 0.15),
          iconColor: c.danger,
          dashed: false,
        ),
    };
  }
}

class _DropzonePalette {
  const _DropzonePalette({
    required this.bg,
    required this.borderColor,
    required this.iconBg,
    required this.iconColor,
    required this.dashed,
  });
  final Color bg;
  final Color borderColor;
  final Color iconBg;
  final Color iconColor;

  /// Border tracejada (idle/hover). Flutter não tem dashed nativo —
  /// limitação assumida; usa-se solid em todos os casos.
  final bool dashed;
}

class _ClearButton extends StatefulWidget {
  const _ClearButton({this.onTap});
  final VoidCallback? onTap;

  @override
  State<_ClearButton> createState() => _ClearButtonState();
}

class _ClearButtonState extends State<_ClearButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Icon(
          LucideIcons.x,
          size: 12,
          color: _hovering ? colors.textSecondary : colors.textMuted,
        ),
      ),
    );
  }
}
