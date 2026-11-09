import 'package:flutter/material.dart';

/// Layout breakpoints keep desktop comfortable and mobile compact.
class Breakpoints {
  static const double tablet = 700;
  static const double desktop = 1000;
}

bool isDesktop(BuildContext context) {
  return MediaQuery.sizeOf(context).width >= Breakpoints.desktop;
}

bool isTabletOrMore(BuildContext context) {
  return MediaQuery.sizeOf(context).width >= Breakpoints.tablet;
}

double contentMaxWidth(BuildContext context) {
  return isDesktop(context) ? 1100 : 700;
}

int searchColumns(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width >= Breakpoints.desktop) {
    return 3;
  }
  if (width >= Breakpoints.tablet) {
    return 2;
  }
  return 1;
}
