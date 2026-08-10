import 'package:flutter/material.dart';
import 'package:review_calendar/ui/core/icons/rc_icons.dart';
import 'package:review_calendar/ui/core/theme/rc_layout.dart';
import 'package:review_calendar/ui/core/theme/rc_theme.dart';

/// 설정 — mirrors `screen-rest.jsx`'s `SettingsScreen`.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    required this.categories,
    required this.onCategoriesChanged,
    super.key,
  });

  final List<String> categories;
  final ValueChanged<List<String>> onCategoriesChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late List<String> _categories = List.of(widget.categories);
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addCategory() {
    final v = _controller.text.trim();
    if (v.isEmpty || _categories.contains(v)) return;
    setState(() {
      _categories = [..._categories.where((c) => c != '기타'), v, '기타'];
      _controller.clear();
    });
    widget.onCategoriesChanged(_categories);
  }

  void _removeCategory(String cat) {
    if (cat == '기타') return;
    setState(() => _categories = _categories.where((c) => c != cat).toList());
    widget.onCategoriesChanged(_categories);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.rcColors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  InkWell(
                    key: const ValueKey('settings:back'),
                    onTap: () => Navigator.of(context).maybePop(),
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: colors.card,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.border),
                      ),
                      child: Center(
                        child: RcIcon(
                          RcIconGlyph.chevronLeft,
                          size: 14,
                          color: colors.ink,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('설정', style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
                    child: Text(
                      '카테고리 관리',
                      style: Theme.of(
                        context,
                      ).textTheme.labelMedium?.copyWith(letterSpacing: 1),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(RcRadius.large),
                      border: Border.all(color: colors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _categories
                              .map(
                                (cat) => Container(
                                  padding: const EdgeInsets.fromLTRB(
                                    12,
                                    6,
                                    6,
                                    6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.backgroundAlternative,
                                    borderRadius: BorderRadius.circular(
                                      RcRadius.pill,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        cat,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: colors.ink,
                                        ),
                                      ),
                                      if (cat != '기타') ...[
                                        const SizedBox(width: 5),
                                        InkWell(
                                          onTap: () => _removeCategory(cat),
                                          customBorder: const CircleBorder(),
                                          child: Container(
                                            width: 18,
                                            height: 18,
                                            decoration: BoxDecoration(
                                              color: colors.border,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: RcIcon(
                                                RcIconGlyph.close,
                                                size: 9,
                                                color: colors.inkSubtle,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                onSubmitted: (_) => _addCategory(),
                                decoration: InputDecoration(
                                  hintText: '새 카테고리 추가',
                                  isDense: true,
                                  filled: true,
                                  fillColor: colors.background,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      RcRadius.small,
                                    ),
                                    borderSide: BorderSide(
                                      color: colors.border,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              key: const ValueKey('settings:add-category'),
                              onTap: _addCategory,
                              borderRadius: BorderRadius.circular(
                                RcRadius.small,
                              ),
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: colors.brand,
                                  borderRadius: BorderRadius.circular(
                                    RcRadius.small,
                                  ),
                                ),
                                child: const Center(
                                  child: RcIcon(
                                    RcIconGlyph.plus,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '"기타"는 기본으로 제공되며 삭제할 수 없어요',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
                    child: Text(
                      '기타',
                      style: Theme.of(
                        context,
                      ).textTheme.labelMedium?.copyWith(letterSpacing: 1),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(RcRadius.large),
                      border: Border.all(color: colors.border),
                    ),
                    child: Text(
                      '알림 · 계정 · 플랫폼 연동 등',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
