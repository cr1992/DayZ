// dart format width=80

/// GENERATED CODE - DO NOT MODIFY BY HAND
/// *****************************************************
///  FlutterGen
/// *****************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: deprecated_member_use,directives_ordering,implicit_dynamic_list_literal,unnecessary_import

import 'package:flutter/widgets.dart';

class $AssetsEditorGen {
  const $AssetsEditorGen();

  /// File path: assets/editor/demo_image.png
  AssetGenImage get demoImage =>
      const AssetGenImage('assets/editor/demo_image.png');

  /// List of all assets
  List<AssetGenImage> get values => [demoImage];
}

class $AssetsFontsGen {
  const $AssetsFontsGen();

  /// File path: assets/fonts/.gitkeep
  String get aGitkeep => 'assets/fonts/.gitkeep';

  /// File path: assets/fonts/HankenGrotesk-Bold.ttf
  String get hankenGroteskBold => 'assets/fonts/HankenGrotesk-Bold.ttf';

  /// File path: assets/fonts/HankenGrotesk-Medium.ttf
  String get hankenGroteskMedium => 'assets/fonts/HankenGrotesk-Medium.ttf';

  /// File path: assets/fonts/HankenGrotesk-Regular.ttf
  String get hankenGroteskRegular => 'assets/fonts/HankenGrotesk-Regular.ttf';

  /// File path: assets/fonts/HankenGrotesk-SemiBold.ttf
  String get hankenGroteskSemiBold => 'assets/fonts/HankenGrotesk-SemiBold.ttf';

  /// File path: assets/fonts/HankenGrotesk_OFL.txt
  String get hankenGroteskOFL => 'assets/fonts/HankenGrotesk_OFL.txt';

  /// File path: assets/fonts/Newsreader-Bold.ttf
  String get newsreaderBold => 'assets/fonts/Newsreader-Bold.ttf';

  /// File path: assets/fonts/Newsreader-Italic.ttf
  String get newsreaderItalic => 'assets/fonts/Newsreader-Italic.ttf';

  /// File path: assets/fonts/Newsreader-Medium.ttf
  String get newsreaderMedium => 'assets/fonts/Newsreader-Medium.ttf';

  /// File path: assets/fonts/Newsreader-MediumItalic.ttf
  String get newsreaderMediumItalic =>
      'assets/fonts/Newsreader-MediumItalic.ttf';

  /// File path: assets/fonts/Newsreader-Regular.ttf
  String get newsreaderRegular => 'assets/fonts/Newsreader-Regular.ttf';

  /// File path: assets/fonts/Newsreader-SemiBold.ttf
  String get newsreaderSemiBold => 'assets/fonts/Newsreader-SemiBold.ttf';

  /// File path: assets/fonts/Newsreader_OFL.txt
  String get newsreaderOFL => 'assets/fonts/Newsreader_OFL.txt';

  /// List of all assets
  List<String> get values => [
    aGitkeep,
    hankenGroteskBold,
    hankenGroteskMedium,
    hankenGroteskRegular,
    hankenGroteskSemiBold,
    hankenGroteskOFL,
    newsreaderBold,
    newsreaderItalic,
    newsreaderMedium,
    newsreaderMediumItalic,
    newsreaderRegular,
    newsreaderSemiBold,
    newsreaderOFL,
  ];
}

class $AssetsIconsGen {
  const $AssetsIconsGen();

  /// File path: assets/icons/.gitkeep
  String get aGitkeep => 'assets/icons/.gitkeep';

  /// List of all assets
  List<String> get values => [aGitkeep];
}

class $AssetsImagesGen {
  const $AssetsImagesGen();

  /// File path: assets/images/.gitkeep
  String get aGitkeep => 'assets/images/.gitkeep';

  /// List of all assets
  List<String> get values => [aGitkeep];
}

class Assets {
  const Assets._();

  static const $AssetsEditorGen editor = $AssetsEditorGen();
  static const $AssetsFontsGen fonts = $AssetsFontsGen();
  static const $AssetsIconsGen icons = $AssetsIconsGen();
  static const $AssetsImagesGen images = $AssetsImagesGen();
}

class AssetGenImage {
  const AssetGenImage(
    this._assetName, {
    this.size,
    this.flavors = const {},
    this.animation,
  });

  final String _assetName;

  final Size? size;
  final Set<String> flavors;
  final AssetGenImageAnimation? animation;

  Image image({
    Key? key,
    AssetBundle? bundle,
    ImageFrameBuilder? frameBuilder,
    ImageErrorWidgetBuilder? errorBuilder,
    String? semanticLabel,
    bool excludeFromSemantics = false,
    double? scale,
    double? width,
    double? height,
    Color? color,
    Animation<double>? opacity,
    BlendMode? colorBlendMode,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    Rect? centerSlice,
    bool matchTextDirection = false,
    bool gaplessPlayback = true,
    bool isAntiAlias = false,
    String? package,
    FilterQuality filterQuality = FilterQuality.medium,
    int? cacheWidth,
    int? cacheHeight,
  }) {
    return Image.asset(
      _assetName,
      key: key,
      bundle: bundle,
      frameBuilder: frameBuilder,
      errorBuilder: errorBuilder,
      semanticLabel: semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
      scale: scale,
      width: width,
      height: height,
      color: color,
      opacity: opacity,
      colorBlendMode: colorBlendMode,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      centerSlice: centerSlice,
      matchTextDirection: matchTextDirection,
      gaplessPlayback: gaplessPlayback,
      isAntiAlias: isAntiAlias,
      package: package,
      filterQuality: filterQuality,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );
  }

  ImageProvider provider({AssetBundle? bundle, String? package}) {
    return AssetImage(_assetName, bundle: bundle, package: package);
  }

  String get path => _assetName;

  String get keyName => _assetName;
}

class AssetGenImageAnimation {
  const AssetGenImageAnimation({
    required this.isAnimation,
    required this.duration,
    required this.frames,
  });

  final bool isAnimation;
  final Duration duration;
  final int frames;
}
