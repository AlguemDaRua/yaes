import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/tokens/dimensions.dart';
import 'empty_state.dart';
import 'skeleton.dart';

/// Renders loading, error, empty and data states for an [AsyncValue].
class AsyncView<T> extends StatelessWidget {
  const AsyncView({
    required this.value,
    required this.data,
    this.loading,
    this.onRetry,
    this.empty,
    this.isEmpty,
    this.emptyTitle,
    this.emptyDescription,
    this.errorTitle,
    this.errorDescription,
    super.key,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final Widget? loading;
  final VoidCallback? onRetry;
  final Widget? empty;
  final bool Function(T data)? isEmpty;
  final String? emptyTitle;
  final String? emptyDescription;
  final String? errorTitle;
  final String? errorDescription;

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);

    return value.when(
      loading: () => loading ?? const AsyncViewSkeleton(),
      error: (error, _) => EmptyState(
        icon: LucideIcons.triangleAlert,
        title: errorTitle ?? strings.commonError,
        description: errorDescription ?? error.toString(),
        ctaLabel: onRetry == null ? null : strings.commonRetry,
        onCta: onRetry,
      ),
      data: (value) {
        if (isEmpty != null && isEmpty!(value)) {
          return empty ??
              EmptyState(
                icon: LucideIcons.inbox,
                title: emptyTitle ?? strings.commonNoData,
                description: emptyDescription ?? strings.commonNoData,
              );
        }

        return data(value);
      },
    );
  }
}

/// Generic table/list placeholder used by [AsyncView] when no custom skeleton
/// is provided.
class AsyncViewSkeleton extends StatelessWidget {
  const AsyncViewSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 640.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Skeleton(width: width, height: 56),
            const SizedBox(height: YaSpacing.sm),
            Skeleton(width: width, height: 56),
            const SizedBox(height: YaSpacing.sm),
            Skeleton(width: width, height: 56),
          ],
        );
      },
    );
  }
}
