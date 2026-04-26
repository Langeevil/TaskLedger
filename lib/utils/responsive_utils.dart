import 'package:flutter/widgets.dart';

enum AppDeviceClass { mobile, tablet, desktop }

class AppResponsive {
  const AppResponsive._();

  static const double mobileMaxWidth = 600;
  static const double desktopMinWidth = 1024;

  static AppDeviceClass deviceForWidth(double width) {
    if (width < mobileMaxWidth) return AppDeviceClass.mobile;
    if (width <= desktopMinWidth) return AppDeviceClass.tablet;
    return AppDeviceClass.desktop;
  }

  static bool isMobile(double width) =>
      deviceForWidth(width) == AppDeviceClass.mobile;

  static bool isTablet(double width) =>
      deviceForWidth(width) == AppDeviceClass.tablet;

  static bool isDesktop(double width) =>
      deviceForWidth(width) == AppDeviceClass.desktop;

  static EdgeInsets pagePadding(double width) {
    return switch (deviceForWidth(width)) {
      AppDeviceClass.mobile => const EdgeInsets.all(12),
      AppDeviceClass.tablet => const EdgeInsets.all(20),
      AppDeviceClass.desktop => const EdgeInsets.all(32),
    };
  }

  static double maxContentWidth(double width) {
    return switch (deviceForWidth(width)) {
      AppDeviceClass.mobile => width,
      AppDeviceClass.tablet => 900,
      AppDeviceClass.desktop => 1120,
    };
  }

  static int gridColumns(
    double width, {
    int mobile = 1,
    int tablet = 3,
    int desktop = 4,
    bool landscape = false,
  }) {
    return switch (deviceForWidth(width)) {
      AppDeviceClass.mobile =>
        landscape ? (mobile + 1).clamp(1, desktop) : mobile,
      AppDeviceClass.tablet =>
        landscape ? (tablet + 1).clamp(1, desktop) : tablet,
      AppDeviceClass.desktop => desktop,
    };
  }

  static double headingSize(double width) {
    return switch (deviceForWidth(width)) {
      AppDeviceClass.mobile => 24,
      AppDeviceClass.tablet => 28,
      AppDeviceClass.desktop => 32,
    };
  }

  static double bodySize(double width) {
    return switch (deviceForWidth(width)) {
      AppDeviceClass.mobile => 14,
      AppDeviceClass.tablet => 16,
      AppDeviceClass.desktop => 18,
    };
  }

  static double itemWidth({
    required double availableWidth,
    required int columns,
    double spacing = 12,
  }) {
    final safeColumns = columns.clamp(1, 12);
    final totalSpacing = spacing * (safeColumns - 1);
    return (availableWidth - totalSpacing) / safeColumns;
  }

  static double modalMaxWidth(double width) {
    return switch (deviceForWidth(width)) {
      AppDeviceClass.mobile => width,
      AppDeviceClass.tablet => 640,
      AppDeviceClass.desktop => 720,
    };
  }

  static double modalMaxHeightFactor(double width) {
    return isMobile(width) ? 0.92 : 0.82;
  }
}

extension AppResponsiveContext on BuildContext {
  Size get screenSize => MediaQuery.of(this).size;
  AppDeviceClass get deviceClass =>
      AppResponsive.deviceForWidth(screenSize.width);
  bool get isMobile => AppResponsive.isMobile(screenSize.width);
  bool get isTablet => AppResponsive.isTablet(screenSize.width);
  bool get isDesktop => AppResponsive.isDesktop(screenSize.width);
  EdgeInsets get responsivePagePadding =>
      AppResponsive.pagePadding(screenSize.width);
}
