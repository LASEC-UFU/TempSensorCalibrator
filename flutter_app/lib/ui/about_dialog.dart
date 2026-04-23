import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;

import '../domain/sensor_model.dart';
import 'theme/app_palette.dart';

/// Mostra um diálogo "Sobre" com o conteúdo markdown do sensor selecionado.
///
/// O conteúdo é carregado de `assets/about/<file>.md`:
///   * NTC          -> ntc.md
///   * RTD          -> rtd.md
///   * Termopares   -> tc.md  (compartilhado por todos os tipos)
///   * fallback     -> default.md
Future<void> showSensorAboutDialog(
  BuildContext context, {
  required SensorModel sensor,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _AboutDialog(sensor: sensor),
  );
}

String _assetForSensor(String id) {
  if (id == 'ntc') return 'assets/about/ntc.md';
  if (id == 'rtd') return 'assets/about/rtd.md';
  if (id.startsWith('tc')) return 'assets/about/tc.md';
  return 'assets/about/default.md';
}

class _AboutDialog extends StatelessWidget {
  const _AboutDialog({required this.sensor});
  final SensorModel sensor;

  @override
  Widget build(BuildContext context) {
    final accent = AppPalette.forSensorId(sensor.id);
    final size = MediaQuery.sizeOf(context);
    final maxWidth = size.width > 900 ? 820.0 : size.width - 40;
    final maxHeight = size.height - 100;

    return Dialog(
      backgroundColor: AppPalette.surface,
      insetPadding: const EdgeInsets.all(20),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: AppPalette.headerGradient,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14)),
              ),
              padding: const EdgeInsets.fromLTRB(18, 14, 8, 14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.info_outline,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sobre o modelo',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                        Text(
                          sensor.displayName,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    tooltip: 'Fechar',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: FutureBuilder<String>(
                future: rootBundle.loadString(_assetForSensor(sensor.id)),
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snap.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Erro ao carregar conteúdo:\n${snap.error}',
                        style: const TextStyle(color: AppPalette.error),
                      ),
                    );
                  }
                  return _MarkdownWithMath(
                    content: snap.data ?? '',
                    accent: accent,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Renderizador de Markdown com suporte a LaTeX via `$...$` (inline) e
/// `$$...$$` (bloco), usando flutter_math_fork.
class _MarkdownWithMath extends StatelessWidget {
  const _MarkdownWithMath({required this.content, required this.accent});
  final String content;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final extensionSet = md.ExtensionSet(
      <md.BlockSyntax>[
        const _MathBlockSyntax(),
        ...md.ExtensionSet.gitHubFlavored.blockSyntaxes,
      ],
      <md.InlineSyntax>[
        _MathInlineSyntax(),
        ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
      ],
    );

    final styleSheet = MarkdownStyleSheet(
      h1: const TextStyle(
        color: AppPalette.textPrimary,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        height: 1.3,
      ),
      h2: TextStyle(
        color: accent,
        fontSize: 17,
        fontWeight: FontWeight.w700,
        height: 1.4,
      ),
      h3: const TextStyle(
        color: AppPalette.textPrimary,
        fontSize: 14.5,
        fontWeight: FontWeight.w700,
      ),
      p: const TextStyle(
        color: AppPalette.textPrimary,
        fontSize: 14,
        height: 1.55,
      ),
      strong: const TextStyle(
        color: AppPalette.textPrimary,
        fontWeight: FontWeight.w700,
      ),
      em: const TextStyle(
        color: AppPalette.textSecondary,
        fontStyle: FontStyle.italic,
      ),
      a: TextStyle(
        color: accent,
        decoration: TextDecoration.underline,
      ),
      blockquote: const TextStyle(
        color: AppPalette.textSecondary,
        fontSize: 13.5,
        fontStyle: FontStyle.italic,
        height: 1.5,
      ),
      blockquoteDecoration: BoxDecoration(
        color: AppPalette.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: accent, width: 3)),
      ),
      blockquotePadding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      code: const TextStyle(
        fontFamily: 'monospace',
        fontSize: 12.5,
        backgroundColor: AppPalette.surfaceAlt,
        color: AppPalette.textPrimary,
      ),
      codeblockDecoration: BoxDecoration(
        color: AppPalette.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppPalette.border),
      ),
      codeblockPadding: const EdgeInsets.all(12),
      tableHead: const TextStyle(
        fontWeight: FontWeight.w700,
        color: AppPalette.textPrimary,
        fontSize: 13,
      ),
      tableBody: const TextStyle(
        color: AppPalette.textPrimary,
        fontSize: 13,
      ),
      tableBorder: TableBorder.all(color: AppPalette.border, width: 1),
      tableHeadAlign: TextAlign.center,
      tableCellsPadding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      tableColumnWidth: const IntrinsicColumnWidth(),
      listBullet: const TextStyle(color: AppPalette.textPrimary),
      h2Padding: const EdgeInsets.only(top: 18, bottom: 6),
      h3Padding: const EdgeInsets.only(top: 14, bottom: 4),
      pPadding: const EdgeInsets.only(bottom: 6),
    );

    return Markdown(
      data: content,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      selectable: true,
      shrinkWrap: false,
      extensionSet: extensionSet,
      styleSheet: styleSheet,
      builders: {
        'math_inline': _MathBuilder(isBlock: false),
        'math_block': _MathBuilder(isBlock: true),
      },
      onTapLink: (text, href, title) async {
        // Sem launcher externo aqui — apenas tornamos selecionável.
      },
    );
  }
}

