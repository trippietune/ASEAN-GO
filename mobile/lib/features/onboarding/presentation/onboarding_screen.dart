import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/organic_accent.dart';
import 'onboarding_controller.dart';

class _OnboardingPageData {
  const _OnboardingPageData({required this.icon, required this.titleBuilder, required this.bodyBuilder});

  final IconData icon;
  final String Function(AppLocalizations) titleBuilder;
  final String Function(AppLocalizations) bodyBuilder;
}

const _pages = [
  _OnboardingPageData(
    icon: Icons.map_outlined,
    titleBuilder: _onboardingTitle1,
    bodyBuilder: _onboardingBody1,
  ),
  _OnboardingPageData(
    icon: Icons.checklist_rtl,
    titleBuilder: _onboardingTitle2,
    bodyBuilder: _onboardingBody2,
  ),
  _OnboardingPageData(
    icon: Icons.shield_outlined,
    titleBuilder: _onboardingTitle3,
    bodyBuilder: _onboardingBody3,
  ),
];

// Small free functions (rather than inline closures above) just so the
// `_pages` list can stay a top-level const — AppLocalizations getters
// themselves aren't const-constructible.
String _onboardingTitle1(AppLocalizations l10n) => l10n.onboardingTitle1;
String _onboardingBody1(AppLocalizations l10n) => l10n.onboardingBody1;
String _onboardingTitle2(AppLocalizations l10n) => l10n.onboardingTitle2;
String _onboardingBody2(AppLocalizations l10n) => l10n.onboardingBody2;
String _onboardingTitle3(AppLocalizations l10n) => l10n.onboardingTitle3;
String _onboardingBody3(AppLocalizations l10n) => l10n.onboardingBody3;

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _isLastPage => _page == _pages.length - 1;

  void _finish() => ref.read(onboardingDismissedProvider.notifier).state = true;

  void _next() {
    if (_isLastPage) {
      _finish();
      return;
    }
    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.yellowPale, AppColors.white],
                stops: [0, 0.6],
              ),
            ),
          ),
          Positioned(
            top: -30,
            right: -30,
            child: OrganicAccent(color: AppColors.pinkLight.withValues(alpha: 0.35), size: 160),
          ),
          Positioned(
            bottom: -40,
            left: -40,
            child: OrganicAccent(color: AppColors.yellowSoft.withValues(alpha: 0.5), size: 180),
          ),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TextButton(
                      onPressed: _isLastPage ? null : _finish,
                      child: Text(
                        l10n.onboardingSkip,
                        style: TextStyle(
                          color: _isLastPage ? Colors.transparent : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (context, i) => _OnboardingPage(data: _pages[i], l10n: l10n),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _pages.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == _page ? 22 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _page ? AppColors.pinkDark : AppColors.pinkLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _next,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.pinkDark,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        _isLastPage ? l10n.onboardingGetStarted : l10n.onboardingNext,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
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

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data, required this.l10n});

  final _OnboardingPageData data;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: AppColors.pinkLight.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(data.icon, size: 72, color: AppColors.pinkDark),
          ),
          const SizedBox(height: 40),
          Text(
            data.titleBuilder(l10n),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.pinkDark,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            data.bodyBuilder(l10n),
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), height: 1.5),
          ),
        ],
      ),
    );
  }
}
