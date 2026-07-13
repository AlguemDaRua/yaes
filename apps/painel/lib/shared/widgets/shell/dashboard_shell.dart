// Tradução fiel de _design/showcases/dashboard-shell.jsx (composição completa).
// Spec: _design/components.md §1.

import 'package:flutter/material.dart';

import '../../../theme/tokens/colors.dart';
import '../../../theme/tokens/dimensions.dart';
import '../layout/responsive.dart';

/// Composição do shell: sidebar | (topbar / main scroll).
///
/// O `child` é o conteúdo da rota actual (já com page header dentro). O shell
/// trata apenas da estrutura. Toasts/dialogs são overlays separados.
class DashboardShell extends StatelessWidget {
  const DashboardShell({
    required this.sidebar,
    required this.topbar,
    required this.child,
    super.key,
  });

  final Widget sidebar;
  final Widget topbar;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);

    return Scaffold(
      backgroundColor: colors.bgBase,
      body: Row(
        children: [
          sidebar,
          Expanded(
            child: Column(
              children: [
                topbar,
                Expanded(
                  child: ColoredBox(
                    color: colors.bgBase,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          padding: YaResponsive.pagePaddingForWidth(
                            constraints.maxWidth,
                          ),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: YaDimensions.pageMaxWidth,
                              ),
                              child: child,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Loading state do shell (auth a verificar). JSX: wordmark grande +
/// barra de progresso animada 200x2 com "A verificar sessão...".
class DashboardShellLoading extends StatefulWidget {
  const DashboardShellLoading({super.key});

  @override
  State<DashboardShellLoading> createState() => _DashboardShellLoadingState();
}

class _DashboardShellLoadingState extends State<DashboardShellLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = YaColors.of(context);
    return ColoredBox(
      color: colors.bgBase,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'YA',
              style: TextStyle(color: colors.textPrimary).merge(
                _yaWordmarkStyle(),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'A VERIFICAR SESSÃO...',
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.54, // 0.14em * 11
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 200,
              height: 2,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9999),
                child: ColoredBox(
                  color: colors.bgSubtle,
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      // Barra desliza de left:-40% até left:100% (CSS keyframe).
                      const widthFraction = 0.4;
                      final t = _controller.value;
                      final leftFraction =
                          -widthFraction + t * (1 + widthFraction);
                      return LayoutBuilder(
                        builder: (_, constraints) {
                          return Stack(
                            children: [
                              Positioned(
                                left: leftFraction * constraints.maxWidth,
                                top: 0,
                                bottom: 0,
                                width: widthFraction * constraints.maxWidth,
                                child: ColoredBox(color: colors.brand),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _yaWordmarkStyle() {
    // Newsreader 36px, weight 500, letterSpacing -0.02em → -0.72.
    return const TextStyle(
      fontFamily: 'Newsreader',
      fontSize: 36,
      height: 1,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.72,
    );
  }
}
