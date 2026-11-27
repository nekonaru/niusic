import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../ui/ni_tokens.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    required this.strings,
    required this.onDone,
    super.key,
  });

  final AppStrings strings;
  final VoidCallback onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < 2) {
      _controller.nextPage(duration: NiMotion.page, curve: NiMotion.emphasized);
    } else {
      widget.onDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    final theme = Theme.of(context);
    final pages = <(IconData, String, String)>[
      (Icons.library_music, strings.onboardingTitle1, strings.onboardingDesc1),
      (Icons.headphones, strings.onboardingTitle2, strings.onboardingDesc2),
      (
        Icons.notifications_none,
        strings.onboardingTitle3,
        strings.onboardingDesc3,
      ),
    ];
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: widget.onDone,
                child: Text(strings.skip),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (index) => setState(() => _page = index),
                itemCount: pages.length,
                itemBuilder: (context, index) {
                  final page = pages[index];
                  return Padding(
                    padding: const EdgeInsets.all(NiSpace.xxl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          page.$1,
                          size: 96,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: NiSpace.xxl),
                        Text(
                          page.$2,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: NiSpace.md),
                        Text(
                          page.$3,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < pages.length; i++)
                  AnimatedContainer(
                    duration: NiMotion.micro,
                    margin: const EdgeInsets.symmetric(horizontal: NiSpace.xs),
                    width: _page == i ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _page == i
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.3,
                            ),
                      borderRadius: BorderRadius.circular(NiRadius.sm),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(NiSpace.xxl),
              child: FilledButton(
                onPressed: _next,
                child: Text(
                  _page == 2 ? strings.getStarted : strings.onboardingNext,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
