import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_math_fork/flutter_math.dart';

import '../domain/sensor_model.dart';
import 'theme/app_palette.dart';

/// Mostra um diálogo "Sobre" com o conteúdo markdown do sensor selecionado.
///
/// Conteúdo é carregado de `assets/about/<arquivo>.md`:
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
        constraints:
            BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Header(sensor: sensor, accent: accent),
            Flexible(
              child: Container(
                width: double.infinity,
                color: AppPalette.surface,
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
                    return SingleChildScrollView(
                      padding:
                          const EdgeInsets.fromLTRB(22, 18, 22, 24),
                      child: _MarkdownRenderer(
                        content: snap.data ?? '',
                        accent: accent,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.sensor, required this.accent});
  final SensorModel sensor;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppPalette.headerGradient,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(14)),
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
              border:
                  Border.all(color: Colors.white.withValues(alpha: 0.3)),
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
    );
  }
}

// ---------------------------------------------------------------------------
// Renderer Markdown leve (suporta: # ## ###, parágrafos, listas -, blockquote >,
// código ```...```, tabelas | a | b |, blocos de matemática $$...$$ e
// matemática inline $...$, ênfases **bold** e *italic*, links [texto](url) e
// código inline `x`).
// ---------------------------------------------------------------------------

class _MarkdownRenderer extends StatelessWidget {
  const _MarkdownRenderer({required this.content, required this.accent});
  final String content;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final blocks = _splitBlocks(content);
    final widgets = <Widget>[];
    for (final b in blocks) {
      widgets.add(_renderBlock(b, accent));
      widgets.add(const SizedBox(height: 8));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: widgets,
    );
  }
}

class _Block {
  _Block(this.kind, this.text, {this.lines = const []});
  final String kind; // h1,h2,h3,p,ul,ol,blockquote,code,math,table,hr
  final String text;
  final List<String> lines;
}

List<_Block> _splitBlocks(String src) {
  final lines = src.replaceAll('\r\n', '\n').split('\n');
  final blocks = <_Block>[];
  var i = 0;
  while (i < lines.length) {
    var line = lines[i];
    final t = line.trim();

    // linhas vazias
    if (t.isEmpty) {
      i++;
      continue;
    }

    // hr ---
    if (RegExp(r'^-{3,}$').hasMatch(t)) {
      blocks.add(_Block('hr', ''));
      i++;
      continue;
    }

    // headings
    if (t.startsWith('### ')) {
      blocks.add(_Block('h3', t.substring(4)));
      i++;
      continue;
    }
    if (t.startsWith('## ')) {
      blocks.add(_Block('h2', t.substring(3)));
      i++;
      continue;
    }
    if (t.startsWith('# ')) {
      blocks.add(_Block('h1', t.substring(2)));
      i++;
      continue;
    }

    // math block $$...$$
    if (t == r'$$') {
      i++;
      final buf = <String>[];
      while (i < lines.length && lines[i].trim() != r'$$') {
        buf.add(lines[i]);
        i++;
      }
      if (i < lines.length) i++; // consome $$ final
      blocks.add(_Block('math', buf.join('\n').trim()));
      continue;
    }

    // code block ```
    if (t.startsWith('```')) {
      i++;
      final buf = <String>[];
      while (i < lines.length && !lines[i].trim().startsWith('```')) {
        buf.add(lines[i]);
        i++;
      }
      if (i < lines.length) i++;
      blocks.add(_Block('code', buf.join('\n')));
      continue;
    }

    // tabela | a | b |
    if (t.startsWith('|') && t.endsWith('|')) {
      final tableLines = <String>[];
      while (i < lines.length &&
          lines[i].trim().startsWith('|') &&
          lines[i].trim().endsWith('|')) {
        tableLines.add(lines[i].trim());
        i++;
      }
      blocks.add(_Block('table', '', lines: tableLines));
      continue;
    }

    // blockquote > ...
    if (t.startsWith('> ')) {
      final buf = <String>[];
      while (i < lines.length && lines[i].trim().startsWith('> ')) {
        buf.add(lines[i].trim().substring(2));
        i++;
      }
      blocks.add(_Block('blockquote', buf.join(' ')));
      continue;
    }

    // ul/ol
    if (RegExp(r'^[-*]\s').hasMatch(t)) {
      final items = <String>[];
      while (i < lines.length &&
          RegExp(r'^[-*]\s').hasMatch(lines[i].trim())) {
        items.add(lines[i].trim().substring(2));
        i++;
      }
      blocks.add(_Block('ul', '', lines: items));
      continue;
    }
    if (RegExp(r'^\d+\.\s').hasMatch(t)) {
      final items = <String>[];
      while (i < lines.length &&
          RegExp(r'^\d+\.\s').hasMatch(lines[i].trim())) {
        items
            .add(lines[i].trim().replaceFirst(RegExp(r'^\d+\.\s'), ''));
        i++;
      }
      blocks.add(_Block('ol', '', lines: items));
      continue;
    }

    // parágrafo: junta linhas até próxima vazia/heading/etc.
    final pbuf = <String>[];
    while (i < lines.length) {
      final cur = lines[i];
      final ct = cur.trim();
      if (ct.isEmpty) break;
      if (ct.startsWith('#') ||
          ct.startsWith('```') ||
          ct.startsWith('> ') ||
          ct == r'$$' ||
          (ct.startsWith('|') && ct.endsWith('|')) ||
          RegExp(r'^[-*]\s').hasMatch(ct) ||
          RegExp(r'^\d+\.\s').hasMatch(ct) ||
          RegExp(r'^-{3,}$').hasMatch(ct)) {
        break;
      }
      pbuf.add(cur);
      i++;
    }
    blocks.add(_Block('p', pbuf.join(' ')));
  }
  return blocks;
}

