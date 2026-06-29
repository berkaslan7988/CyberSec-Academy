import 'package:flutter/material.dart';

/// Tiny zero-dependency Markdown renderer covering what lesson content needs:
///   # / ## / ###  headings
///   ```           fenced code blocks (monospace, dark surface)
///   - / *         bullet lists
///   > text        callouts (used for ethics/warning boxes)
///   **bold**, `inline code`
///   blank line    paragraph separator
class MarkdownView extends StatelessWidget {
  final String data;
  const MarkdownView(this.data, {super.key});

  // Internal separator used to pack bullet items into one string.
  static const String _sep = '';

  @override
  Widget build(BuildContext context) {
    final blocks = _parseBlocks(data);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final b in blocks) ...[
          _buildBlock(context, b),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  List<_Block> _parseBlocks(String src) {
    final lines = src.replaceAll('\r\n', '\n').split('\n');
    final blocks = <_Block>[];
    var i = 0;
    final para = <String>[];

    void flushPara() {
      if (para.isNotEmpty) {
        blocks.add(_Block(_BlockType.paragraph, para.join(' ').trim()));
        para.clear();
      }
    }

    while (i < lines.length) {
      final line = lines[i];
      final trimmed = line.trimRight();

      if (trimmed.trimLeft().startsWith('```')) {
        flushPara();
        final code = <String>[];
        i++;
        while (i < lines.length && !lines[i].trimLeft().startsWith('```')) {
          code.add(lines[i]);
          i++;
        }
        i++; // skip closing fence
        blocks.add(_Block(_BlockType.code, code.join('\n')));
        continue;
      }
      if (trimmed.isEmpty) {
        flushPara();
        i++;
        continue;
      }
      if (trimmed.startsWith('### ')) {
        flushPara();
        blocks.add(_Block(_BlockType.h3, trimmed.substring(4)));
      } else if (trimmed.startsWith('## ')) {
        flushPara();
        blocks.add(_Block(_BlockType.h2, trimmed.substring(3)));
      } else if (trimmed.startsWith('# ')) {
        flushPara();
        blocks.add(_Block(_BlockType.h1, trimmed.substring(2)));
      } else if (trimmed.startsWith('> ')) {
        flushPara();
        final quote = <String>[trimmed.substring(2)];
        while (i + 1 < lines.length && lines[i + 1].trimLeft().startsWith('> ')) {
          i++;
          quote.add(lines[i].trimLeft().substring(2));
        }
        blocks.add(_Block(_BlockType.quote, quote.join(' ')));
      } else if (trimmed.trimLeft().startsWith('- ') ||
          trimmed.trimLeft().startsWith('* ')) {
        flushPara();
        final items = <String>[trimmed.trimLeft().substring(2)];
        while (i + 1 < lines.length) {
          final n = lines[i + 1].trimLeft();
          if (n.startsWith('- ') || n.startsWith('* ')) {
            i++;
            items.add(n.substring(2));
          } else {
            break;
          }
        }
        blocks.add(_Block(_BlockType.bullets, items.join(_sep)));
      } else {
        para.add(trimmed);
      }
      i++;
    }
    flushPara();
    return blocks;
  }

  Widget _buildBlock(BuildContext context, _Block b) {
    final t = Theme.of(context).textTheme;
    switch (b.type) {
      case _BlockType.h1:
        return Text(b.text,
            style: t.headlineSmall?.copyWith(fontWeight: FontWeight.bold));
      case _BlockType.h2:
        return Text(b.text,
            style: t.titleLarge?.copyWith(fontWeight: FontWeight.bold));
      case _BlockType.h3:
        return Text(b.text,
            style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600));
      case _BlockType.paragraph:
        return _inline(context, b.text, t.bodyMedium);
      case _BlockType.bullets:
        final items = b.text.split(_sep);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final it in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  '),
                    Expanded(child: _inline(context, it, t.bodyMedium)),
                  ],
                ),
              ),
          ],
        );
      case _BlockType.code:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1117),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white24),
          ),
          child: SelectableText(
            b.text,
            style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13.5,
                color: Color(0xFF9CDCFE)),
          ),
        );
      case _BlockType.quote:
        final c = Theme.of(context).colorScheme;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: c.tertiaryContainer.withOpacity(0.4),
            borderRadius: BorderRadius.circular(8),
            border: Border(left: BorderSide(color: c.tertiary, width: 4)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.shield_outlined, size: 18),
              const SizedBox(width: 8),
              Expanded(child: _inline(context, b.text, t.bodyMedium)),
            ],
          ),
        );
    }
  }

  /// Renders inline **bold** and `code` spans within a paragraph.
  Widget _inline(BuildContext context, String text, TextStyle? base) {
    final spans = <InlineSpan>[];
    final pattern = RegExp(r'(\*\*[^*]+\*\*|`[^`]+`)');
    var last = 0;
    for (final m in pattern.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start)));
      }
      final tok = m.group(0)!;
      if (tok.startsWith('**')) {
        spans.add(TextSpan(
            text: tok.substring(2, tok.length - 2),
            style: const TextStyle(fontWeight: FontWeight.bold)));
      } else {
        spans.add(TextSpan(
            text: tok.substring(1, tok.length - 1),
            style: const TextStyle(
                fontFamily: 'monospace',
                backgroundColor: Color(0x33888888),
                fontSize: 13.5)));
      }
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
    return RichText(
      text: TextSpan(
          style: base ?? DefaultTextStyle.of(context).style, children: spans),
    );
  }
}

enum _BlockType { h1, h2, h3, paragraph, bullets, code, quote }

class _Block {
  final _BlockType type;
  final String text;
  const _Block(this.type, this.text);
}