/// Sintaxe inline `$...$` e `$$...$$` (no mesmo parágrafo).
class _MathInlineSyntax extends md.InlineSyntax {
  _MathInlineSyntax()
      : super(r'\$\$([^\$]+?)\$\$|\$([^\$\n]+?)\$', startCharacter: 0x24);

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final block = match.group(1);
    final inline = match.group(2);
    final tex = (block ?? inline ?? '').trim();
    final el = md.Element.text(
      block != null ? 'math_block' : 'math_inline',
      tex,
    );
    parser.addNode(el);
    return true;
  }
}

/// Sintaxe de bloco: parágrafo iniciado por `$$` em linha própria.
class _MathBlockSyntax extends md.BlockSyntax {
  const _MathBlockSyntax();

  @override
  RegExp get pattern => RegExp(r'^\s*\$\$\s*$');

  @override
  bool canParse(md.BlockParser parser) {
    return pattern.hasMatch(parser.current.content);
  }

  @override
  md.Node? parse(md.BlockParser parser) {
    parser.advance(); // consome $$
    final buf = StringBuffer();
    while (!parser.isDone) {
      if (pattern.hasMatch(parser.current.content)) {
        parser.advance();
        break;
      }
      if (buf.isNotEmpty) buf.writeln();
      buf.write(parser.current.content);
      parser.advance();
    }
    return md.Element.text('math_block', buf.toString().trim());
  }
}

class _MathBuilder extends MarkdownElementBuilder {
  _MathBuilder({required this.isBlock});
  final bool isBlock;

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final tex = element.textContent;
    final color = preferredStyle?.color ?? AppPalette.textPrimary;
    if (isBlock) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Math.tex(
            tex,
            mathStyle: MathStyle.display,
            textStyle: TextStyle(color: color, fontSize: 16),
            onErrorFallback: (e) => _texError(tex, e.message),
          ),
        ),
      );
    }
    return Math.tex(
      tex,
      mathStyle: MathStyle.text,
      textStyle: TextStyle(color: color, fontSize: 14),
      onErrorFallback: (e) => _texError(tex, e.message),
    );
  }

  Widget _texError(String tex, String msg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppPalette.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          tex,
          style: const TextStyle(
            fontFamily: 'monospace',
            color: AppPalette.error,
            fontSize: 12,
          ),
        ),
      );
}
