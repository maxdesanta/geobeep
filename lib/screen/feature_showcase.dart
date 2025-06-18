import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

class FeatureShowcase extends StatefulWidget {
  final Widget child;

  const FeatureShowcase({super.key, required this.child});

  @override
  State<FeatureShowcase> createState() => _FeatureShowcaseState();
}

class _FeatureShowcaseState extends State<FeatureShowcase> {
  final GlobalKey _helpButtonKey = GlobalKey();
  final GlobalKey _stationCardKey = GlobalKey();
  final GlobalKey _alarmButtonKey = GlobalKey();
  final GlobalKey _mapButtonKey = GlobalKey();
  final GlobalKey _favoriteButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Start showcase after build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startShowcase();
      }
    });
  }

  void _startShowcase() {
    ShowCaseWidget.of(context).startShowCase([
      _helpButtonKey,
      _stationCardKey,
      _alarmButtonKey,
      _mapButtonKey,
      _favoriteButtonKey,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
      onStart: (index, key) {},
      onComplete: (index, key) {},
      blurValue: 1,
      builder: (context) => _wrapWithShowcase(widget.child),
    );
  }

  Widget _wrapWithShowcase(Widget child) {
    // This is a wrapper that will add showcase keys to specific widgets
    return child;
  }

  // Method to wrap specific widgets with showcase
  static Widget wrapHelpButton(Widget child, GlobalKey key) {
    return Showcase(
      key: key,
      title: 'Bantuan & Panduan',
      description:
          'Ketuk ikon ini kapan saja untuk melihat panduan penggunaan aplikasi',
      child: child,
    );
  }

  static Widget wrapStationCard(Widget child, GlobalKey key) {
    return Showcase(
      key: key,
      title: 'Kartu Stasiun Favorit',
      description:
          'Ini adalah stasiun favorit Anda. Badge kuning menunjukkan alarm sedang aktif',
      child: child,
    );
  }

  static Widget wrapAlarmButton(Widget child, GlobalKey key) {
    return Showcase(
      key: key,
      title: 'Tombol Alarm',
      description: 'Ketuk untuk mengatur alarm lokasi dengan radius tertentu',
      child: child,
    );
  }

  static Widget wrapMapButton(Widget child, GlobalKey key) {
    return Showcase(
      key: key,
      title: 'Lihat di Peta',
      description: 'Ketuk untuk melihat lokasi stasiun di peta',
      child: child,
    );
  }

  static Widget wrapFavoriteButton(Widget child, GlobalKey key) {
    return Showcase(
      key: key,
      title: 'Hapus Favorit',
      description: 'Ketuk untuk menghapus stasiun dari daftar favorit',
      child: child,
    );
  }
}

// Helper mixin for easy showcase integration
mixin ShowcaseMixin<T extends StatefulWidget> on State<T> {
  final Map<String, GlobalKey> showcaseKeys = {};

  GlobalKey getShowcaseKey(String keyName) {
    return showcaseKeys.putIfAbsent(keyName, () => GlobalKey());
  }

  void startShowcase(List<String> keyNames) {
    final keys = keyNames.map((name) => getShowcaseKey(name)).toList();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ShowCaseWidget.of(context).startShowCase(keys);
      }
    });
  }

  Widget buildShowcase({
    required String keyName,
    required String title,
    required String description,
    required Widget child,
    ShapeBorder? targetShapeBorder,
  }) {
    return Showcase(
      key: getShowcaseKey(keyName),
      title: title,
      description: description,
      targetShapeBorder: targetShapeBorder ?? const RoundedRectangleBorder(),
      // Only pass targetShapeBorder if it's not null
      child: child,
    );
  }
}
