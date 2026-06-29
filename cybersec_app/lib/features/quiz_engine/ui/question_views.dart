import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../models/question.dart';

/// Renders the answer-input UI for a question and reports the answer payload
/// upward via [onChanged]. The payload shape matches AnswerEvaluator.evaluate.
class QuestionView extends StatelessWidget {
  final Question question;
  final String lang;
  final bool locked; // after Check, disable input
  final ValueChanged<Object?> onChanged;

  const QuestionView({
    super.key,
    required this.question,
    required this.lang,
    required this.locked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    switch (question.type) {
      case QuestionType.multipleChoice:
        return _ChoiceView(
            key: ValueKey('mc_${question.id}'),
            question: question,
            lang: lang,
            multi: question.options.where((o) => o.correct).length > 1,
            locked: locked,
            onChanged: onChanged);
      case QuestionType.trueFalse:
        return _ChoiceView(
            key: ValueKey('tf_${question.id}'),
            question: question,
            lang: lang,
            multi: false,
            locked: locked,
            onChanged: onChanged);
      case QuestionType.command:
        return _TextView(
            key: ValueKey('cmd_${question.id}'),
            lang: lang,
            mono: true,
            locked: locked,
            onChanged: onChanged);
      case QuestionType.fillBlank:
        return _TextView(
            key: ValueKey('fb_${question.id}'),
            lang: lang,
            mono: false,
            locked: locked,
            onChanged: onChanged);
      case QuestionType.matching:
        return _MatchingView(
            key: ValueKey('mt_${question.id}'),
            question: question,
            lang: lang,
            locked: locked,
            onChanged: onChanged);
      case QuestionType.ordering:
        return _OrderingView(
            key: ValueKey('or_${question.id}'),
            question: question,
            lang: lang,
            locked: locked,
            onChanged: onChanged);
    }
  }
}

class _ChoiceView extends StatefulWidget {
  final Question question;
  final String lang;
  final bool multi;
  final bool locked;
  final ValueChanged<Object?> onChanged;
  const _ChoiceView(
      {super.key,
      required this.question,
      required this.lang,
      required this.multi,
      required this.locked,
      required this.onChanged});

  @override
  State<_ChoiceView> createState() => _ChoiceViewState();
}

class _ChoiceViewState extends State<_ChoiceView> {
  final Set<int> _selected = {};

  void _toggle(int i) {
    if (widget.locked) return;
    setState(() {
      if (widget.multi) {
        _selected.contains(i) ? _selected.remove(i) : _selected.add(i);
      } else {
        _selected
          ..clear()
          ..add(i);
      }
    });
    widget.onChanged(Set<int>.from(_selected));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < widget.question.options.length; i++)
          Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            color: _selected.contains(i)
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
            child: ListTile(
              leading: Icon(widget.multi
                  ? (_selected.contains(i)
                      ? Icons.check_box
                      : Icons.check_box_outline_blank)
                  : (_selected.contains(i)
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked)),
              title: Text(widget.question.options[i].label.resolve(widget.lang)),
              onTap: () => _toggle(i),
            ),
          ),
      ],
    );
  }
}

class _TextView extends StatefulWidget {
  final String lang;
  final bool mono;
  final bool locked;
  final ValueChanged<Object?> onChanged;
  const _TextView(
      {super.key,
      required this.lang,
      required this.mono,
      required this.locked,
      required this.onChanged});

  @override
  State<_TextView> createState() => _TextViewState();
}

class _TextViewState extends State<_TextView> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings(widget.lang);
    return TextField(
      controller: _ctrl,
      enabled: !widget.locked,
      autocorrect: false,
      enableSuggestions: false,
      style: widget.mono
          ? const TextStyle(fontFamily: 'monospace', fontSize: 16)
          : null,
      decoration: InputDecoration(
        hintText: widget.mono ? s.typeCommandHint : s.fillHint,
        border: const OutlineInputBorder(),
        prefixText: widget.mono ? '\$ ' : null,
      ),
      onChanged: widget.onChanged,
    );
  }
}

class _MatchingView extends StatefulWidget {
  final Question question;
  final String lang;
  final bool locked;
  final ValueChanged<Object?> onChanged;
  const _MatchingView(
      {super.key,
      required this.question,
      required this.lang,
      required this.locked,
      required this.onChanged});

  @override
  State<_MatchingView> createState() => _MatchingViewState();
}

class _MatchingViewState extends State<_MatchingView> {
  final Map<int, int> _map = {}; // leftIndex -> original right pair index
  late List<int> _rightOrder; // shuffled display order of right options

  @override
  void initState() {
    super.initState();
    _rightOrder = List<int>.generate(widget.question.pairs.length, (i) => i)
      ..shuffle();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings(widget.lang);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.matchHint, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        for (var i = 0; i < widget.question.pairs.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                    flex: 4,
                    child: Text(widget.question.pairs[i].left.resolve(widget.lang),
                        style: const TextStyle(fontWeight: FontWeight.w600))),
                const Icon(Icons.arrow_forward, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  flex: 6,
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: _map[i],
                    hint: Text(s.matchHint),
                    items: [
                      for (final r in _rightOrder)
                        DropdownMenuItem(
                          value: r,
                          child: Text(
                              widget.question.pairs[r].right.resolve(widget.lang),
                              overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: widget.locked
                        ? null
                        : (v) {
                            setState(() => _map[i] = v!);
                            widget.onChanged(Map<int, int>.from(_map));
                          },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _OrderingView extends StatefulWidget {
  final Question question;
  final String lang;
  final bool locked;
  final ValueChanged<Object?> onChanged;
  const _OrderingView(
      {super.key,
      required this.question,
      required this.lang,
      required this.locked,
      required this.onChanged});

  @override
  State<_OrderingView> createState() => _OrderingViewState();
}

class _OrderingViewState extends State<_OrderingView> {
  late List<int> _order; // original indices in user's current order

  @override
  void initState() {
    super.initState();
    _order = List<int>.generate(widget.question.orderedItems.length, (i) => i);
    _order.shuffle();
    // Report initial order so Check is enabled.
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => widget.onChanged(List<int>.from(_order)));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings(widget.lang);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.tapToOrderHint, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: !widget.locked,
          onReorder: (oldI, newI) {
            if (widget.locked) return;
            setState(() {
              if (newI > oldI) newI -= 1;
              final item = _order.removeAt(oldI);
              _order.insert(newI, item);
            });
            widget.onChanged(List<int>.from(_order));
          },
          children: [
            for (var i = 0; i < _order.length; i++)
              Card(
                key: ValueKey('ord_${_order[i]}'),
                child: ListTile(
                  leading: CircleAvatar(child: Text('${i + 1}')),
                  title: Text(widget.question.orderedItems[_order[i]]
                      .resolve(widget.lang)),
                  trailing: const Icon(Icons.drag_handle),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