Widget _renderBlock(_Block b, Color accent) {
  switch (b.kind) {
    case 'h1':
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          b.text,
          style: const TextStyle(
            color: AppPalette.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            height: 1.3,
          ),
        ),
      );
    case 'h2':
      return Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: Text(
          b.text,
          style: TextStyle(
            color: accent,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            height: 1.4,
          ),
        ),
      );
    case 'h3':
      return Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 2),
        child: Text(
          b.text,
          style: const TextStyle(
            color: AppPalette.textPrimary,
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    case 'hr':
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Divider(color: AppPalette.divider, height: 1),
      );
    case 'math':
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Center(
          child: Math.tex(
            b.text,
            mathStyle: MathStyle.display,
            textStyle: const TextStyle(
              color: AppPalette.textPrimary,
              fontSize: 16,
            ),
            onErrorFallback: (e) => _texErr(b.text),
          ),
        ),
      );
    case 'code':
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppPalette.surfaceAlt,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppPalette.border),
        ),
        padding: const EdgeInsets.all(12),
        child: SelectableText(
          b.text,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 12.5,
            color: AppPalette.textPrimary,
            height: 1.4,
          ),
        ),
      );
    case 'blockquote':
      return Container(
        decoration: BoxDecoration(
          color: AppPalette.surfaceAlt,
          borderRadius: BorderRadius.circular(8),
          border: Border(left: BorderSide(color: accent, width: 3)),
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: _RichLine(
          text: b.text,
          baseStyle: const TextStyle(
            color: AppPalette.textSecondary,
            fontSize: 13.5,
            fontStyle: FontStyle.italic,
            height: 1.5,
          ),
          accent: accent,
        ),
      );
    case 'ul':
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in b.lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 7, right: 10),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _RichLine(
                      text: item,
                      baseStyle: _bodyStyle(),
                      accent: accent,
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    case 'ol':
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var k = 0; k < b.lines.length; k++)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 22,
                    child: Text(
                      '${k + 1}.',
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _RichLine(
                      text: b.lines[k],
                      baseStyle: _bodyStyle(),
                      accent: accent,
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    case 'table':
      return _renderTable(b.lines, accent);
    case 'p':
    default:
      return _RichLine(
        text: b.text,
        baseStyle: _bodyStyle(),
        accent: accent,
      );
  }
}

TextStyle _bodyStyle() => const TextStyle(
      color: AppPalette.textPrimary,
      fontSize: 14,
      height: 1.55,
    );

