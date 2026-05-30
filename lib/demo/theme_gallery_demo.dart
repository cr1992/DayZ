// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:dayz/ui/theme/dayz_colors.dart';
import 'package:dayz/ui/theme/dayz_fonts.dart';
import 'package:dayz/ui/theme/dayz_text_theme.dart';
import 'package:dayz/ui/theme/dayz_theme.dart';
import 'package:dayz/ui/theme/dayz_tokens.g.dart' hide DayzFonts;

/// Interactive gallery showcasing the 6 themes, typography, and box shadows.
///
/// Author: @Ray
class ThemeGalleryDemo extends StatefulWidget {
  const ThemeGalleryDemo({super.key});

  @override
  State<ThemeGalleryDemo> createState() => _ThemeGalleryDemoState();
}

class _ThemeGalleryDemoState extends State<ThemeGalleryDemo> {
  String _currentThemeKey = 'purpleLight';

  @override
  Widget build(BuildContext context) {
    final themeData = DayzThemes.all[_currentThemeKey]!;
    
    return Theme(
      data: themeData,
      child: Scaffold(
        body: AnimatedTheme(
          data: themeData,
          duration: DayzMotion.dur,
          curve: Curves.easeInOut,
          child: Builder(
            builder: (context) {
              final colors = context.dayz;
              final typography = context.dayzText;
              
              return CustomScrollView(
                slivers: [
                  // Beautiful Custom Header with dynamic background
                  SliverAppBar(
                    expandedHeight: 180.0,
                    floating: false,
                    pinned: true,
                    backgroundColor: colors.surface,
                    elevation: 0,
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text(
                        '主题画廊',
                        style: typography.h1.copyWith(
                          color: colors.ink,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              colors.accentSoft,
                              colors.bg,
                            ],
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: -20,
                              top: -20,
                              child: CircleAvatar(
                                radius: 80,
                                backgroundColor: colors.accentRing,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Theme Selection Segment
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(DayzSpacing.s4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('选择主题', style: typography.h3),
                          const SizedBox(height: DayzSpacing.s2),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: DayzThemes.all.keys.map((key) {
                                final isSelected = _currentThemeKey == key;
                                final itemTheme = DayzThemes.all[key]!;
                                final itemColors = itemTheme.extension<DayzColors>()!;
                                
                                return Padding(
                                  padding: const EdgeInsets.only(right: DayzSpacing.s2),
                                  child: ChoiceChip(
                                    label: Text(key),
                                    selected: isSelected,
                                    selectedColor: itemColors.accentSoft2,
                                    backgroundColor: colors.surface2,
                                    labelStyle: typography.caption.copyWith(
                                      color: isSelected ? itemColors.accentStrong : colors.ink2,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                    onSelected: (selected) {
                                      if (selected) {
                                        setState(() {
                                          _currentThemeKey = key;
                                        });
                                      }
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Accent Color System Grid
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(DayzSpacing.s4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('强调色家族', style: typography.h3),
                          const SizedBox(height: DayzSpacing.s3),
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            childAspectRatio: 2.2,
                            mainAxisSpacing: DayzSpacing.s3,
                            crossAxisSpacing: DayzSpacing.s3,
                            children: [
                              _buildColorCard('accent', colors.accent, colors.onAccent, typography),
                              _buildColorCard('accentStrong', colors.accentStrong, colors.onAccent, typography),
                              _buildColorCard('accentInk', colors.accentInk, colors.onAccent, typography),
                              _buildColorCard('onAccent', colors.onAccent, colors.ink, typography),
                              _buildColorCard('accentSoft', colors.accentSoft, colors.ink, typography),
                              _buildColorCard('accentSoft2', colors.accentSoft2, colors.ink, typography),
                              _buildColorCard('accentRing', colors.accentRing, colors.ink, typography),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Neutral Colors
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(DayzSpacing.s4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('中性色家族', style: typography.h3),
                          const SizedBox(height: DayzSpacing.s3),
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            childAspectRatio: 2.2,
                            mainAxisSpacing: DayzSpacing.s3,
                            crossAxisSpacing: DayzSpacing.s3,
                            children: [
                              _buildColorCard('bg', colors.bg, colors.ink, typography),
                              _buildColorCard('bg2', colors.bg2, colors.ink, typography),
                              _buildColorCard('surface', colors.surface, colors.ink, typography),
                              _buildColorCard('surface2', colors.surface2, colors.ink, typography),
                              _buildColorCard('ink', colors.ink, colors.surface, typography),
                              _buildColorCard('ink2', colors.ink2, colors.surface, typography),
                              _buildColorCard('ink3', colors.ink3, colors.surface, typography),
                              _buildColorCard('ink4', colors.ink4, colors.surface, typography),
                              _buildColorCard('hairline', colors.hairline, colors.ink, typography),
                              _buildColorCard('hairline2', colors.hairline2, colors.ink, typography),
                              _buildColorCard('overlay', colors.overlay, colors.onAccent, typography),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Semantic Helpers
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(DayzSpacing.s4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('语义组件 & 特效', style: typography.h3),
                          const SizedBox(height: DayzSpacing.s3),
                          // Glass surface simulation
                          Stack(
                            children: [
                              Container(
                                height: 120,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(DayzRadii.md),
                                  gradient: const LinearGradient(
                                    colors: [Colors.orange, Colors.pink, Colors.blue],
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '彩色背景图案',
                                    style: typography.h2.copyWith(color: Colors.white),
                                  ),
                                ),
                              ),
                              Positioned.fill(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(DayzRadii.md),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                                    child: Container(
                                      color: colors.glassSurface,
                                      alignment: Alignment.center,
                                      child: Text(
                                        '毛玻璃效果 (glassSurface 80% opacity)',
                                        style: typography.body.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: colors.ink,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: DayzSpacing.s4),
                          
                          // FAB with linear gradient and elevation shadows
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('立体受光 FAB 按钮', style: typography.body),
                                  Text('使用 fabGradient + shadowMd', style: typography.caption),
                                ],
                              ),
                              Container(
                                width: 58,
                                height: 58,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: colors.fabGradient,
                                  boxShadow: colors.shadowMd,
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: () {},
                                    child: Icon(
                                      Icons.add,
                                      color: colors.onAccent,
                                      size: 26,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Box Shadows Gallery
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(DayzSpacing.s4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('多层投影家族', style: typography.h3),
                          const SizedBox(height: DayzSpacing.s3),
                          _buildShadowCard('shadowSm (极窄贴纸)', colors.shadowSm, colors, typography),
                          const SizedBox(height: DayzSpacing.s3),
                          _buildShadowCard('shadowMd (标准漂浮)', colors.shadowMd, colors, typography),
                          const SizedBox(height: DayzSpacing.s3),
                          _buildShadowCard('shadowLg (全局大悬浮)', colors.shadowLg, colors, typography),
                        ],
                      ),
                    ),
                  ),

                  // Typography Gallery
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(DayzSpacing.s4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('排版规范 (.t-*)', style: typography.h3),
                          const SizedBox(height: DayzSpacing.s3),
                          _buildTextRow('display', 'Display', typography.display, colors),
                          _buildTextRow('h1', 'Heading 1', typography.h1, colors),
                          _buildTextRow('h2', 'Heading 2', typography.h2, colors),
                          _buildTextRow('h3', 'Heading 3', typography.h3, colors),
                          _buildTextRow('body', 'UI Body Text (CJK height: 1.7)\n跨平台、本地优先、注重隐私的日记 App。基于 Flutter/Dart 开发。', typography.body, colors),
                          _buildTextRow('diary', 'Diary Reading Mode (CJK height: 1.85)\n今天天气晴朗，微风。在写日记的时光里，时间仿佛慢了下来。我们记录生活，只为对抗遗忘。', typography.diary, colors),
                          _buildTextRow('caption', 'Caption / Meta Info text', typography.caption, colors),
                          _buildTextRow('overline', 'OVERLINE METRIC LABEL', typography.overline, colors),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildColorCard(String name, Color color, Color textColor, DayzTextTheme typography) {
    final hexString = '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
    return Container(
      padding: const EdgeInsets.all(DayzSpacing.s2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(DayzRadii.sm),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            name,
            style: typography.caption.copyWith(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            hexString,
            style: typography.overline.copyWith(
              color: textColor.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShadowCard(String name, List<BoxShadow> shadow, DayzColors colors, DayzTextTheme typography) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DayzSpacing.s4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(DayzRadii.md),
        boxShadow: shadow,
        border: Border.all(color: colors.hairline),
      ),
      child: Text(
        name,
        style: typography.body.copyWith(color: colors.ink),
      ),
    );
  }

  Widget _buildTextRow(String role, String sampleText, TextStyle style, DayzColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DayzSpacing.s2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '.t-$role',
            style: TextStyle(
              fontFamily: DayzFonts.sans,
              fontFamilyFallback: DayzFonts.sansFallback,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: colors.ink3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sampleText,
            style: style,
          ),
          const Divider(),
        ],
      ),
    );
  }
}
