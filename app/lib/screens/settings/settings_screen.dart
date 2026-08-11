import 'package:flutter/material.dart';
import 'package:review_calendar/features/account/presentation/account_ui_state.dart';
import 'package:review_calendar/features/account/presentation/account_view_model.dart';
import 'package:review_calendar/features/notification/domain/notification_device_registration.dart';
import 'package:review_calendar/ui/core/icons/rc_icons.dart';
import 'package:review_calendar/ui/core/theme/rc_layout.dart';
import 'package:review_calendar/ui/core/theme/rc_theme.dart';

/// 설정 — mirrors `screen-rest.jsx`'s `SettingsScreen`, extended with real
/// 알림/계정 rows in place of the design's "알림 · 계정 · 플랫폼 연동 등"
/// placeholder card (same card/row visual language as the rest of the
/// screen — no new design language introduced).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    required this.categories,
    required this.onCategoriesChanged,
    required this.accountViewModel,
    this.notificationRegistration,
    super.key,
  });

  final List<String> categories;
  final ValueChanged<List<String>> onCategoriesChanged;
  final AccountViewModel accountViewModel;
  final NotificationDeviceRegistrationController? notificationRegistration;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late List<String> _categories = List.of(widget.categories);
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.accountViewModel.addListener(_onAccountChanged);
  }

  @override
  void dispose() {
    widget.accountViewModel.removeListener(_onAccountChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onAccountChanged() {
    final state = widget.accountViewModel.state;
    if (state.message != null && !state.isBusy) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(state.message!)));
    }
    setState(() {});
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('회원 탈퇴'),
        content: const Text('탈퇴하면 등록한 일정과 기록이 모두 삭제되고 복구할 수 없어요. 정말 탈퇴하시겠어요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('탈퇴하기', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final success = await widget.accountViewModel.deleteAccount();
      // AuthGate swaps its child when the sign-out stream fires, but that
      // only changes what's *underneath* this screen's own pushed route —
      // without popping it explicitly, Settings stays on top, hiding the
      // login screen it just revealed.
      if (success && mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  Future<void> _handleSignOut() async {
    final success = await widget.accountViewModel.signOut();
    if (success && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _requestNotificationPermission() async {
    await widget.notificationRegistration?.requestAfterExplanation();
    if (mounted) setState(() {});
  }

  /// The OS is the source of truth for notification permission — an app
  /// can request it or point the user at Settings, but can't silently
  /// toggle it back off once granted, so this renders status + the one
  /// action that's actually available for each state instead of an
  /// on/off switch.
  Widget _buildNotificationRow(BuildContext context) {
    final status = widget.notificationRegistration?.status;
    final (statusLabel, action) = switch (status) {
      null => ('알림 기능을 사용할 수 없어요', null),
      NotificationPermissionStatus.authorized => ('알림이 켜져 있어요', null),
      NotificationPermissionStatus.notDetermined => (
        '아직 알림을 설정하지 않았어요',
        _requestNotificationPermission,
      ),
      NotificationPermissionStatus.denied ||
      NotificationPermissionStatus.permanentlyDenied => (
        '알림이 꺼져 있어요',
        _requestNotificationPermission,
      ),
    };
    return _SettingsRow(
      label: '푸시 알림',
      trailing: action == null ? null : '설정하기',
      subtitle: statusLabel,
      onTap: action,
    );
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
                      '알림',
                      style: Theme.of(
                        context,
                      ).textTheme.labelMedium?.copyWith(letterSpacing: 1),
                    ),
                  ),
                  _SettingsCard(children: [_buildNotificationRow(context)]),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
                    child: Text(
                      '계정',
                      style: Theme.of(
                        context,
                      ).textTheme.labelMedium?.copyWith(letterSpacing: 1),
                    ),
                  ),
                  _SettingsCard(
                    children: [
                      _SettingsRow(
                        label: '로그아웃',
                        busy:
                            widget.accountViewModel.state.status ==
                            AccountActionStatus.signingOut,
                        onTap: _handleSignOut,
                      ),
                      Divider(height: 1, color: colors.border),
                      _SettingsRow(
                        label: '회원 탈퇴',
                        labelColor: Colors.red,
                        busy:
                            widget.accountViewModel.state.status ==
                            AccountActionStatus.deleting,
                        onTap: _confirmDeleteAccount,
                      ),
                    ],
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

/// Same card chrome as the "카테고리 관리" card above — border/radius/color
/// only, so 알림/계정 read as part of the same screen rather than a
/// different design language.
class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.rcColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(RcRadius.large),
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.label,
    this.subtitle,
    this.trailing,
    this.labelColor,
    this.busy = false,
    this.onTap,
  });

  final String label;
  final String? subtitle;
  final String? trailing;
  final Color? labelColor;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.rcColors;
    return InkWell(
      onTap: busy ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: labelColor ?? colors.ink,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(fontSize: 12, color: colors.inkSubtle),
                    ),
                  ],
                ],
              ),
            ),
            if (busy)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.inkSubtle,
                ),
              )
            else if (trailing != null)
              Text(
                trailing!,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: colors.brandDeep,
                ),
              )
            else if (onTap != null)
              RcIcon(
                RcIconGlyph.chevronRight,
                size: 12,
                color: colors.inkMuted,
              ),
          ],
        ),
      ),
    );
  }
}