Widget _texErr(String tex) => Container(
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

Widget _renderTable(List<String> lines, Color accent) {
  if (lines.isEmpty) return const SizedBox.shrink();
  // separa cabeçalho / divisor / corpo
  List<String> splitRow(String row) {
    var r = row.trim();
    if (r.startsWith('|')) r = r.substring(1);
    if (r.endsWith('|')) r = r.substring(0, r.length - 1);
    return r.split('|').map((c) => c.trim()).toList();
  }

  final header = splitRow(lines.first);
  var bodyStart = 1;
  if (lines.length >= 2 &&
      RegExp(r'^[\|\s\-\:]+$').hasMatch(lines[1].trim())) {
    bodyStart = 2;
  }
  final body = lines.sublist(bodyStart).map(splitRow).toList();

  TableRow makeHeader() => TableRow(
        decoration: BoxDecoration(color: AppPalette.surfaceAlt),
        children: [
          for (final h in header)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: _RichLine(
                text: h,
                baseStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppPalette.textPrimary,
                  fontSize: 13,
                ),
                accent: accent,
              ),
            ),
        ],
      );

  TableRow makeRow(List<String> cells) => TableRow(
        children: [
          for (var k = 0; k < header.length; k++)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: _RichLine(
                text: k < cells.length ? cells[k] : '',
                baseStyle: const TextStyle(
                  color: AppPalette.textPrimary,
                  fontSize: 13,
                  height: 1.4,
                ),
                accent: accent,
              ),
            ),
        ],
      );

  return ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: Table(
      border: TableBorder.all(color: AppPalette.border, width: 1),
      defaultColumnWidth: const IntrinsicColumnWidth(),
      children: [
        makeHeader(),
        ...body.map(makeRow),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// _RichLine: renderiza uma linha de texto com:
//   * matemática inline $...$
//   * **negrito**, *itálico*, `código`, [link](url)
// produzindo um RichText com WidgetSpans para o LaTeX.
// ---------------------------------------------------------------------------

class _RichLine extends StatelessWidget {
  const _RichLine({
    required this.text,
    required this.baseStyle,
    required this.accent,
  });
  final String text;
  final TextStyle baseStyle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final spans = _buildSpans(text, baseStyle, accent);
    return SelectableText.rich(
      TextSpan(children: spans, style: baseStyle),
    );
  }
}

/// Tokeniza inline math `$...$` e formata o restante com **bold**, *italic*,
/// `code`, [link](url).
List<InlineSpan> _buildSpans(
  String src,
  TextStyle base,
  Color accent,
) {
  final spans = <InlineSpan>[];
  final mathRe = RegExp(r'\$([^\$\n]+?)\$');
  var idx = 0;
  for (final m in mathRe.allMatches(src)) {
    if (m.start > idx) {
      spans.addAll(_formatText(src.substring(idx, m.start), base, accent));
    }
    final tex = m.group(1) ?? '';
    spans.add(WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Math.tex(
        tex,
        mathStyle: MathStyle.text,
        textStyle: TextStyle(
          color: base.color,
          fontSize: (base.fontSize ?? 14),
        ),
        onErrorFallback: (e) => Text(
          '\$$tex\$',
          style: TextStyle(
            color: AppPalette.error,
            fontSize: base.fontSize,
            fontFamily: 'monospace',
          ),
        ),
      ),
    ));
    idx = m.end;
  }
  if (idx < src.length) {
    spans.addAll(_formatText(src.substring(idx), base, accent));
  }
  return spans;
}

/// Aplica `**bold**`, `*italic*`, `` `code` `` e `[txt](url)` num pedaço de
/// texto sem matemática.
List<InlineSpan> _formatText(String src, TextStyle base, Color accent) {
  // Regex unificada: cada alternativa captura.
  final re = RegExp(
    r'(\*\*[^*\n]+?\*\*)|(\*[^*\n]+?\*)|(`[^`\n]+?`)|(\[[^\]]+?\]\([^\)]+?\))',
  );
  final out = <InlineSpan>[];
  var idx = 0;
  for (final m in re.allMatches(src)) {
    if (m.start > idx) {
      out.add(TextSpan(text: src.substring(idx, m.start), style: base));
    }
    final s = m.group(0)!;
    if (s.startsWith('**')) {
      out.add(TextSpan(
        text: s.substring(2, s.length - 2),
        style: base.copyWith(fontWeight: FontWeight.w700),
      ));
    } else if (s.startsWith('*')) {
      out.add(TextSpan(
        text: s.substring(1, s.length - 1),
        style: base.copyWith(fontStyle: FontStyle.italic),
      ));
    } else if (s.startsWith('`')) {
      out.add(TextSpan(
        text: s.substring(1, s.length - 1),
        style: base.copyWith(
          fontFamily: 'monospace',
          fontSize: (base.fontSize ?? 14) * 0.92,
          backgroundColor: AppPalette.surfaceAlt,
        ),
      ));
    } else if (s.startsWith('[')) {
      final close = s.indexOf(']');
      final txt = s.substring(1, close);
      out.add(TextSpan(
        text: txt,
        style: base.copyWith(
          color: accent,
          decoration: TextDecoration.underline,
        ),
      ));
    } else {
      out.add(TextSpan(text: s, style: base));
    }
    idx = m.end;
  }
  if (idx < src.length) {
    out.add(TextSpan(text: src.substring(idx), style: base));
  }
  return out;
}
