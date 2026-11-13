import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../auth/auth.dart';
import '../../controllers/global_search_controller.dart';
import '../../models/global_search_hit_model.dart';

class GlobalSearchBar extends ConsumerStatefulWidget {
  const GlobalSearchBar({required this.role, super.key});

  final UserRole role;

  @override
  ConsumerState<GlobalSearchBar> createState() => _GlobalSearchBarState();
}

class _GlobalSearchBarState extends ConsumerState<GlobalSearchBar> {
  final _queryController = TextEditingController();
  final _focusNode = FocusNode();
  final _overlayController = OverlayPortalController();
  final _anchorKey = GlobalKey();
  final _popupKey = GlobalKey();
  final _layerLink = LayerLink();
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _queryController.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) _open();
  }

  void _open() {
    if (_isOpen) return;
    setState(() => _isOpen = true);
    _overlayController.show();
  }

  void _close() {
    if (!_isOpen) return;
    _focusNode.unfocus();
    setState(() => _isOpen = false);
    _overlayController.hide();
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _overlayController,
      overlayChildBuilder: _overlay,
      child: CompositedTransformTarget(
        link: _layerLink,
        child: SizedBox(
          key: _anchorKey,
          height: 44,
          child: TextField(
            controller: _queryController,
            focusNode: _focusNode,
            textInputAction: TextInputAction.search,
            maxLength: 100,
            onTap: _open,
            onChanged: (value) {
              setState(() {});
              ref
                  .read(globalSearchControllerProvider(widget.role).notifier)
                  .search(value);
            },
            onSubmitted: _submit,
            decoration: InputDecoration(
              hintText: 'Buscar clientes, contratos o pagos…',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _queryController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpiar búsqueda',
                      onPressed: () {
                        _queryController.clear();
                        ref
                            .read(globalSearchControllerProvider(widget.role)
                                .notifier)
                            .search('');
                        setState(() {});
                        _focusNode.requestFocus();
                      },
                      icon: const Icon(Icons.close, size: 18),
                    ),
              counterText: '',
              filled: true,
              fillColor: AppTheme.surfaceSecondary,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppTheme.space3,
                vertical: AppTheme.space2,
              ),
              border: _searchBorder(),
              enabledBorder: _searchBorder(),
              focusedBorder: _searchBorder(),
            ),
          ),
        ),
      ),
    );
  }

  InputBorder _searchBorder() => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusField),
        borderSide: const BorderSide(color: AppTheme.lineStrong),
      );

  Widget _overlay(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context);
    final popupWidth = math.min(460.0, viewport.width - 24);
    final box = _anchorKey.currentContext?.findRenderObject();
    final anchorLeft =
        box is RenderBox ? box.localToGlobal(Offset.zero).dx : AppTheme.space3;
    final targetLeft = anchorLeft.clamp(
        12.0, math.max(12.0, viewport.width - popupWidth - 12));
    final horizontalOffset = (targetLeft - anchorLeft).toDouble();
    final maxHeight = math.min(440.0, viewport.height * .7);

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _maybeDismiss,
      child: Stack(
        children: [
          CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomLeft,
            followerAnchor: Alignment.topLeft,
            offset: Offset(horizontalOffset, AppTheme.space2),
            child: Material(
              key: _popupKey,
              color: AppTheme.surface,
              elevation: 12,
              shadowColor: AppTheme.primary.withValues(alpha: .16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radius),
                side: const BorderSide(color: AppTheme.line),
              ),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                width: popupWidth,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxHeight),
                  child: _popupContent(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _maybeDismiss(PointerDownEvent event) {
    if (_containsPoint(_anchorKey, event.position) ||
        _containsPoint(_popupKey, event.position)) {
      return;
    }
    _close();
  }

  bool _containsPoint(GlobalKey key, Offset point) {
    final renderObject = key.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return false;
    return renderObject.size.contains(renderObject.globalToLocal(point));
  }

  Widget _popupContent(BuildContext context) {
    final query = _queryController.text.trim();
    final searchState = ref.watch(globalSearchControllerProvider(widget.role));
    if (query.isEmpty) return _quickLinks(context);
    if (query.length < 2) {
      return const Padding(
        padding: EdgeInsets.all(AppTheme.space4),
        child: Text(
          'Escribe al menos 2 caracteres para buscar.',
          style: TextStyle(color: AppTheme.muted),
        ),
      );
    }
    return searchState.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppTheme.space6),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, color: AppTheme.muted),
              const SizedBox(height: AppTheme.space2),
              const Text('No se pudo completar la búsqueda.'),
              TextButton.icon(
                onPressed: () => ref
                    .read(globalSearchControllerProvider(widget.role).notifier)
                    .search(query),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
      data: (hits) => hits.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(AppTheme.space4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.search_off_outlined, color: AppTheme.muted),
                  const SizedBox(height: AppTheme.space2),
                  Text('No encontramos resultados para “$query”.'),
                ],
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: AppTheme.space2),
              itemCount: hits.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) =>
                  _resultTile(context, hits[index]),
            ),
    );
  }

  Widget _quickLinks(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.space4,
              AppTheme.space3,
              AppTheme.space4,
              AppTheme.space2,
            ),
            child: Text(
              'Accesos rápidos',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppTheme.muted,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          _quickLink(context, 'Clientes', Icons.people_outline, '/clientes'),
          _quickLink(
              context, 'Contratos', Icons.description_outlined, '/contratos'),
          _quickLink(context, 'Pagos', Icons.credit_card_outlined, '/pagos'),
        ],
      );

  Widget _quickLink(
    BuildContext context,
    String label,
    IconData icon,
    String route,
  ) =>
      ListTile(
        minTileHeight: 48,
        leading: Icon(icon, color: AppTheme.secondaryDark),
        title: Text(label),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 15),
        onTap: () => _openRoute(context, route),
      );

  Widget _resultTile(BuildContext context, GlobalSearchHitModel hit) =>
      ListTile(
        minVerticalPadding: AppTheme.space2,
        minTileHeight: 56,
        leading: CircleAvatar(
          backgroundColor: AppTheme.secondarySoft,
          foregroundColor: AppTheme.secondaryDark,
          child: Icon(_icon(hit.type), size: 20),
        ),
        title: Text(hit.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          hit.subtitle.isEmpty
              ? _typeLabel(hit.type)
              : '${_typeLabel(hit.type)} · ${hit.subtitle}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.muted),
        onTap: () => _openRoute(context, hit.route),
      );

  void _submit(String _) async {
    final hits = await ref
        .read(globalSearchControllerProvider(widget.role).notifier)
        .searchNow(_queryController.text);
    if (!mounted || hits.isEmpty) return;
    _openRoute(context, hits.first.route);
  }

  void _openRoute(BuildContext context, String route) {
    _close();
    context.go(route);
  }

  IconData _icon(GlobalSearchHitType type) => switch (type) {
        GlobalSearchHitType.cliente => Icons.person_outline,
        GlobalSearchHitType.contrato => Icons.description_outlined,
        GlobalSearchHitType.pago => Icons.receipt_long_outlined,
      };

  String _typeLabel(GlobalSearchHitType type) => switch (type) {
        GlobalSearchHitType.cliente => 'Cliente',
        GlobalSearchHitType.contrato => 'Contrato',
        GlobalSearchHitType.pago => 'Pago',
      };
}
