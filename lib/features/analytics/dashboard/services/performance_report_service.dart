// ================================================================
// FILE: lib/features/personal/dashboard/services/performance_report_service.dart
//
// Generates a premium certificate-style multi-page PDF report
// from a UserDashboard instance, with AI-powered psychological
// mindset analysis using the app's existing UniversalAIService.
//
// PAGES:
//   Page 1 → Certificate Cover (gold seal, user name, tier, rank)
//   Page 2 → Performance Overview (summary metrics grid)
//   Page 3 → Task Analytics (daily + weekly + goals + bucket stats)
//   Page 4 → Streaks & Progress History (30-day chart)
//   Page 5 → Mood & Wellbeing (mood history chart + frequency)
//   Page 6 → Rewards Gallery (tier breakdown + top rewards)
//   Page 7 → Deep Psychological Mindset Analysis (AI-generated)
//
// USAGE:
//   final bytes = await PerformanceReportService.generate(
//     dashboard: userDashboard,
//     userName: 'Aryan Sharma',
//   );
//   await Printing.layoutPdf(onLayout: (_) => bytes);
//
// ADD TO pubspec.yaml:
//   pdf: ^3.10.8
//   printing: ^5.13.1
// ================================================================

import 'dart:typed_data';
import 'dart:math' as math;

import 'package:flutter/material.dart' show Color;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:the_time_chart/ai_services/constants/ai_constants.dart';
import 'package:the_time_chart/helpers/card_color_helper.dart';

import '../../../../ai_services/services/universal_ai_service.dart';
import '../../../../widgets/logger.dart';
import '../models/dashboard_model.dart';

// ──────────────────────────────────────────────────────────────────
// DESIGN TOKENS
// Dark navy + gold certificate aesthetic, LaTeX-inspired typography
// ──────────────────────────────────────────────────────────────────

class _C {
  // Backgrounds
  static const PdfColor navy = PdfColor.fromInt(0xFF0D1B2A);
  static const PdfColor navyLight = PdfColor.fromInt(0xFF1A2E45);
  static const PdfColor navyMid = PdfColor.fromInt(0xFF142338);
  static const PdfColor page = PdfColor.fromInt(0xFFF8F6F0); // warm ivory

  // Gold accent family
  static const PdfColor gold = PdfColor.fromInt(0xFFD4A843);
  static const PdfColor goldLight = PdfColor.fromInt(0xFFEDC967);
  static const PdfColor goldPale = PdfColor.fromInt(0xFFF7E8B8);

  // Text
  static const PdfColor textDark = PdfColor.fromInt(0xFF1C1C2E);
  static const PdfColor textMid = PdfColor.fromInt(0xFF4A4A6A);
  static const PdfColor textLight = PdfColor.fromInt(0xFF8A8AAA);
  static const PdfColor white = PdfColors.white;

  // Status colours
  static const PdfColor green = PdfColor.fromInt(0xFF10B981);
  static const PdfColor greenLight = PdfColor.fromInt(0xFFD1FAE5);
  static const PdfColor red = PdfColor.fromInt(0xFFEF4444);
  static const PdfColor redLight = PdfColor.fromInt(0xFFFEE2E2);
  static const PdfColor blue = PdfColor.fromInt(0xFF3B82F6);
  static const PdfColor blueLight = PdfColor.fromInt(0xFFDBEAFE);
  static const PdfColor purple = PdfColor.fromInt(0xFF8B5CF6);
  static const PdfColor purpleLight = PdfColor.fromInt(0xFFEDE9FE);
  static const PdfColor amber = PdfColor.fromInt(0xFFF59E0B);
  static const PdfColor amberLight = PdfColor.fromInt(0xFFFEF3C7);

  // Tier colours mapped from your CardColorHelper
  static PdfColor tier(String t) {
    switch (t.toLowerCase()) {
      case 'nova':
        return PdfColor.fromInt(0xFFFFD700);
      case 'radiant':
        return PdfColor.fromInt(0xFFFF6B35);
      case 'prism':
        return PdfColor.fromInt(0xFFAB47BC);
      case 'crystal':
        return PdfColor.fromInt(0xFF29B6F6);
      case 'blaze':
        return PdfColor.fromInt(0xFFFF7043);
      case 'ember':
        return PdfColor.fromInt(0xFF66BB6A);
      case 'flame':
        return PdfColor.fromInt(0xFFEF5350);
      case 'spark':
        return PdfColor.fromInt(0xFFFFCA28);
      default:
        return PdfColor.fromInt(0xFF90A4AE);
    }
  }
}

// ──────────────────────────────────────────────────────────────────
// MAIN SERVICE
// ──────────────────────────────────────────────────────────────────

class PerformanceReportService {
  PerformanceReportService._();

  // ── Public entry point ─────────────────────────────────────────

  /// Generates the full PDF report and returns the raw bytes.
  /// Pass [userName] from your auth user profile.
  /// Set [generateAiAnalysis] to false to skip the AI page
  /// (faster, no token cost).
  static Future<Uint8List> generate({
    required UserDashboard dashboard,
    required String userName,
    bool generateAiAnalysis = true,
    void Function(int step, int total, String message)? onProgress,
  }) async {
    logI('📄 [ReportService] starting PDF generation for $userName');
    onProgress?.call(1, 6, 'Initiating PDF Generation sequence...');

    // ── Step 1: generate AI analysis (async, before PDF build) ────
    String aiAnalysis = '';
    if (generateAiAnalysis) {
      onProgress?.call(2, 6, 'Analyzing productivity trends with AI...');
      try {
        aiAnalysis = await _generateMindsetAnalysis(dashboard, userName);
      } catch (e) {
        logE('AI Mindset Analysis generation failed: $e');
        aiAnalysis =
            'An error occurred while compiling AI Mindset Analysis. Your standard analytics metrics are fully compiled below.';
      }
    }

    // ── Step 2: load fonts ─────────────────────────────────────────
    onProgress?.call(3, 6, 'Loading high-definition typography and colors...');
    final fonts = await _loadFonts();

    // ── Step 3: build the PDF ──────────────────────────────────────
    final pdf = pw.Document(
      title: '$userName — Performance Report',
      author: 'Time Chart',
      creator: 'PerformanceReportService',
    );

    final now = DateTime.now();
    final generatedLabel =
        '${now.day.toString().padLeft(2, '0')} '
        '${_monthName(now.month)} ${now.year}';

    // Each page receives the same fonts/theme context
    final theme = pw.ThemeData.withFont(
      base: fonts['regular']!,
      bold: fonts['bold']!,
      italic: fonts['italic']!,
      boldItalic: fonts['boldItalic']!,
    );

    onProgress?.call(4, 6, 'Rendering premium report pages...');

    // Page 1 — Certificate Cover
    try {
      pdf.addPage(
        _buildCoverPage(
          theme: theme,
          fonts: fonts,
          dashboard: dashboard,
          userName: userName,
          generatedLabel: generatedLabel,
        ),
      );
    } catch (e, stack) {
      logE('Error rendering cover page: $e\n$stack');
      pdf.addPage(
        _buildErrorPage(
          theme: theme,
          fonts: fonts,
          pageTitle: 'Certificate Cover',
          error: e,
        ),
      );
    }

    // Page 2 — Performance Overview
    try {
      pdf.addPage(
        _buildOverviewPage(
          theme: theme,
          fonts: fonts,
          dashboard: dashboard,
          userName: userName,
        ),
      );
    } catch (e, stack) {
      logE('Error rendering overview page: $e\n$stack');
      pdf.addPage(
        _buildErrorPage(
          theme: theme,
          fonts: fonts,
          pageTitle: 'Performance Overview',
          error: e,
        ),
      );
    }

    // Page 3 — Task Analytics
    try {
      pdf.addPage(
        _buildTaskAnalyticsPage(
          theme: theme,
          fonts: fonts,
          dashboard: dashboard,
          userName: userName,
        ),
      );
    } catch (e, stack) {
      logE('Error rendering task analytics page: $e\n$stack');
      pdf.addPage(
        _buildErrorPage(
          theme: theme,
          fonts: fonts,
          pageTitle: 'Task Analytics',
          error: e,
        ),
      );
    }

    // Page 4 — Streaks & Progress
    try {
      pdf.addPage(
        _buildStreaksProgressPage(
          theme: theme,
          fonts: fonts,
          dashboard: dashboard,
          userName: userName,
        ),
      );
    } catch (e, stack) {
      logE('Error rendering streaks progress page: $e\n$stack');
      pdf.addPage(
        _buildErrorPage(
          theme: theme,
          fonts: fonts,
          pageTitle: 'Streaks & Habits',
          error: e,
        ),
      );
    }

    // Page 5 — Mood & Wellbeing
    try {
      pdf.addPage(
        _buildMoodPage(
          theme: theme,
          fonts: fonts,
          dashboard: dashboard,
          userName: userName,
        ),
      );
    } catch (e, stack) {
      logE('Error rendering mood page: $e\n$stack');
      pdf.addPage(
        _buildErrorPage(
          theme: theme,
          fonts: fonts,
          pageTitle: 'Mood & Wellbeing',
          error: e,
        ),
      );
    }

    // Page 6 — Rewards Gallery
    try {
      pdf.addPage(
        _buildRewardsPage(
          theme: theme,
          fonts: fonts,
          dashboard: dashboard,
          userName: userName,
        ),
      );
    } catch (e, stack) {
      logE('Error rendering rewards page: $e\n$stack');
      pdf.addPage(
        _buildErrorPage(
          theme: theme,
          fonts: fonts,
          pageTitle: 'Rewards Gallery',
          error: e,
        ),
      );
    }

    // Page 7 — AI Mindset Analysis
    if (generateAiAnalysis && aiAnalysis.isNotEmpty) {
      onProgress?.call(5, 6, 'Applying final psychological insights...');
      try {
        pdf.addPage(
          _buildMindsetPage(
            theme: theme,
            fonts: fonts,
            aiAnalysis: aiAnalysis,
            userName: userName,
            signupDate: dashboard.createdAt,
          ),
        );
      } catch (e, stack) {
        logE('Error rendering mindset page: $e\n$stack');
        pdf.addPage(
          _buildErrorPage(
            theme: theme,
            fonts: fonts,
            pageTitle: 'AI Mindset Analysis',
            error: e,
          ),
        );
      }
    }

    onProgress?.call(6, 6, 'Encoding and saving PDF package...');
    final bytes = await pdf.save();
    logI('✅ [ReportService] PDF generated — ${bytes.length} bytes');
    return bytes;
  }

  // ── Convenience: show share sheet directly ────────────────────

  static Future<void> share({
    required UserDashboard dashboard,
    required String userName,
  }) async {
    final bytes = await generate(dashboard: dashboard, userName: userName);
    await Printing.sharePdf(
      bytes: bytes,
      filename: '${userName.replaceAll(' ', '_')}_performance_report.pdf',
    );
  }

  // ── Convenience: open print/save dialog ───────────────────────

  static Future<void> printOrSave({
    required UserDashboard dashboard,
    required String userName,
  }) async {
    await Printing.layoutPdf(
      name: '$userName - Performance Report',
      onLayout: (_) => generate(dashboard: dashboard, userName: userName),
    );
  }

  // ================================================================
  // PAGE 1 — CERTIFICATE COVER
  // ================================================================

  static pw.Page _buildCoverPage({
    required pw.ThemeData theme,
    required Map<String, pw.Font> fonts,
    required UserDashboard dashboard,
    required String userName,
    required String generatedLabel,
  }) {
    final summary = dashboard.overview.summary;
    final tier = summary.bestTierAchieved;

    return pw.Page(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        margin: pw.EdgeInsets.zero,
        buildBackground: (context) => pw.Container(color: _C.navy),
      ),
      build: (ctx) => pw.SizedBox(
        width: 595.27,
        height: 841.89,
        child: pw.Stack(
          children: [
            // ── Radial Concentric Watermark Background ───────────────
            pw.Positioned.fill(
              child: pw.CustomPaint(
                painter: _RadialWatermarkPainter(
                  color: _C.gold.shade(0.04),
                ).call,
              ),
            ),

            // ── Decorative corner ornaments ──────────────────────────
            pw.Positioned(
              top: 24,
              left: 24,
              child: _cornerOrnament(topLeft: true),
            ),
            pw.Positioned(
              top: 24,
              right: 24,
              child: _cornerOrnament(topLeft: false),
            ),
            pw.Positioned(
              bottom: 24,
              left: 24,
              child: _cornerOrnament(topLeft: false, flip: true),
            ),
            pw.Positioned(
              bottom: 24,
              right: 24,
              child: _cornerOrnament(topLeft: true, flip: true),
            ),

            // ── Gold border frames with explicit sizes ────────────────
            pw.Positioned(
              top: 24,
              left: 24,
              child: pw.SizedBox(
                width: 595.27 - 48,
                height: 841.89 - 48,
                child: pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: _C.gold, width: 1.5),
                  ),
                ),
              ),
            ),
            pw.Positioned(
              top: 30,
              left: 30,
              child: pw.SizedBox(
                width: 595.27 - 60,
                height: 841.89 - 60,
                child: pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(
                      color: _C.goldLight.shade(0.5),
                      width: 0.5,
                    ),
                  ),
                ),
              ),
            ),

            // ── Main content centred ─────────────────────────────────
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 60),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.SizedBox(height: 50),

                  // App name
                  pw.Text(
                    'TIME CHART',
                    style: pw.TextStyle(
                      font: fonts['bold'],
                      fontSize: 12,
                      letterSpacing: 6,
                      color: _C.gold,
                    ),
                  ),

                  pw.SizedBox(height: 12),
                  _decorativeDots(fonts),
                  pw.SizedBox(height: 16),

                  // "Certificate of Performance"
                  pw.Text(
                    'Certificate of',
                    style: pw.TextStyle(
                      font: fonts['italic'],
                      fontSize: 18,
                      color: _C.goldPale,
                    ),
                  ),
                  pw.Text(
                    'Performance',
                    style: pw.TextStyle(
                      font: fonts['bold'],
                      fontSize: 38,
                      color: _C.white,
                      letterSpacing: 1,
                    ),
                  ),

                  pw.SizedBox(height: 20),
                  _decorativeDots(fonts),
                  pw.SizedBox(height: 20),

                  // "This certifies that"
                  pw.Text(
                    'This certifies that',
                    style: pw.TextStyle(
                      font: fonts['regular'],
                      fontSize: 13,
                      color: _C.textLight.shade(0.8),
                    ),
                  ),
                  pw.SizedBox(height: 8),

                  // User name with centered gold underline
                  pw.Column(
                    children: [
                      pw.Text(
                        userName,
                        style: pw.TextStyle(
                          font: fonts['bold'],
                          fontSize: 40,
                          color: _C.goldLight,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 6),
                      pw.Container(width: 60, height: 2, color: _C.gold),
                      pw.SizedBox(height: 4),
                      if (dashboard.createdAt != null)
                        pw.Text(
                          'Est. ${_monthName(dashboard.createdAt!.month)} ${dashboard.createdAt!.year}',
                          style: pw.TextStyle(
                            font: fonts['italic'],
                            fontSize: 9,
                            color: _C.goldPale,
                          ),
                        ),
                    ],
                  ),

                  pw.SizedBox(height: 16),
                  pw.Text(
                    'has demonstrated outstanding commitment to\npersonal growth and productivity',
                    style: pw.TextStyle(
                      font: fonts['italic'],
                      fontSize: 12,
                      color: _C.goldPale,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),

                  pw.SizedBox(height: 24),

                  // ── Key metrics row ────────────────────────────────
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                    children: [
                      _certMetric(
                        fonts: fonts,
                        label: 'TOTAL POINTS',
                        value: _fmt(summary.totalPoints),
                      ),
                      _certDot(),
                      _certMetric(
                        fonts: fonts,
                        label: 'CURRENT STREAK',
                        value: '${summary.currentStreak}d',
                      ),
                      _certDot(),
                      _certMetric(
                        fonts: fonts,
                        label: 'BEST TIER',
                        value: tier == 'none' ? 'STARTER' : tier.toUpperCase(),
                      ),
                      _certDot(),
                      _certMetric(
                        fonts: fonts,
                        label: 'REWARDS',
                        value: '${summary.totalRewards}',
                      ),
                    ],
                  ),

                  // Core Metrics Subtitle Row
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Overall Completion Rate: ${summary.completionRateAll.toStringAsFixed(1)}%     •     Total Active Days: ${dashboard.streaks.stats.totalActiveDaysAllTime}',
                    style: pw.TextStyle(
                      font: fonts['regular'],
                      fontSize: 8.5,
                      color: _C.goldPale,
                      letterSpacing: 0.5,
                    ),
                  ),

                  pw.SizedBox(height: 24),
                  _decorativeDots(fonts),
                  pw.SizedBox(height: 16),

                  // ── Gold seal circle ───────────────────────────────
                  _goldSeal(fonts: fonts, tier: tier),

                  pw.SizedBox(height: 20),
                  _decorativeDots(fonts),
                  pw.SizedBox(height: 16),

                  // Footer
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'GENERATED ON',
                            style: pw.TextStyle(
                              font: fonts['regular'],
                              fontSize: 7,
                              letterSpacing: 2,
                              color: _C.textLight,
                            ),
                          ),
                          pw.Text(
                            generatedLabel,
                            style: pw.TextStyle(
                              font: fonts['bold'],
                              fontSize: 10,
                              color: _C.goldLight,
                            ),
                          ),
                        ],
                      ),
                      // Rank tier highlight
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text(
                            'CURRENT STATUS',
                            style: pw.TextStyle(
                              font: fonts['regular'],
                              fontSize: 7,
                              letterSpacing: 2,
                              color: _C.textLight,
                            ),
                          ),
                          pw.Text(
                            '${CardColorHelper.getTierEmoji(tier)} ${tier == "none" ? "STARTER" : tier.toUpperCase()}',
                            style: pw.TextStyle(
                              font: fonts['bold'],
                              fontSize: 10,
                              color: _C.tier(tier),
                            ),
                          ),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'GLOBAL RANK',
                            style: pw.TextStyle(
                              font: fonts['regular'],
                              fontSize: 7,
                              letterSpacing: 2,
                              color: _C.textLight,
                            ),
                          ),
                          pw.Text(
                            summary.globalRank > 0
                                ? '#${summary.globalRank}'
                                : 'Unranked',
                            style: pw.TextStyle(
                              font: fonts['bold'],
                              fontSize: 10,
                              color: _C.goldLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Page _buildOverviewPage({
    required pw.ThemeData theme,
    required Map<String, pw.Font> fonts,
    required UserDashboard dashboard,
    required String userName,
  }) {
    final s = dashboard.overview.summary;

    // Detect exceptional achievements
    String? achievementTitle;
    String? achievementDesc;
    if (s.completionRateAll >= 80.0) {
      achievementTitle = 'All-Time Consistency Leader';
      achievementDesc =
          'You have maintained an outstanding completion rate of ${s.completionRateAll.toStringAsFixed(1)}% across all-time schedules! Your dedication is elite.';
    } else if (s.longestStreak >= 7) {
      achievementTitle = 'Elite Habit Champion';
      achievementDesc =
          'You achieved a continuous streak of ${s.longestStreak} days! This demonstrates incredibly high resilience and focus.';
    } else if (s.averageRating >= 4.0) {
      achievementTitle = 'Excellent Quality of Execution';
      achievementDesc =
          'Your tasks are completed with a beautiful average rating of ${s.averageRating.toStringAsFixed(1)}/5, proving you prioritize quality and deep work.';
    }

    return pw.Page(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 46),
        buildBackground: (ctx) => pw.Stack(
          children: [
            pw.Container(color: _C.page),
            _pageWatermark(fonts),
            pw.Positioned(top: 0, left: 0, right: 0, child: _topBand()),
            pw.Positioned(bottom: 0, left: 0, right: 0, child: _bottomBand()),
          ],
        ),
      ),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _pageHeader(
            fonts: fonts,
            title: 'Performance Overview',
            page: 2,
            signupDate: dashboard.createdAt,
          ),
          pw.SizedBox(height: 16),

          // ── Top metrics 2×4 grid ──────────────────────────────────
          pw.Row(
            children: [
              pw.Expanded(
                child: _metricCard(
                  fonts: fonts,
                  label: 'Total Points',
                  value: _fmt(s.totalPoints),
                  color: _C.navy,
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _metricCard(
                  fonts: fonts,
                  label: 'Points Today',
                  value: _fmt(s.pointsToday),
                  color: _C.green,
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _metricCard(
                  fonts: fonts,
                  label: 'This Week',
                  value: _fmt(s.pointsThisWeek),
                  color: _C.blue,
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _metricCard(
                  fonts: fonts,
                  label: 'Total Rewards',
                  value: '${s.totalRewards}',
                  color: _C.amber,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              pw.Expanded(
                child: _metricCard(
                  fonts: fonts,
                  label: 'Current Streak',
                  value: '${s.currentStreak} days',
                  color: _C.purple,
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _metricCard(
                  fonts: fonts,
                  label: 'Longest Streak',
                  value: '${s.longestStreak} days',
                  color: _C.navyLight,
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _metricCard(
                  fonts: fonts,
                  label: 'Avg Rating',
                  value: s.averageRating.toStringAsFixed(1),
                  color: _C.green,
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _metricCard(
                  fonts: fonts,
                  label: 'Best Tier',
                  value: s.bestTierAchieved == 'none'
                      ? 'STARTER'
                      : s.bestTierAchieved.toUpperCase(),
                  color: _C.tier(s.bestTierAchieved),
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 16),
          _sectionTitle(fonts: fonts, title: 'Completion Rates'),
          pw.SizedBox(height: 10),

          // ── Completion rate bars ──────────────────────────────────
          _progressRow(
            fonts: fonts,
            label: 'All Time',
            value: s.completionRateAll,
            color: _C.navy,
            signupDate: dashboard.createdAt,
          ),
          pw.SizedBox(height: 8),
          _progressRow(
            fonts: fonts,
            label: 'This Week',
            value: s.completionRateWeek,
            color: _C.blue,
          ),
          pw.SizedBox(height: 8),
          _progressRow(
            fonts: fonts,
            label: 'Today',
            value: s.completionRateToday,
            color: _C.green,
          ),

          // Conditional achievement highlight box
          if (achievementTitle != null) ...[
            pw.SizedBox(height: 16),
            _statHighlightBox(
              fonts: fonts,
              title: achievementTitle,
              description: achievementDesc!,
            ),
          ],

          pw.SizedBox(height: 16),
          _sectionTitle(fonts: fonts, title: 'Points Breakdown by Source'),
          pw.SizedBox(height: 10),

          // ── Horizontal bar chart for points by source ─────────────
          _horizontalBarChart(
            fonts: fonts,
            items: [
              _BarItem('Daily Tasks', s.dailyTasksPoints, _C.blue),
              _BarItem('Weekly Tasks', s.weeklyTasksPoints, _C.purple),
              _BarItem('Long Goals', s.longGoalsPoints, _C.green),
              _BarItem('Bucket List', s.bucketListPoints, _C.amber),
            ],
          ),

          pw.SizedBox(height: 16),
          _sectionTitle(fonts: fonts, title: "Recent Activity Log"),
          pw.SizedBox(height: 10),

          _recentActivityTable(fonts: fonts, items: dashboard.recentActivity),

          pw.SizedBox(height: 12),
          _pageFooter(fonts: fonts, userName: userName, page: 2),
        ],
      ),
    );
  }

  // ================================================================
  // PAGE 3 — TASK ANALYTICS
  // ================================================================

  static pw.Page _buildTaskAnalyticsPage({
    required pw.ThemeData theme,
    required Map<String, pw.Font> fonts,
    required UserDashboard dashboard,
    required String userName,
  }) {
    final ov = dashboard.overview;

    return pw.Page(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 46),
        buildBackground: (ctx) => pw.Stack(
          children: [
            pw.Container(color: _C.page),
            _pageWatermark(fonts),
            pw.Positioned(top: 0, left: 0, right: 0, child: _topBand()),
            pw.Positioned(bottom: 0, left: 0, right: 0, child: _bottomBand()),
          ],
        ),
      ),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _pageHeader(
            fonts: fonts,
            title: 'Task Analytics',
            page: 3,
            signupDate: dashboard.createdAt,
          ),
          pw.SizedBox(height: 16),

          // ── Combined LaTeX Metric Table ───────────────────────────
          _combinedStatsTable(fonts: fonts, ov: ov),

          pw.SizedBox(height: 16),
          _sectionTitle(fonts: fonts, title: 'Category Performance'),
          pw.SizedBox(height: 10),

          _categoryBreakdown(fonts: fonts, stats: dashboard.categoryStats),

          pw.SizedBox(height: 16),
          _sectionTitle(
            fonts: fonts,
            title: 'Weekly Performance (Last 12 Weeks)',
          ),
          pw.SizedBox(height: 10),

          _weeklyBarChart(
            fonts: fonts,
            history: dashboard.weeklyHistory,
            signupDate: dashboard.createdAt,
          ),

          pw.SizedBox(height: 12),

          // ── Weekly history summary row ────────────────────────────
          pw.Row(
            children: [
              pw.Expanded(
                child: _infoChip(
                  fonts: fonts,
                  label: 'Current Week',
                  value: _fmt(dashboard.weeklyHistory.currentWeekPoints),
                  color: _C.blue,
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _infoChip(
                  fonts: fonts,
                  label: 'Last Week',
                  value: _fmt(dashboard.weeklyHistory.lastWeekPoints),
                  color: _C.navyLight,
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _infoChip(
                  fonts: fonts,
                  label: 'Weekly Avg',
                  value: _fmt(
                    dashboard.weeklyHistory.averageWeeklyPoints.round(),
                  ),
                  color: _C.purple,
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _infoChip(
                  fonts: fonts,
                  label: 'WoW Change',
                  value:
                      '${dashboard.weeklyHistory.weekOverWeekChange > 0 ? '+' : ''}${dashboard.weeklyHistory.weekOverWeekChange.toStringAsFixed(1)}%',
                  color: dashboard.weeklyHistory.weekOverWeekChange >= 0
                      ? _C.green
                      : _C.red,
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 12),
          _pageFooter(fonts: fonts, userName: userName, page: 3),
        ],
      ),
    );
  }

  // ================================================================
  // PAGE 4 — STREAKS & PROGRESS HISTORY
  // ================================================================

  static pw.Page _buildStreaksProgressPage({
    required pw.ThemeData theme,
    required Map<String, pw.Font> fonts,
    required UserDashboard dashboard,
    required String userName,
  }) {
    final streaks = dashboard.streaks;
    final progress = dashboard.progressHistory;

    return pw.Page(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 46),
        buildBackground: (ctx) => pw.Stack(
          children: [
            pw.Container(color: _C.page),
            _pageWatermark(fonts),
            pw.Positioned(top: 0, left: 0, right: 0, child: _topBand()),
            pw.Positioned(bottom: 0, left: 0, right: 0, child: _bottomBand()),
          ],
        ),
      ),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _pageHeader(
            fonts: fonts,
            title: 'Streaks & Progress History',
            page: 4,
            signupDate: dashboard.createdAt,
          ),
          pw.SizedBox(height: 16),

          // ── Streak hero cards ─────────────────────────────────────
          pw.Row(
            children: [
              pw.Expanded(
                child: _streakHeroCard(
                  fonts: fonts,
                  label: 'CURRENT STREAK',
                  value: '${streaks.current.days}',
                  unit: 'days',
                  color: streaks.isAtRisk ? _C.red : _C.green,
                  subLabel: streaks.isAtRisk ? 'AT RISK TODAY' : 'ACTIVE',
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: _streakHeroCard(
                  fonts: fonts,
                  label: 'LONGEST STREAK',
                  value: '${streaks.longest.days}',
                  unit: 'days',
                  color: _C.gold,
                  subLabel: 'PERSONAL BEST',
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: _streakHeroCard(
                  fonts: fonts,
                  label: 'TOTAL ACTIVE DAYS',
                  value: '${streaks.stats.totalActiveDaysAllTime}',
                  unit: 'days',
                  color: _C.navy,
                  subLabel: 'ALL TIME',
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: _streakHeroCard(
                  fonts: fonts,
                  label: 'NEXT MILESTONE',
                  value: '${streaks.nextMilestone.target}',
                  unit: 'days',
                  color: _C.purple,
                  subLabel: '${streaks.nextMilestone.daysRemaining} TO GO',
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 16),

          // ── Milestone progress bar ────────────────────────────────
          _milestoneProgressBar(fonts: fonts, streaks: streaks),

          pw.SizedBox(height: 16),
          _sectionTitle(fonts: fonts, title: '30-Day Activity Calendar'),
          pw.SizedBox(height: 10),

          _streakCalendar(
            fonts: fonts,
            history: streaks.history,
            signupDate: dashboard.createdAt,
          ),

          pw.SizedBox(height: 16),
          _sectionTitle(fonts: fonts, title: 'Daily Points (Last 30 Days)'),
          pw.SizedBox(height: 10),

          _dailyPointsChart(
            fonts: fonts,
            stats: progress.dailyStats,
            signupDate: dashboard.createdAt,
          ),

          pw.SizedBox(height: 12),

          // ── Best / worst day row ──────────────────────────────────
          pw.Row(
            children: [
              pw.Expanded(
                child: _infoChip(
                  fonts: fonts,
                  label: 'Best Day',
                  value: progress.bestDay != null
                      ? '${_fmt(progress.bestDay!.value)} pts · ${progress.bestDay!.formattedDate}'
                      : '—',
                  color: _C.green,
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: _infoChip(
                  fonts: fonts,
                  label: 'Worst Day',
                  value: progress.worstDay != null
                      ? '${_fmt(progress.worstDay!.value)} pts · ${progress.worstDay!.formattedDate}'
                      : '—',
                  color: _C.red,
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: _infoChip(
                  fonts: fonts,
                  label: 'Trend',
                  value: progress.trend.toUpperCase(),
                  color: progress.trend == 'improving'
                      ? _C.green
                      : progress.trend == 'declining'
                      ? _C.red
                      : _C.textMid,
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 16),
          _sectionTitle(fonts: fonts, title: 'Streak Breaks (Last 90 Days)'),
          pw.SizedBox(height: 10),

          // ── Streak Breaks Table ──────────────────────────────────
          _streakBreakTable(
            fonts: fonts,
            breaks: streaks.history.breaksInLast90Days,
          ),

          pw.SizedBox(height: 12),
          _pageFooter(fonts: fonts, userName: userName, page: 4),
        ],
      ),
    );
  }

  // ================================================================
  // PAGE 5 — MOOD & WELLBEING
  // ================================================================

  static pw.Page _buildMoodPage({
    required pw.ThemeData theme,
    required Map<String, pw.Font> fonts,
    required UserDashboard dashboard,
    required String userName,
  }) {
    final mood = dashboard.mood;

    return pw.Page(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 46),
        buildBackground: (ctx) => pw.Stack(
          children: [
            pw.Container(color: _C.page),
            _pageWatermark(fonts),
            pw.Positioned(top: 0, left: 0, right: 0, child: _topBand()),
            pw.Positioned(bottom: 0, left: 0, right: 0, child: _bottomBand()),
          ],
        ),
      ),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _pageHeader(
            fonts: fonts,
            title: 'Mood & Wellbeing',
            page: 5,
            signupDate: dashboard.createdAt,
          ),
          pw.SizedBox(height: 16),

          // ── Mood summary cards ────────────────────────────────────
          pw.Row(
            children: [
              pw.Expanded(
                child: _metricCard(
                  fonts: fonts,
                  label: '7-Day Avg',
                  value: mood.averageMoodLast7Days.toStringAsFixed(1),
                  color: _moodColor(mood.averageMoodLast7Days),
                  icon: '♡',
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _metricCard(
                  fonts: fonts,
                  label: '30-Day Avg',
                  value: mood.averageMoodLast30Days.toStringAsFixed(1),
                  color: _moodColor(mood.averageMoodLast30Days),
                  icon: '♡',
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _metricCard(
                  fonts: fonts,
                  label: 'Most Common',
                  value: mood.mostCommonMood.isEmpty
                      ? '—'
                      : mood.mostCommonMood,
                  color: _C.purple,
                  icon: '◉',
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _metricCard(
                  fonts: fonts,
                  label: 'Trend',
                  value: mood.trend.toUpperCase(),
                  color: mood.trend == 'improving'
                      ? _C.green
                      : mood.trend == 'declining'
                      ? _C.red
                      : _C.navy,
                  icon: '↗',
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 20),
          _sectionTitle(fonts: fonts, title: 'Mood History (Last 30 Days)'),
          pw.SizedBox(height: 10),

          _moodLineChart(
            fonts: fonts,
            history: mood.moodHistory,
            signupDate: dashboard.createdAt,
          ),

          pw.SizedBox(height: 20),
          _sectionTitle(fonts: fonts, title: 'Mood Frequency Distribution'),
          pw.SizedBox(height: 10),

          _moodFrequencyBars(fonts: fonts, frequency: mood.moodFrequency),

          pw.SizedBox(height: 20),

          // ── Mood scale reference ──────────────────────────────────
          _sectionTitle(fonts: fonts, title: 'Mood Scale Reference (1–10)'),
          pw.SizedBox(height: 8),
          _moodScaleReference(fonts: fonts),

          pw.SizedBox(height: 20),
          _sectionTitle(fonts: fonts, title: 'Current Mood Reflection'),
          pw.SizedBox(height: 8),
          _todayMoodCard(fonts: fonts, today: mood.todayMood),

          pw.SizedBox(height: 12),
          _pageFooter(fonts: fonts, userName: userName, page: 5),
        ],
      ),
    );
  }

  // ================================================================
  // PAGE 6 — REWARDS GALLERY
  // ================================================================

  static pw.Page _buildRewardsPage({
    required pw.ThemeData theme,
    required Map<String, pw.Font> fonts,
    required UserDashboard dashboard,
    required String userName,
  }) {
    final rewards = dashboard.rewards;

    return pw.Page(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 46),
        buildBackground: (ctx) => pw.Stack(
          children: [
            pw.Container(color: _C.page),
            _pageWatermark(fonts),
            pw.Positioned(top: 0, left: 0, right: 0, child: _topBand()),
            pw.Positioned(bottom: 0, left: 0, right: 0, child: _bottomBand()),
          ],
        ),
      ),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _pageHeader(
            fonts: fonts,
            title: 'Rewards Gallery',
            page: 6,
            signupDate: dashboard.createdAt,
          ),
          pw.SizedBox(height: 16),

          // ── Summary header ────────────────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: _C.navy,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
              children: [
                _certMetric(
                  fonts: fonts,
                  label: 'TOTAL EARNED',
                  value: '${rewards.summary.totalRewardsEarned}',
                  light: true,
                ),
                _certDot(light: false),
                _certMetric(
                  fonts: fonts,
                  label: 'BEST TIER',
                  value: rewards.summary.bestTierAchieved.toUpperCase(),
                  light: true,
                ),
                _certDot(light: false),
                _certMetric(
                  fonts: fonts,
                  label: 'REWARD POINTS',
                  value: _fmt(rewards.summary.allRewardsPoints),
                  light: true,
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),
          _sectionTitle(fonts: fonts, title: 'Tier Breakdown (All Time)'),
          pw.SizedBox(height: 10),

          _tierBreakdown(fonts: fonts, rewards: rewards),

          pw.SizedBox(height: 20),
          _sectionTitle(fonts: fonts, title: 'Recently Earned Rewards'),
          pw.SizedBox(height: 10),

          _recentRewardsList(fonts: fonts, rewards: rewards.recentRewards),

          pw.SizedBox(height: 12),
          _pageFooter(fonts: fonts, userName: userName, page: 6),
        ],
      ),
    );
  }

  // ================================================================
  // PAGE 7 — AI MINDSET ANALYSIS
  // ================================================================

  static pw.Page _buildMindsetPage({
    required pw.ThemeData theme,
    required Map<String, pw.Font> fonts,
    required String aiAnalysis,
    required String userName,
    DateTime? signupDate,
  }) {
    // Parse sections from AI response (separated by ##)
    final sections = _parseMindsetSections(aiAnalysis);

    return pw.Page(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 46),
        buildBackground: (ctx) => pw.Stack(
          children: [
            pw.Container(color: _C.page),
            _pageWatermark(fonts),
            pw.Positioned(top: 0, left: 0, right: 0, child: _topBand()),
            pw.Positioned(bottom: 0, left: 0, right: 0, child: _bottomBand()),
          ],
        ),
      ),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _pageHeader(
            fonts: fonts,
            title: 'Deep Psychological Analysis',
            page: 7,
            signupDate: signupDate,
          ),

          pw.SizedBox(height: 4),
          pw.Text(
            'AI-powered mindset analysis based on your performance patterns',
            style: pw.TextStyle(
              font: fonts['italic'],
              fontSize: 10,
              color: _C.textLight,
            ),
          ),
          pw.SizedBox(height: 14),

          // ── Intro box ─────────────────────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: _C.navyLight,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 3,
                  height: 30,
                  color: _C.gold,
                  margin: const pw.EdgeInsets.only(right: 10),
                ),
                pw.Expanded(
                  child: pw.Text(
                    'This analysis synthesises your productivity metrics, '
                    'mood patterns, streak data, and reward history to provide '
                    'a personalised psychological portrait of your journey.',
                    style: pw.TextStyle(
                      font: fonts['italic'],
                      fontSize: 10,
                      color: _C.goldPale,
                    ),
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 16),

          // ── Render each AI section ────────────────────────────────
          ...sections.map(
            (section) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (section.title.isNotEmpty) ...[
                  pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 6),
                    child: pw.Row(
                      children: [
                        pw.Container(
                          width: 4,
                          height: 14,
                          color: _C.gold,
                          margin: const pw.EdgeInsets.only(right: 8),
                        ),
                        pw.Text(
                          section.title.toUpperCase(),
                          style: pw.TextStyle(
                            font: fonts['bold'],
                            fontSize: 10,
                            letterSpacing: 1.5,
                            color: _C.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                pw.Text(
                  section.body,
                  style: pw.TextStyle(
                    font: fonts['regular'],
                    fontSize: 10,
                    lineSpacing: 4,
                    color: _C.textMid,
                  ),
                ),
                pw.SizedBox(height: 14),
              ],
            ),
          ),

          pw.SizedBox(height: 12),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: _C.goldPale,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Text(
              'This analysis is generated by AI and is intended for reflection and personal growth. '
              'It is not a clinical assessment.',
              style: pw.TextStyle(
                font: fonts['italic'],
                fontSize: 8,
                color: _C.textMid,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.SizedBox(height: 12),
          _pageFooter(fonts: fonts, userName: userName, page: 7),
        ],
      ),
    );
  }

  // ================================================================
  // AI MINDSET ANALYSIS GENERATOR
  // Calls your existing UniversalAIService using AIProvider.claude
  // for deep reasoning quality, with a rich data-driven prompt.
  // ================================================================

  static Future<String> _generateMindsetAnalysis(
    UserDashboard dashboard,
    String userName,
  ) async {
    logI('🤖 [ReportService] generating AI mindset analysis...');

    final s = dashboard.overview.summary;
    final mood = dashboard.mood;
    final streaks = dashboard.streaks;
    final progress = dashboard.progressHistory;
    final rewards = dashboard.rewards;
    final ov = dashboard.overview;

    final prompt =
        '''
You are an expert performance psychologist and life coach. Analyse the following real user performance data and provide a DEEP psychological mindset analysis for $userName.

=== PERFORMANCE DATA ===
Total Points: ${s.totalPoints}
Points Today: ${s.pointsToday}
Points This Week: ${s.pointsThisWeek}
Global Rank: ${s.globalRank > 0 ? '#${s.globalRank}' : 'Unranked'}
Average Rating: ${s.averageRating.toStringAsFixed(1)}/5
Best Tier Achieved: ${s.bestTierAchieved}

=== COMPLETION RATES ===
All Time: ${s.completionRateAll.toStringAsFixed(1)}%
This Week: ${s.completionRateWeek.toStringAsFixed(1)}%
Today: ${s.completionRateToday.toStringAsFixed(1)}%

=== TASK PERFORMANCE ===
Daily Tasks: ${ov.dailyTasksStats.dayTasksCompleted}/${ov.dailyTasksStats.totalDayTasks} completed (${ov.dailyTasksStats.dayTasksCompletionRate.toStringAsFixed(1)}%)
Weekly Tasks: ${ov.weeklyTasksStats.weekTasksCompleted}/${ov.weeklyTasksStats.totalWeekTasks} completed
Long Goals: ${ov.longGoalsStats.longGoalsCompleted} completed, ${ov.longGoalsStats.longGoalsActive} active
Bucket List: ${ov.bucketListStats.bucketItemsCompleted}/${ov.bucketListStats.totalBucketItems} completed

=== STREAKS ===
Current Streak: ${streaks.current.days} days (${streaks.isActive ? 'ACTIVE' : 'BROKEN'})
Longest Streak: ${streaks.longest.days} days
Total Active Days: ${streaks.stats.totalActiveDaysAllTime}
Average Streak: ${streaks.stats.averageStreak.toStringAsFixed(1)} days
Most Common Break Day: ${streaks.stats.mostCommonBreakDay.isEmpty ? 'N/A' : streaks.stats.mostCommonBreakDay}
Streak At Risk: ${streaks.isAtRisk}

=== MOOD DATA (1-10 scale) ===
7-Day Average Mood: ${mood.averageMoodLast7Days.toStringAsFixed(1)}/10
30-Day Average Mood: ${mood.averageMoodLast30Days.toStringAsFixed(1)}/10
Mood Trend: ${mood.trend}
Most Common Mood: ${mood.mostCommonMood.isEmpty ? 'Not tracked' : mood.mostCommonMood}
Today's Mood: ${mood.todayMood?.label ?? 'Not logged'}

=== PROGRESS TREND ===
30-Day Trend: ${progress.trend}
Average Daily Progress: ${progress.averageProgress.toStringAsFixed(1)}%
Best Day: ${progress.bestDay != null ? '${_fmt(progress.bestDay!.value)} pts on ${progress.bestDay!.formattedDate}' : 'N/A'}

=== REWARDS ===
Total Rewards: ${rewards.summary.totalRewardsEarned}
Best Tier: ${rewards.summary.bestTierAchieved}
Nova: ${rewards.novaCount}, Radiant: ${rewards.radiantCount}, Crystal: ${rewards.crystalCount}
Blaze: ${rewards.blazeCount}, Ember: ${rewards.emberCount}, Spark: ${rewards.sparkCount}

=== INSTRUCTIONS ===
Write a deep, personalised psychological analysis structured with these EXACT sections:
## Productivity Archetype
(2-3 sentences: classify their productivity style based on task patterns, e.g. "Deadline Sprinter", "Steady Builder", "Goal Chaser")

## Motivational Engine
(2-3 sentences: what drives them based on their reward history, completion patterns, and task types)

## Emotional Intelligence Patterns
(2-3 sentences: interpret their mood data in context of their productivity — correlations, self-awareness level)

## Consistency Architecture
(2-3 sentences: deep analysis of their streak behaviour, break patterns, and habit formation stage)

## Cognitive Load & Capacity
(2-3 sentences: are they overloaded, underutilised, or in flow state based on completion rates and progress)

## Growth Trajectory
(2-3 sentences: where they are headed based on all data combined — honest and forward-looking)

## Power Recommendations
(3 bullet points, each starting with "→": specific, data-driven recommendations they can act on immediately)

Write in a warm, professional, insightful tone. Be specific — reference actual numbers. Avoid generic advice. Be psychologically informed.
''';

    try {
      final response = await UniversalAIService().generateResponse(
        prompt: prompt,
        systemPrompt:
            'You are an expert performance psychologist. Write insightful, '
            'data-driven psychological analysis. Be specific and reference the '
            'actual numbers provided. Structure your response with ## section headers.',
        preferredProvider: AIProvider.claude, // deepest reasoning
        maxTokens: 1500,
        temperature: 0.6,
        contextType: 'analysis',
        aiUsageSource: 'performance_report',
        useCache: false,
      );

      if (response.isSuccess && response.response.isNotEmpty) {
        logI('✅ [ReportService] AI analysis generated');
        return response.response;
      } else {
        logW('⚠️ [ReportService] AI response empty, using fallback');
        return _fallbackAnalysis(userName, dashboard);
      }
    } catch (e) {
      logE('❌ [ReportService] AI analysis failed: $e');
      return _fallbackAnalysis(userName, dashboard);
    }
  }

  // ── Static fallback if AI is unavailable ──────────────────────
  static String _fallbackAnalysis(String userName, UserDashboard d) {
    final s = d.overview.summary;
    final rate = s.completionRateAll;
    final streak = s.currentStreak;

    return '''## Performance Summary
$userName has accumulated ${_fmt(s.totalPoints)} total points with a ${rate.toStringAsFixed(1)}% all-time completion rate, demonstrating a ${rate >= 70
        ? 'strong'
        : rate >= 40
        ? 'developing'
        : 'emerging'} commitment to personal productivity.

## Streak Behaviour
With a current streak of $streak days and a personal best of ${s.longestStreak} days, ${userName.split(' ').first} shows ${streak >= 7
        ? 'excellent'
        : streak >= 3
        ? 'good'
        : 'early-stage'} consistency in daily habit formation.

## Recommendations
→ Focus on maintaining your ${streak}-day streak by scheduling a non-negotiable 15-minute daily task.
→ Aim to push your completion rate above ${(rate + 10).clamp(0, 100).toStringAsFixed(0)}% this week by reviewing pending tasks each morning.
→ Track your mood daily in the diary to build clearer correlations between emotional state and productivity output.''';
  }

  // ================================================================
  // COMPONENT BUILDERS
  // ================================================================

  // ── Page header with navy banner ──────────────────────────────

  static pw.Widget _pageHeader({
    required Map<String, pw.Font> fonts,
    required String title,
    required int page,
    DateTime? signupDate,
  }) {
    final runningSections = {
      2: 'PERFORMANCE OVERVIEW',
      3: 'TASK ANALYTICS',
      4: 'STREAKS & HABITS',
      5: 'MOOD & WELLBEING',
      6: 'REWARDS GALLERY',
      7: 'AI MINDSET ANALYSIS',
    };
    final sectionName = runningSections[page] ?? 'PERFORMANCE REPORT';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Text(
                        'TIME CHART',
                        style: pw.TextStyle(
                          font: fonts['regular'],
                          fontSize: 7,
                          letterSpacing: 3,
                          color: _C.textLight,
                        ),
                      ),
                      if (signupDate != null) ...[
                        pw.SizedBox(width: 8),
                        pw.Text(
                          '•   Member since ${_monthName(signupDate.month)} ${signupDate.year}',
                          style: pw.TextStyle(
                            font: fonts['italic'],
                            fontSize: 7,
                            color: _C.textLight,
                          ),
                        ),
                      ],
                    ],
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    title,
                    style: pw.TextStyle(
                      font: fonts['bold'],
                      fontSize: 20,
                      color: _C.navy,
                    ),
                  ),
                ],
              ),
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  sectionName,
                  style: pw.TextStyle(
                    font: fonts['bold'],
                    fontSize: 7.5,
                    letterSpacing: 1.5,
                    color: _C.gold,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Page $page of 7',
                  style: pw.TextStyle(
                    font: fonts['regular'],
                    fontSize: 7,
                    color: _C.textLight,
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Divider(
          height: 1,
          thickness: 0.5,
          color: PdfColor.fromInt(0xFFE2E8F0),
        ),
      ],
    );
  }

  // ── Thin gold divider ─────────────────────────────────────────

  static pw.Widget _goldDivider({bool short = false}) => pw.Container(
    width: short ? 80.0 : double.infinity,
    height: 1.5,
    color: _C.gold,
    margin: const pw.EdgeInsets.symmetric(vertical: 4),
  );

  // ── Certificate metric (used on dark backgrounds) ─────────────

  static pw.Widget _certMetric({
    required Map<String, pw.Font> fonts,
    required String label,
    required String value,
    bool light = false,
  }) => pw.Column(
    children: [
      pw.Text(
        value,
        style: pw.TextStyle(
          font: fonts['bold'],
          fontSize: 18,
          color: light ? _C.goldLight : _C.white,
        ),
      ),
      pw.Text(
        label,
        style: pw.TextStyle(
          font: fonts['regular'],
          fontSize: 7,
          letterSpacing: 1.5,
          color: light ? _C.goldPale : _C.textLight,
        ),
      ),
    ],
  );

  static pw.Widget _certDot({bool light = true}) => pw.Container(
    width: 4,
    height: 4,
    decoration: pw.BoxDecoration(
      color: light ? _C.gold : _C.navyLight,
      shape: pw.BoxShape.circle,
    ),
  );

  // ── Gold seal SVG-like circle ──────────────────────────────────

  static pw.Widget _goldSeal({
    required Map<String, pw.Font> fonts,
    required String tier,
  }) {
    final emoji = CardColorHelper.getTierEmoji(tier);
    return pw.Container(
      width: 120,
      height: 120,
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(
        shape: pw.BoxShape.circle,
        border: pw.Border.all(color: _C.gold, width: 0.5),
      ),
      child: pw.Container(
        width: 110,
        height: 110,
        decoration: pw.BoxDecoration(
          shape: pw.BoxShape.circle,
          border: pw.Border.all(color: _C.gold, width: 3),
          color: _C.navyLight,
        ),
        child: pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                'VERIFIED',
                style: pw.TextStyle(
                  font: fonts['bold'],
                  fontSize: 7,
                  letterSpacing: 2,
                  color: _C.gold,
                ),
              ),
              pw.Text(
                tier == 'none' ? 'S' : tier[0].toUpperCase(),
                style: pw.TextStyle(
                  font: fonts['bold'],
                  fontSize: 32,
                  color: _C.tier(tier),
                ),
              ),
              pw.Text(
                tier == 'none' ? 'STARTER' : tier.toUpperCase(),
                style: pw.TextStyle(
                  font: fonts['regular'],
                  fontSize: 7,
                  letterSpacing: 1,
                  color: _C.goldPale,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                emoji,
                style: pw.TextStyle(font: fonts['bold'], fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Corner ornament (decorative L-shape) ──────────────────────

  static pw.Widget _cornerOrnament({bool topLeft = true, bool flip = false}) {
    final isTop = !flip;
    final isLeft = topLeft != flip; // XOR logic for mirroring
    return pw.SizedBox(
      width: 80,
      height: 80,
      child: pw.Stack(
        children: [
          // Outer horizontal arm
          pw.Positioned(
            top: isTop ? 0 : null,
            bottom: isTop ? null : 0,
            left: isLeft ? 0 : null,
            right: isLeft ? null : 0,
            child: pw.Container(width: 80, height: 2, color: _C.gold),
          ),
          // Outer vertical arm
          pw.Positioned(
            top: isTop ? 0 : null,
            bottom: isTop ? null : 0,
            left: isLeft ? 0 : null,
            right: isLeft ? null : 0,
            child: pw.Container(width: 2, height: 80, color: _C.gold),
          ),
          // Inner horizontal arm (offset 6)
          pw.Positioned(
            top: isTop ? 6 : null,
            bottom: isTop ? null : 6,
            left: isLeft ? 6 : null,
            right: isLeft ? null : 6,
            child: pw.Container(width: 74, height: 0.5, color: _C.gold),
          ),
          // Inner vertical arm (offset 6)
          pw.Positioned(
            top: isTop ? 6 : null,
            bottom: isTop ? null : 6,
            left: isLeft ? 6 : null,
            right: isLeft ? null : 6,
            child: pw.Container(width: 0.5, height: 74, color: _C.gold),
          ),
        ],
      ),
    );
  }

  // ── Metric card (white with coloured header) ──────────────────

  static pw.Widget _metricCard({
    required Map<String, pw.Font> fonts,
    required String label,
    required String value,
    required PdfColor color,
    String icon = '',
  }) => pw.Container(
    decoration: pw.BoxDecoration(
      color: _C.white,
      borderRadius: pw.BorderRadius.circular(6),
      boxShadow: [
        pw.BoxShadow(
          color: PdfColor.fromInt(0x11000000),
          blurRadius: 4,
          offset: const PdfPoint(0, 2),
        ),
      ],
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: pw.BoxDecoration(
            color: color,
            borderRadius: const pw.BorderRadius.only(
              topLeft: pw.Radius.circular(6),
              topRight: pw.Radius.circular(6),
            ),
          ),
          child: pw.Text(
            label,
            style: pw.TextStyle(
              font: fonts['bold'],
              fontSize: 7,
              color: _C.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            value,
            style: pw.TextStyle(
              font: fonts['bold'],
              fontSize: 16,
              color: _C.textDark,
            ),
          ),
        ),
      ],
    ),
  );

  // ── Progress row with label + bar ────────────────────────────

  static pw.Widget _progressRow({
    required Map<String, pw.Font> fonts,
    required String label,
    required double value,
    required PdfColor color,
    DateTime? signupDate,
  }) {
    final pct = value.clamp(0.0, 100.0);
    PdfColor barColor = color;
    if (pct >= 80.0) {
      barColor = _C.green;
    } else if (pct >= 50.0) {
      barColor = _C.blue;
    } else {
      barColor = _C.red;
    }

    String subLabel = '';
    if (label == 'All Time' && signupDate != null) {
      subLabel = '\n(since ${_monthName(signupDate.month)} ${signupDate.year})';
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.SizedBox(
            width: 85,
            child: pw.Text(
              '$label$subLabel',
              style: pw.TextStyle(
                font: fonts['regular'],
                fontSize: 9,
                color: _C.textMid,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.LayoutBuilder(
              builder: (ctx, constraints) {
                final double fullW = constraints?.maxWidth ?? 200.0;
                final double barW = (pct / 100.0) * fullW;
                final double targetPos = 0.80 * fullW;

                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Stack(
                      children: [
                        pw.Container(width: fullW, height: 8),
                        pw.Positioned(
                          left: (targetPos - 15).clamp(0.0, fullW),
                          child: pw.Text(
                            'Target: 80%',
                            style: pw.TextStyle(font: fonts['bold'], fontSize: 6, color: _C.navy),
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 2),
                    pw.Stack(
                      alignment: pw.Alignment.centerLeft,
                      children: [
                        pw.Container(
                          height: 14,
                          width: fullW,
                          decoration: pw.BoxDecoration(
                            color: _C.page,
                            border: pw.Border.all(color: _C.textLight.shade(0.3)),
                            borderRadius: pw.BorderRadius.circular(7),
                          ),
                        ),
                        pw.Container(
                          height: 14,
                          width: barW,
                          decoration: pw.BoxDecoration(
                            color: barColor,
                            borderRadius: pw.BorderRadius.circular(7),
                          ),
                        ),
                        pw.Positioned(
                          left: targetPos,
                          top: 0,
                          bottom: 0,
                          child: pw.Container(width: 1.5, color: _C.navy),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          pw.SizedBox(width: 8),
          pw.SizedBox(
            width: 32,
            child: pw.Text(
              '${pct.toStringAsFixed(1)}%',
              style: pw.TextStyle(
                font: fonts['bold'],
                fontSize: 9,
                color: _C.textDark,
              ),
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  // ── Horizontal bar chart ──────────────────────────────────────

  static pw.Widget _horizontalBarChart({
    required Map<String, pw.Font> fonts,
    required List<_BarItem> items,
  }) {
    final maxVal = items.fold<double>(
      1,
      (m, i) => math.max(m, i.value.toDouble()),
    );
    return pw.Column(
      children: items.map((item) {
        final frac = maxVal > 0 ? item.value / maxVal : 0.0;
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Row(
            children: [
              pw.SizedBox(
                width: 90,
                child: pw.Text(
                  item.label,
                  style: pw.TextStyle(
                    font: fonts['regular'],
                    fontSize: 9,
                    color: _C.textMid,
                  ),
                ),
              ),
              pw.Expanded(
                child: pw.Container(
                  height: 14,
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFFF1F5F9),
                    borderRadius: pw.BorderRadius.circular(3),
                  ),
                  child: pw.Stack(
                    children: [
                      pw.Positioned(
                        top: 0,
                        bottom: 0,
                        left: 0,
                        child: pw.SizedBox(
                          width: frac.clamp(0.02, 1.0) * 200,
                          child: pw.Container(
                            decoration: pw.BoxDecoration(
                              color: item.color,
                              borderRadius: pw.BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                _fmt(item.value),
                style: pw.TextStyle(
                  font: fonts['bold'],
                  fontSize: 9,
                  color: _C.textDark,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Today snapshot block ──────────────────────────────────────

  static pw.Widget _todaySnapshot({
    required Map<String, pw.Font> fonts,
    required TodaySummary today,
  }) {
    final m = today.summary;
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _C.navyLight,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _todayStat(
            fonts: fonts,
            label: 'Scheduled',
            value: '${m.totalScheduledTask}',
            color: _C.white,
          ),
          _todayStat(
            fonts: fonts,
            label: 'Completed',
            value: '${m.completed}',
            color: _C.green,
          ),
          _todayStat(
            fonts: fonts,
            label: 'In Progress',
            value: '${m.inProgress}',
            color: _C.amber,
          ),
          _todayStat(
            fonts: fonts,
            label: 'Pending',
            value: '${m.notCompleted}',
            color: _C.red,
          ),
          _todayStat(
            fonts: fonts,
            label: 'Pts Earned',
            value: _fmt(m.pointsEarned),
            color: _C.gold,
          ),
          _todayStat(
            fonts: fonts,
            label: 'Day Rating',
            value: '${m.dayRating.toStringAsFixed(1)}/5',
            color: _C.goldLight,
          ),
          _todayStat(
            fonts: fonts,
            label: 'Diary',
            value: today.diaryEntry.hasEntry ? 'Written' : 'Pending',
            color: today.diaryEntry.hasEntry ? _C.green : _C.textLight,
          ),
        ],
      ),
    );
  }

  static pw.Widget _todayStat({
    required Map<String, pw.Font> fonts,
    required String label,
    required String value,
    required PdfColor color,
  }) => pw.Column(
    children: [
      pw.Text(
        value,
        style: pw.TextStyle(font: fonts['bold'], fontSize: 14, color: color),
      ),
      pw.Text(
        label,
        style: pw.TextStyle(
          font: fonts['regular'],
          fontSize: 7,
          color: _C.textLight,
        ),
      ),
    ],
  );

  // ── Stat block (column card) ──────────────────────────────────

  static pw.Widget _statBlock({
    required Map<String, pw.Font> fonts,
    required String title,
    required PdfColor color,
    required List<_StatRow> rows,
  }) => pw.Container(
    decoration: pw.BoxDecoration(
      color: _C.white,
      borderRadius: pw.BorderRadius.circular(6),
      boxShadow: [
        pw.BoxShadow(
          color: PdfColor.fromInt(0x08000000),
          blurRadius: 4,
          offset: const PdfPoint(0, 1),
        ),
      ],
    ),
    child: pw.ClipRRect(
      horizontalRadius: 6,
      verticalRadius: 6,
      child: pw.Column(
        children: [
          pw.Container(height: 3, color: color, width: double.infinity),
          pw.Padding(
            padding: const pw.EdgeInsets.all(10),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    font: fonts['bold'],
                    fontSize: 10,
                    color: color,
                  ),
                ),
                pw.Divider(height: 8, thickness: 0.5),
                ...rows.map(
                  (r) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 5),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          r.label,
                          style: pw.TextStyle(
                            font: fonts['regular'],
                            fontSize: 8,
                            color: _C.textMid,
                          ),
                        ),
                        pw.Text(
                          r.value,
                          style: pw.TextStyle(
                            font: fonts['bold'],
                            fontSize: 8,
                            color: _C.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  // ── Category breakdown ────────────────────────────────────────

  static pw.Widget _categoryBreakdown({
    required Map<String, pw.Font> fonts,
    required CategoryStats stats,
  }) {
    if (stats.stats.isEmpty) {
      return pw.Text(
        'No category data available',
        style: pw.TextStyle(
          font: fonts['italic'],
          fontSize: 9,
          color: _C.textLight,
        ),
      );
    }
    final maxPoints = stats.stats.fold<int>(1, (m, s) => math.max(m, s.points));
    return pw.Column(
      children: stats.stats.take(6).map((cat) {
        final frac = maxPoints > 0 ? cat.points / maxPoints : 0.0;
        final pct = stats.categoryPercentages[cat.categoryType] ?? 0;
        final displayColor = cat.displayColor.toPdf();

        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Row(
            children: [
              // Bullet dot with category color
              pw.Container(
                width: 6,
                height: 6,
                decoration: pw.BoxDecoration(
                  shape: pw.BoxShape.circle,
                  color: displayColor,
                ),
              ),
              pw.SizedBox(width: 8),
              // Category name and task counts
              pw.SizedBox(
                width: 130,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      cat.categoryName,
                      style: pw.TextStyle(
                        font: fonts['bold'],
                        fontSize: 9,
                        color: _C.textDark,
                      ),
                    ),
                    pw.Text(
                      '${cat.tasksCompleted}/${cat.totalTasks} tasks completed',
                      style: pw.TextStyle(
                        font: fonts['regular'],
                        fontSize: 7,
                        color: _C.textMid,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 12),
              // Responsive bar with inner percentage
              pw.Expanded(
                child: pw.LayoutBuilder(
                  builder: (ctx, constraints) {
                    final double fullWidth = constraints?.maxWidth ?? 200.0;
                    final double barWidth = (frac.clamp(0.05, 1.0) * fullWidth)
                        .toDouble();
                    return pw.Container(
                      height: 14,
                      alignment: pw.Alignment.centerLeft,
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFFF1F5F9),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Stack(
                        children: [
                          pw.Container(
                            width: barWidth,
                            decoration: pw.BoxDecoration(
                              color: displayColor,
                              borderRadius: pw.BorderRadius.circular(4),
                            ),
                            alignment: pw.Alignment.centerRight,
                            padding: const pw.EdgeInsets.only(right: 6),
                            child: pw.Text(
                              '${pct.toStringAsFixed(0)}%',
                              style: pw.TextStyle(
                                font: fonts['bold'],
                                fontSize: 7,
                                color: _C.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              pw.SizedBox(width: 12),
              // Total points earned
              pw.Text(
                '${_fmt(cat.points)} pts',
                style: pw.TextStyle(
                  font: fonts['bold'],
                  fontSize: 8.5,
                  color: _C.textDark,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Weekly bar chart ──────────────────────────────────────────

  static pw.Widget _weeklyBarChart({
    required Map<String, pw.Font> fonts,
    required WeeklyHistory history,
    DateTime? signupDate,
  }) {
    final DateTime? normSignup = signupDate != null
        ? DateTime(signupDate.year, signupDate.month, signupDate.day)
        : null;

    final stats = history.weeklyStats.where((w) {
      if (normSignup == null) return true;
      final midnightW = DateTime(w.weekStart.year, w.weekStart.month, w.weekStart.day);
      return !midnightW.isBefore(normSignup);
    }).take(12).toList();

    if (stats.isEmpty) {
      return pw.Text(
        'No weekly data yet',
        style: pw.TextStyle(
          font: fonts['italic'],
          fontSize: 9,
          color: _C.textLight,
        ),
      );
    }

    final maxPts = stats.fold<int>(1, (m, s) => math.max(m, s.points));
    const chartHeight = 90.0;

    return pw.Container(
      height: chartHeight + 35, // extra room for labels
      child: pw.Stack(
        children: [
          // 1. Gridlines (25%, 50%, 75%)
          pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.SizedBox(height: 5), // top space
              // 75% gridline
              pw.Row(
                children: [
                  pw.SizedBox(
                    width: 20,
                    child: pw.Text(
                      '${(maxPts * 0.75).round()}',
                      style: pw.TextStyle(
                        font: fonts['regular'],
                        fontSize: 5,
                        color: _C.textLight,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Container(
                      height: 0.5,
                      color: PdfColor.fromInt(0xFFE2E8F0),
                    ),
                  ),
                ],
              ),
              // 50% gridline
              pw.Row(
                children: [
                  pw.SizedBox(
                    width: 20,
                    child: pw.Text(
                      '${(maxPts * 0.50).round()}',
                      style: pw.TextStyle(
                        font: fonts['regular'],
                        fontSize: 5,
                        color: _C.textLight,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Container(
                      height: 0.5,
                      color: PdfColor.fromInt(0xFFE2E8F0),
                    ),
                  ),
                ],
              ),
              // 25% gridline
              pw.Row(
                children: [
                  pw.SizedBox(
                    width: 20,
                    child: pw.Text(
                      '${(maxPts * 0.25).round()}',
                      style: pw.TextStyle(
                        font: fonts['regular'],
                        fontSize: 5,
                        color: _C.textLight,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Container(
                      height: 0.5,
                      color: PdfColor.fromInt(0xFFE2E8F0),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 25), // bottom spacing for x-axis
            ],
          ),

          // 2. Bars overlay
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 20),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: stats.asMap().entries.map((e) {
                final w = e.value;
                final frac = maxPts > 0 ? w.points / maxPts : 0.0;
                final isCurrent = e.key == stats.length - 1;
                final barHeightActual = (chartHeight * frac).clamp(
                  2.0,
                  chartHeight,
                );

                // Date label formatting: e.g. "13 May"
                final dateStr =
                    '${w.weekStart.day} ${_monthName(w.weekStart.month).substring(0, math.min(3, _monthName(w.weekStart.month).length))}';

                return pw.Expanded(
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      // Top value label
                      if (w.points > 0)
                        pw.Text(
                          '${w.points}',
                          style: pw.TextStyle(
                            font: fonts['bold'],
                            fontSize: 6,
                            color: isCurrent ? _C.gold : _C.textDark,
                          ),
                        ),
                      pw.SizedBox(height: 2),
                      // The bar
                      pw.Container(
                        height: barHeightActual,
                        margin: const pw.EdgeInsets.symmetric(horizontal: 4),
                        decoration: pw.BoxDecoration(
                          color: isCurrent ? _C.gold : _C.navy,
                          borderRadius: const pw.BorderRadius.only(
                            topLeft: pw.Radius.circular(3),
                            topRight: pw.Radius.circular(3),
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      // Week number
                      pw.Text(
                        'W${w.weekNumber}',
                        style: pw.TextStyle(
                          font: fonts['bold'],
                          fontSize: 6.5,
                          color: isCurrent ? _C.gold : _C.textDark,
                        ),
                      ),
                      // Week date sublabel
                      pw.Text(
                        dateStr,
                        style: pw.TextStyle(
                          font: fonts['regular'],
                          fontSize: 5,
                          color: _C.textLight,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Streak hero card ──────────────────────────────────────────

  static pw.Widget _streakHeroCard({
    required Map<String, pw.Font> fonts,
    required String label,
    required String value,
    required String unit,
    required PdfColor color,
    required String subLabel,
  }) => pw.Container(
    decoration: pw.BoxDecoration(
      color: _C.white,
      borderRadius: pw.BorderRadius.circular(8),
      boxShadow: [
        pw.BoxShadow(color: PdfColor.fromInt(0x09000000), blurRadius: 4),
      ],
    ),
    child: pw.ClipRRect(
      horizontalRadius: 8,
      verticalRadius: 8,
      child: pw.Column(
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.only(
              top: 12,
              left: 12,
              right: 12,
              bottom: 8,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  label,
                  style: pw.TextStyle(
                    font: fonts['regular'],
                    fontSize: 7,
                    letterSpacing: 0.5,
                    color: _C.textLight,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  value,
                  style: pw.TextStyle(
                    font: fonts['bold'],
                    fontSize: 28,
                    color: color,
                  ),
                ),
                pw.Text(
                  unit,
                  style: pw.TextStyle(
                    font: fonts['regular'],
                    fontSize: 8,
                    color: _C.textMid,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: pw.BoxDecoration(
                    color: color.shade(0.15),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    subLabel,
                    style: pw.TextStyle(
                      font: fonts['bold'],
                      fontSize: 6,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          pw.Container(height: 3, color: color, width: double.infinity),
        ],
      ),
    ),
  );

  // ── Milestone progress bar ────────────────────────────────────

  static pw.Widget _milestoneProgressBar({
    required Map<String, pw.Font> fonts,
    required Streaks streaks,
  }) {
    final current = streaks.current.days;
    final milestones = streaks.milestones.take(8).toList();
    final maxMs = milestones.isNotEmpty ? milestones.last : 365;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Milestone Progress',
          style: pw.TextStyle(
            font: fonts['bold'],
            fontSize: 9,
            color: _C.textDark,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Container(
          height: 8,
          decoration: pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFE2E8F0),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Stack(
            children: [
              pw.Positioned(
                top: 0,
                bottom: 0,
                left: 0,
                child: pw.SizedBox(
                  width:
                      (current / maxMs).clamp(0.0, 1.0) *
                      200, // Assuming 200px width for the bar
                  child: pw.Container(
                    decoration: pw.BoxDecoration(
                      color: _C.gold,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: milestones.map((ms) {
            final reached = current >= ms;
            return pw.Column(
              children: [
                pw.Text(
                  '$ms',
                  style: pw.TextStyle(
                    font: fonts[reached ? 'bold' : 'regular'],
                    fontSize: 7,
                    color: reached ? _C.gold : _C.textLight,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── 30-day calendar grid ──────────────────────────────────────

  static pw.Widget _streakCalendar({
    required Map<String, pw.Font> fonts,
    required StreakHistory history,
    DateTime? signupDate,
  }) {
    final today = DateTime.now();
    final DateTime? normSignup = signupDate != null
        ? DateTime(signupDate.year, signupDate.month, signupDate.day)
        : null;

    final days = List.generate(30, (i) {
      final d = today.subtract(Duration(days: 29 - i));
      final midnightD = DateTime(d.year, d.month, d.day);
      final isBeforeSignup =
          normSignup != null && midnightD.isBefore(normSignup);
      final key =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final active = !isBeforeSignup && history.calendar30Days[key] == true;
      return _CalDay(d, active);
    });

    return pw.Wrap(
      spacing: 4,
      runSpacing: 4,
      children: List.generate(days.length, (i) {
        final day = days[i];
        final midnightD = DateTime(day.date.year, day.date.month, day.date.day);
        final isBeforeSignup = normSignup != null && midnightD.isBefore(normSignup);

        PdfColor boxColor;
        String textStr;
        PdfColor textColor;

        if (isBeforeSignup) {
          boxColor = PdfColor.fromInt(0xFFCBD5E1);
          textStr = '—';
          textColor = _C.white;
        } else if (day.active) {
          boxColor = _C.green;
          textStr = '${day.date.day}';
          textColor = _C.white;
        } else {
          boxColor = PdfColor.fromInt(0xFFE2E8F0);
          textStr = '${day.date.day}';
          textColor = _C.textLight;
        }

        return pw.Container(
          width: 18,
          height: 18,
          decoration: pw.BoxDecoration(
            color: boxColor,
            borderRadius: pw.BorderRadius.circular(3),
          ),
          child: pw.Center(
            child: pw.Text(
              textStr,
              style: pw.TextStyle(
                font: fonts[day.active ? 'bold' : 'regular'],
                fontSize: 6,
                color: textColor,
              ),
            ),
          ),
        );
      }),
    );
  }

  // ── Daily points mini bar chart ───────────────────────────────

  static pw.Widget _dailyPointsChart({
    required Map<String, pw.Font> fonts,
    required List<DailyStatPoint> stats,
    DateTime? signupDate,
  }) {
    final DateTime? normSignup = signupDate != null
        ? DateTime(signupDate.year, signupDate.month, signupDate.day)
        : null;

    final filteredStats = stats.where((s) {
      if (normSignup == null) return true;
      final midnightS = DateTime(s.date.year, s.date.month, s.date.day);
      return !midnightS.isBefore(normSignup);
    }).toList();

    if (filteredStats.isEmpty) {
      return pw.Text(
        'No data yet',
        style: pw.TextStyle(
          font: fonts['italic'],
          fontSize: 9,
          color: _C.textLight,
        ),
      );
    }

    final maxPts = filteredStats.fold<int>(1, (m, s) => math.max(m, s.points));
    const chartH = 90.0;
    final double avgPoints =
        filteredStats.fold<int>(0, (sum, s) => sum + s.points) / filteredStats.length;
    final double avgY = maxPts > 0 ? (avgPoints / maxPts) * chartH : 0.0;

    return pw.Container(
      height: chartH + 20, // room for x-axis date labels
      child: pw.Stack(
        children: [
          // 1. Gridlines and Y-axis labels
          pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              // Max points line
              pw.Row(
                children: [
                  pw.SizedBox(
                    width: 20,
                    child: pw.Text(
                      '$maxPts',
                      style: pw.TextStyle(
                        font: fonts['regular'],
                        fontSize: 6,
                        color: _C.textLight,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Container(
                      height: 0.5,
                      color: PdfColor.fromInt(0xFFF1F5F9),
                    ),
                  ),
                ],
              ),
              // Mid points line
              pw.Row(
                children: [
                  pw.SizedBox(
                    width: 20,
                    child: pw.Text(
                      '${(maxPts / 2).round()}',
                      style: pw.TextStyle(
                        font: fonts['regular'],
                        fontSize: 6,
                        color: _C.textLight,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Container(
                      height: 0.5,
                      color: PdfColor.fromInt(0xFFF1F5F9),
                    ),
                  ),
                ],
              ),
              // Baseline
              pw.Row(
                children: [
                  pw.SizedBox(
                    width: 20,
                    child: pw.Text(
                      '0',
                      style: pw.TextStyle(
                        font: fonts['regular'],
                        fontSize: 6,
                        color: _C.textLight,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Container(
                      height: 1.0,
                      color: _C.navy,
                    ), // 1px Navy solid baseline
                  ),
                ],
              ),
              pw.SizedBox(height: 12), // space for date labels
            ],
          ),

          // 2. Average points dashed line (Gold)
          if (avgPoints > 0)
            pw.Positioned(
              bottom: avgY + 12, // shift up to align above baseline container height offset
              left: 20,
              right: 0,
              child: pw.Row(
                children: [
                  _dashedLine(
                    color: _C.gold,
                    height: 1.0,
                    dashWidth: 4,
                    dashGap: 4,
                  ),
                  pw.SizedBox(width: 4),
                  pw.Text(
                    'Avg: ${avgPoints.round()}',
                    style: pw.TextStyle(
                      font: fonts['bold'],
                      fontSize: 5,
                      color: _C.gold,
                    ),
                  ),
                ],
              ),
            ),

          // 3. Bars overlay and date sublabels
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 20),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: filteredStats.asMap().entries.map((e) {
                final idx = e.key;
                final s = e.value;
                final frac = maxPts > 0 ? s.points / maxPts : 0.0;
                final barH = (chartH * frac).clamp(1.0, chartH);

                // Bar coloring logic by point values
                PdfColor barColor = PdfColor.fromInt(0xFFE2E8F0); // Slate Grey for 0 pts
                if (s.points > 150) {
                  barColor = PdfColor.fromInt(0xFF1D4ED8); // Dark Blue (151+)
                } else if (s.points > 50) {
                  barColor = PdfColor.fromInt(0xFF3B82F6); // Blue (51-150)
                } else if (s.points > 0) {
                  barColor = PdfColor.fromInt(0xFF93C5FD); // Light Blue (1-50)
                }

                final showLabel = (idx % 5 == 0) || (idx == filteredStats.length - 1);

                return pw.Expanded(
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      // The bar
                      pw.Container(
                        height: barH,
                        margin: const pw.EdgeInsets.symmetric(horizontal: 0.5),
                        color: barColor,
                      ),
                      pw.SizedBox(height: 4),
                      // Date label below (every 5th bar)
                      pw.SizedBox(
                        height: 8,
                        child: showLabel
                            ? pw.Text(
                                s.shortDate,
                                style: pw.TextStyle(
                                  font: fonts['regular'],
                                  fontSize: 5,
                                  color: _C.textLight,
                                ),
                              )
                            : pw.SizedBox.shrink(),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Mood line "chart" (dots connected) ───────────────────────

  static pw.Widget _moodLineChart({
    required Map<String, pw.Font> fonts,
    required List<MoodDataPoint> history,
    DateTime? signupDate,
  }) {
    final DateTime? normSignup = signupDate != null
        ? DateTime(signupDate.year, signupDate.month, signupDate.day)
        : null;

    final filteredHistory = history.where((m) {
      if (normSignup == null) return true;
      final midnightM = DateTime(m.date.year, m.date.month, m.date.day);
      return !midnightM.isBefore(normSignup);
    }).toList();

    if (filteredHistory.isEmpty) {
      return pw.Container(
        height: 80,
        alignment: pw.Alignment.center,
        child: pw.Text(
          'No mood data recorded yet',
          style: pw.TextStyle(
            font: fonts['italic'],
            fontSize: 9,
            color: _C.textLight,
          ),
        ),
      );
    }

    const chartH = 80.0;

    return pw.Column(
      children: [
        pw.Container(
          height: chartH,
          child: pw.Row(
            children: [
              // Y-axis indicators
              pw.SizedBox(
                width: 25,
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '10',
                      style: pw.TextStyle(
                        font: fonts['regular'],
                        fontSize: 5.5,
                        color: _C.textLight,
                      ),
                    ),
                    pw.Text(
                      '7',
                      style: pw.TextStyle(
                        font: fonts['regular'],
                        fontSize: 5.5,
                        color: _C.textLight,
                      ),
                    ),
                    pw.Text(
                      '4',
                      style: pw.TextStyle(
                        font: fonts['regular'],
                        fontSize: 5.5,
                        color: _C.textLight,
                      ),
                    ),
                    pw.Text(
                      '1',
                      style: pw.TextStyle(
                        font: fonts['regular'],
                        fontSize: 5.5,
                        color: _C.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              // The custom paint chart using the pdf package painter callback typedef
              pw.Expanded(
                child: pw.CustomPaint(
                  size: const PdfPoint(0, chartH),
                  painter: (canvas, size) =>
                      _paintMoodChart(canvas, size, filteredHistory),
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 6),
        // X-axis label row
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 25),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                '30 days ago',
                style: pw.TextStyle(
                  font: fonts['regular'],
                  fontSize: 6,
                  color: _C.textLight,
                ),
              ),
              pw.Text(
                'Today',
                style: pw.TextStyle(
                  font: fonts['regular'],
                  fontSize: 6,
                  color: _C.textLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Custom drawing function for Mood Chart ───────────────────
  static void _paintMoodChart(
    PdfGraphics canvas,
    PdfPoint size,
    List<MoodDataPoint> history,
  ) {
    if (history.isEmpty) return;

    final points = history.take(30).toList().reversed.toList();
    if (points.length < 2) return;

    final double dx = size.x / (points.length - 1);
    final double chartHeight = size.y - 20;
    final double scaleY = chartHeight / 9.0; // 1 to 10 scale

    double getY(double val) {
      return 10 + (val - 1) * scaleY;
    }

    // 1. Draw layered opacity background zones
    // Red zone (mood 1-3)
    canvas.setFillColor(PdfColor.fromInt(0x12EF5350)); // Red ~7% opacity
    canvas.drawRect(0, getY(1), size.x, getY(3) - getY(1));
    canvas.fillPath();

    // Amber zone (mood 4-6)
    canvas.setFillColor(PdfColor.fromInt(0x12FFCA28)); // Amber ~7% opacity
    canvas.drawRect(0, getY(4), size.x, getY(6) - getY(4));
    canvas.fillPath();

    // Green zone (mood 7-10)
    canvas.setFillColor(PdfColor.fromInt(0x1266BB6A)); // Green ~7% opacity
    canvas.drawRect(0, getY(7), size.x, size.y - getY(7));
    canvas.fillPath();

    // 2. Dashed reference lines at y = 4 (Red) and y = 7 (Green)
    canvas.setLineWidth(0.5);
    canvas.setLineDashPattern([3, 3]);

    // Line at y = 4
    canvas.setStrokeColor(PdfColor.fromInt(0x80EF5350)); // faint red
    canvas.moveTo(0, getY(4));
    canvas.lineTo(size.x, getY(4));
    canvas.strokePath();

    // Line at y = 7
    canvas.setStrokeColor(PdfColor.fromInt(0x8066BB6A)); // faint green
    canvas.moveTo(0, getY(7));
    canvas.lineTo(size.x, getY(7));
    canvas.strokePath();

    // Reset dash pattern for graph lines
    canvas.setLineDashPattern([]);

    // 3. Connect points with polyline (Navy)
    canvas.setStrokeColor(PdfColor.fromInt(0xFF0F172A)); // Dark Slate
    canvas.setLineWidth(1.5);
    canvas.setLineJoin(PdfLineJoin.round);

    for (int i = 0; i < points.length; i++) {
      final x = i * dx;
      final y = getY(points[i].value.toDouble());
      if (i == 0) {
        canvas.moveTo(x, y);
      } else {
        canvas.lineTo(x, y);
      }
    }
    canvas.strokePath();

    // 4. White circular dots with border at each point
    for (int i = 0; i < points.length; i++) {
      final x = i * dx;
      final double val = points[i].value.toDouble();
      final y = getY(val);

      // White fill circle
      canvas.setFillColor(PdfColor.fromInt(0xFFFFFFFF));
      canvas.drawEllipse(x, y, 3.5, 3.5);
      canvas.fillPath();

      // Border circle matching the mood color
      final moodCol = _moodColor(val);
      canvas.setStrokeColor(moodCol);
      canvas.setLineWidth(1.0);
      canvas.drawEllipse(x, y, 3.5, 3.5);
      canvas.strokePath();
    }
  }

  // ── Mood frequency bars ───────────────────────────────────────

  static pw.Widget _moodFrequencyBars({
    required Map<String, pw.Font> fonts,
    required Map<String, int> frequency,
  }) {
    if (frequency.isEmpty) {
      return pw.Text(
        'No mood data yet',
        style: pw.TextStyle(
          font: fonts['italic'],
          fontSize: 9,
          color: _C.textLight,
        ),
      );
    }

    final sorted = frequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxCount = sorted.first.value;

    return pw.Column(
      children: sorted.take(6).map((e) {
        final frac = maxCount > 0 ? e.value / maxCount : 0.0;
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 6),
          child: pw.Row(
            children: [
              pw.SizedBox(
                width: 70,
                child: pw.Text(
                  e.key,
                  style: pw.TextStyle(
                    font: fonts['regular'],
                    fontSize: 9,
                    color: _C.textMid,
                  ),
                ),
              ),
              pw.Expanded(
                child: pw.Container(
                  height: 10,
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFFF1F5F9),
                    borderRadius: pw.BorderRadius.circular(3),
                  ),
                  child: pw.Stack(
                    children: [
                      pw.Positioned(
                        top: 0,
                        bottom: 0,
                        left: 0,
                        child: pw.SizedBox(
                          width: frac.clamp(0.02, 1.0) * 200,
                          child: pw.Container(
                            decoration: pw.BoxDecoration(
                              color: _C.purple,
                              borderRadius: pw.BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                '${e.value}x',
                style: pw.TextStyle(
                  font: fonts['bold'],
                  fontSize: 8,
                  color: _C.textDark,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Mood scale reference ──────────────────────────────────────

  static pw.Widget _moodScaleReference({required Map<String, pw.Font> fonts}) {
    final levels = [
      _MoodLevel(1, 'Very Low', _C.red),
      _MoodLevel(3, 'Low', PdfColor.fromInt(0xFFFF7043)),
      _MoodLevel(5, 'Neutral', _C.amber),
      _MoodLevel(7, 'Good', _C.green),
      _MoodLevel(9, 'Great', PdfColor.fromInt(0xFF2196F3)),
    ];
    return pw.Row(
      children: levels.map((l) {
        return pw.Expanded(
          child: pw.Container(
            margin: const pw.EdgeInsets.symmetric(horizontal: 2),
            padding: const pw.EdgeInsets.symmetric(vertical: 6),
            decoration: pw.BoxDecoration(
              color: l.color.shade(0.15),
              borderRadius: pw.BorderRadius.circular(4),
              border: pw.Border.all(color: l.color.shade(0.3)),
            ),
            child: pw.Column(
              children: [
                pw.Text(
                  '${l.rating}',
                  style: pw.TextStyle(
                    font: fonts['bold'],
                    fontSize: 12,
                    color: l.color,
                  ),
                ),
                pw.Text(
                  l.label,
                  style: pw.TextStyle(
                    font: fonts['regular'],
                    fontSize: 7,
                    color: _C.textMid,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Today's mood details card ─────────────────────────────────

  static pw.Widget _todayMoodCard({
    required Map<String, pw.Font> fonts,
    required TodayMood? today,
  }) {
    if (today == null || today.rating == 0) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromInt(0xFFF1F5F9),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Row(
          children: [
            pw.Text('💤', style: pw.TextStyle(fontSize: 14)),
            pw.SizedBox(width: 10),
            pw.Text(
              'No diary reflection or mood entry recorded for today yet.',
              style: pw.TextStyle(
                font: fonts['italic'],
                fontSize: 8.5,
                color: _C.textLight,
              ),
            ),
          ],
        ),
      );
    }

    final PdfColor mc = _moodColor(today.rating.toDouble());

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: mc.shade(0.1),
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: mc.shade(0.3), width: 0.5),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.all(6),
            decoration: pw.BoxDecoration(
              color: mc.shade(0.2),
              shape: pw.BoxShape.circle,
            ),
            child: pw.Text(today.emoji, style: pw.TextStyle(fontSize: 14)),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Today\'s Mood Reflection',
                      style: pw.TextStyle(
                        font: fonts['bold'],
                        fontSize: 9.5,
                        color: _C.textDark,
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: pw.BoxDecoration(
                        color: mc,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        'RATING: ${today.rating}/10',
                        style: pw.TextStyle(
                          font: fonts['bold'],
                          fontSize: 6.5,
                          color: _C.white,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  today.label.isEmpty
                      ? 'Logged with no written reflection.'
                      : '"${today.label}"',
                  style: pw.TextStyle(
                    font: today.label.isEmpty
                        ? fonts['italic']
                        : fonts['regular'],
                    fontSize: 8.5,
                    color: _C.textMid,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tier breakdown row ────────────────────────────────────────

  static pw.Widget _tierBreakdown({
    required Map<String, pw.Font> fonts,
    required Rewards rewards,
  }) {
    final tiers = [
      _TierItem('Nova', rewards.novaCount, _C.tier('nova')),
      _TierItem('Radiant', rewards.radiantCount, _C.tier('radiant')),
      _TierItem('Prism', rewards.prismCount, _C.tier('prism')),
      _TierItem('Crystal', rewards.crystalCount, _C.tier('crystal')),
      _TierItem('Blaze', rewards.blazeCount, _C.tier('blaze')),
      _TierItem('Ember', rewards.emberCount, _C.tier('ember')),
      _TierItem('Flame', rewards.flameCount, _C.tier('flame')),
      _TierItem('Spark', rewards.sparkCount, _C.tier('spark')),
    ];

    return pw.Row(
      children: tiers.map((t) {
        final hasAny = t.count > 0;
        return pw.Expanded(
          child: pw.Container(
            margin: const pw.EdgeInsets.symmetric(horizontal: 3),
            padding: const pw.EdgeInsets.symmetric(vertical: 10),
            decoration: pw.BoxDecoration(
              color: hasAny
                  ? t.color.shade(0.12)
                  : PdfColor.fromInt(0xFFF1F5F9),
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(
                color: hasAny
                    ? t.color.shade(0.4)
                    : PdfColor.fromInt(0xFFE2E8F0),
              ),
            ),
            child: pw.Column(
              children: [
                pw.Text(
                  '${t.count}',
                  style: pw.TextStyle(
                    font: fonts['bold'],
                    fontSize: 16,
                    color: hasAny ? t.color : _C.textLight,
                  ),
                ),
                pw.Text(
                  t.name,
                  style: pw.TextStyle(
                    font: fonts['regular'],
                    fontSize: 7,
                    color: hasAny ? _C.textMid : _C.textLight,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Recent rewards list ───────────────────────────────────────

  static pw.Widget _recentRewardsList({
    required Map<String, pw.Font> fonts,
    required List<UnlockedReward> rewards,
  }) {
    if (rewards.isEmpty) {
      return pw.Text(
        'No rewards earned yet — keep going!',
        style: pw.TextStyle(
          font: fonts['italic'],
          fontSize: 9,
          color: _C.textLight,
        ),
      );
    }
    return pw.Column(
      children: rewards.take(12).map((r) {
        final tc = _C.tier(r.tier);
        return pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 6),
          padding: const pw.EdgeInsets.only(top: 8, bottom: 8, right: 12),
          decoration: pw.BoxDecoration(
            color: _C.white,
            borderRadius: pw.BorderRadius.circular(6),
            boxShadow: [
              pw.BoxShadow(color: PdfColor.fromInt(0x07000000), blurRadius: 3),
            ],
          ),
          child: pw.Row(
            children: [
              pw.Container(
                width: 3,
                height: 32,
                decoration: pw.BoxDecoration(
                  color: tc,
                  borderRadius: const pw.BorderRadius.only(
                    topRight: pw.Radius.circular(2),
                    bottomRight: pw.Radius.circular(2),
                  ),
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Container(
                width: 28,
                height: 28,
                decoration: pw.BoxDecoration(
                  color: tc.shade(0.12),
                  shape: pw.BoxShape.circle,
                ),
                child: pw.Center(
                  child: pw.Text(
                    r.tier.isEmpty ? 'S' : r.tier[0].toUpperCase(),
                    style: pw.TextStyle(
                      font: fonts['bold'],
                      fontSize: 12,
                      color: tc,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      r.tagName.isEmpty ? r.tier.toUpperCase() : r.tagName,
                      style: pw.TextStyle(
                        font: fonts['bold'],
                        fontSize: 9,
                        color: _C.textDark,
                      ),
                    ),
                    pw.Text(
                      r.taskName.isEmpty ? r.earnedFrom : r.taskName,
                      style: pw.TextStyle(
                        font: fonts['regular'],
                        fontSize: 8,
                        color: _C.textMid,
                      ),
                    ),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    r.timeAgo.isEmpty ? '' : r.timeAgo,
                    style: pw.TextStyle(
                      font: fonts['regular'],
                      fontSize: 7,
                      color: _C.textLight,
                    ),
                  ),
                  pw.Text(
                    r.tier.toUpperCase(),
                    style: pw.TextStyle(
                      font: fonts['bold'],
                      fontSize: 8,
                      color: tc,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Info chip ─────────────────────────────────────────────────

  static pw.Widget _infoChip({
    required Map<String, pw.Font> fonts,
    required String label,
    required String value,
    required PdfColor color,
  }) => pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: pw.BoxDecoration(
      color: color.shade(0.1),
      borderRadius: pw.BorderRadius.circular(6),
      border: pw.Border.all(color: color.shade(0.3)),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            font: fonts['regular'],
            fontSize: 7,
            color: _C.textMid,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(font: fonts['bold'], fontSize: 10, color: color),
        ),
      ],
    ),
  );

  // ── Section title ─────────────────────────────────────────────

  static pw.Widget _sectionTitle({
    required Map<String, pw.Font> fonts,
    required String title,
  }) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Row(
        children: [
          pw.Container(
            width: 3,
            height: 14,
            color: _C.gold,
            margin: const pw.EdgeInsets.only(right: 8),
          ),
          pw.Text(
            title,
            style: pw.TextStyle(
              font: fonts['bold'],
              fontSize: 12,
              color: _C.textDark,
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 4),
      pw.Divider(
        height: 1,
        thickness: 0.5,
        color: PdfColor.fromInt(0xFFE2E8F0),
      ),
    ],
  );

  // ── Diagonal Faint Watermark (Pages 2-7) ──────────────────────
  static pw.Widget _pageWatermark(Map<String, pw.Font> fonts) {
    return pw.Positioned.fill(
      child: pw.Center(
        child: pw.Transform.rotate(
          angle: -0.785398, // -45 degrees
          child: pw.Text(
            'TIME CHART',
            style: pw.TextStyle(
              font: fonts['bold'],
              fontSize: 75,
              color: PdfColor.fromInt(0x080D1B2A), // ~3% opacity navy
            ),
          ),
        ),
      ),
    );
  }

  // ── Top and Bottom bands for pages 2-7 ────────────────────────
  static pw.Widget _topBand() {
    return pw.Column(
      children: [
        pw.Container(height: 4, color: _C.gold),
        pw.Container(height: 2, color: _C.navy),
      ],
    );
  }

  static pw.Widget _bottomBand() {
    return pw.Column(
      children: [
        pw.Container(height: 2, color: _C.navy),
        pw.Container(height: 4, color: _C.gold),
      ],
    );
  }

  // ── Dashed line (for targets/average lines) ────────────────────
  static pw.Widget _dashedLine({
    required PdfColor color,
    double height = 1,
    double dashWidth = 4,
    double dashGap = 3,
  }) {
    return pw.LayoutBuilder(
      builder: (ctx, constraints) {
        final double width = constraints?.maxWidth ?? 200.0;
        final int count = (width / (dashWidth + dashGap)).floor();
        return pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: List.generate(count, (_) {
            return pw.Container(width: dashWidth, height: height, color: color);
          }),
        );
      },
    );
  }

  // ── LaTeX-style Recent Activity Table (Page 2) ─────────────────
  static pw.Widget _recentActivityTable({
    required Map<String, pw.Font> fonts,
    required List<RecentActivityItem> items,
  }) {
    if (items.isEmpty) {
      return pw.Text(
        'No recent activities logged.',
        style: pw.TextStyle(
          font: fonts['italic'],
          fontSize: 8,
          color: _C.textLight,
        ),
      );
    }

    final displayItems = items.take(5).toList();
    final headerStyle = pw.TextStyle(
      font: fonts['bold'],
      fontSize: 7,
      color: _C.white,
    );
    final cellStyle = pw.TextStyle(
      font: fonts['regular'],
      fontSize: 7,
      color: _C.textDark,
    );
    final rightCellStyle = pw.TextStyle(
      font: fonts['bold'],
      fontSize: 7,
      color: _C.textDark,
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Table(
          border: const pw.TableBorder(
            horizontalInside: pw.BorderSide(
              width: 0.5,
              color: PdfColor.fromInt(0xFFE2E8F0),
            ),
            bottom: pw.BorderSide(
              width: 1,
              color: PdfColor.fromInt(0xFFCBD5E1),
            ),
          ),
          columnWidths: {
            0: const pw.FlexColumnWidth(0.8), // Date
            1: const pw.FlexColumnWidth(2.5), // Activity
            2: const pw.FlexColumnWidth(1.2), // Type
            3: const pw.FlexColumnWidth(1.0), // Points
            4: const pw.FlexColumnWidth(1.2), // Status
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: _C.navy),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text('Date', style: headerStyle),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text('Activity', style: headerStyle),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text('Type', style: headerStyle),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                    'Points',
                    style: headerStyle,
                    textAlign: pw.TextAlign.right,
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text('Status', style: headerStyle),
                ),
              ],
            ),
            ...displayItems.asMap().entries.map((e) {
              final idx = e.key;
              final item = e.value;
              final rowColor = idx % 2 == 0
                  ? _C.white
                  : PdfColor.fromInt(0xFFF8FAFC);
              final statusText = item.action.replaceAll('_', ' ').toUpperCase();

              return pw.TableRow(
                decoration: pw.BoxDecoration(color: rowColor),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      '${item.createdAt.day}/${item.createdAt.month}',
                      style: cellStyle,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(item.message, style: cellStyle),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(item.type.toUpperCase(), style: cellStyle),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      item.points > 0 ? '+${item.points} pts' : '—',
                      style: rightCellStyle,
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(statusText, style: cellStyle),
                  ),
                ],
              );
            }).toList(),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Showing ${displayItems.length} of ${items.length} recent activities',
          style: pw.TextStyle(
            font: fonts['italic'],
            fontSize: 6.5,
            color: _C.textLight,
          ),
        ),
      ],
    );
  }

  // ── LaTeX-style Combined Stats Table (Page 3) ──────────────────
  static pw.Widget _combinedStatsTable({
    required Map<String, pw.Font> fonts,
    required DashboardOverview ov,
  }) {
    final headerStyle = pw.TextStyle(
      font: fonts['bold'],
      fontSize: 8,
      color: _C.white,
    );
    final cellStyle = pw.TextStyle(
      font: fonts['regular'],
      fontSize: 8,
      color: _C.textDark,
    );
    final boldStyle = pw.TextStyle(
      font: fonts['bold'],
      fontSize: 8,
      color: _C.textDark,
    );

    final totalTasks =
        ov.dailyTasksStats.totalDayTasks +
        ov.weeklyTasksStats.totalWeekTasks +
        ov.longGoalsStats.totalLongGoals +
        ov.bucketListStats.totalBucketItems;
    final totalCompleted =
        ov.dailyTasksStats.dayTasksCompleted +
        ov.weeklyTasksStats.weekTasksCompleted +
        ov.longGoalsStats.longGoalsCompleted +
        ov.bucketListStats.bucketItemsCompleted;
    final totalPoints =
        ov.dailyTasksStats.totalDayTasksPoints +
        ov.weeklyTasksStats.totalWeekTasksPoints +
        ov.longGoalsStats.totalLongGoalsPoints +
        ov.bucketListStats.totalBucketPoints;

    return pw.Table(
      border: const pw.TableBorder(
        horizontalInside: pw.BorderSide(
          width: 0.5,
          color: PdfColor.fromInt(0xFFE2E8F0),
        ),
        bottom: pw.BorderSide(width: 1, color: PdfColor.fromInt(0xFFCBD5E1)),
      ),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.2), // Module
        1: const pw.FlexColumnWidth(1.0), // Scheduled/Total
        2: const pw.FlexColumnWidth(1.2), // Completed
        3: const pw.FlexColumnWidth(1.5), // Avg Progress/Rating
        4: const pw.FlexColumnWidth(1.0), // Points
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _C.navy),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text('Module', style: headerStyle),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text('Schedules/Totals', style: headerStyle),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text('Completions', style: headerStyle),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text('Progress / Rating', style: headerStyle),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text('Points Earned', style: headerStyle),
            ),
          ],
        ),
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _C.white),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text('Daily Habits', style: boldStyle),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                '${ov.dailyTasksStats.totalDayTasks}',
                style: cellStyle,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                '${ov.dailyTasksStats.dayTasksCompleted} (${ov.dailyTasksStats.dayTasksCompletionRate.toStringAsFixed(0)}%)',
                style: cellStyle,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                'Rating: ${ov.dailyTasksStats.dayTasksCompletionRating.toStringAsFixed(1)}/10',
                style: cellStyle,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                '${_fmt(ov.dailyTasksStats.totalDayTasksPoints)} pts',
                style: boldStyle,
              ),
            ),
          ],
        ),
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFF8FAFC),
          ),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text('Weekly Focus', style: boldStyle),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                '${ov.weeklyTasksStats.totalWeekTasks}',
                style: cellStyle,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                '${ov.weeklyTasksStats.weekTasksCompleted} (${ov.weeklyTasksStats.weekTasksCompletionRate.toStringAsFixed(0)}%)',
                style: cellStyle,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                'Rating: ${ov.weeklyTasksStats.weekTasksCompletionRating.toStringAsFixed(1)}/10',
                style: cellStyle,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                '${_fmt(ov.weeklyTasksStats.totalWeekTasksPoints)} pts',
                style: boldStyle,
              ),
            ),
          ],
        ),
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _C.white),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text('Long Goals', style: boldStyle),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                '${ov.longGoalsStats.totalLongGoals}',
                style: cellStyle,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                '${ov.longGoalsStats.longGoalsCompleted} (${ov.longGoalsStats.longGoalsActive} active)',
                style: cellStyle,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                'Avg Progress: ${ov.longGoalsStats.longGoalsAverageProgress.toStringAsFixed(0)}%',
                style: cellStyle,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                '${_fmt(ov.longGoalsStats.totalLongGoalsPoints)} pts',
                style: boldStyle,
              ),
            ),
          ],
        ),
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFF8FAFC),
          ),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text('Bucket List', style: boldStyle),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                '${ov.bucketListStats.totalBucketItems}',
                style: cellStyle,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                '${ov.bucketListStats.bucketItemsCompleted} (${ov.bucketListStats.bucketItemsInProgress} active)',
                style: cellStyle,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                'Avg Progress: ${ov.bucketListStats.bucketAverageProgress.toStringAsFixed(0)}%',
                style: cellStyle,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                '${_fmt(ov.bucketListStats.totalBucketPoints)} pts',
                style: boldStyle,
              ),
            ),
          ],
        ),
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _C.gold.shade(0.12)),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                'Combined Summary',
                style: pw.TextStyle(
                  font: fonts['bold'],
                  fontSize: 8,
                  color: _C.navy,
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                '$totalTasks',
                style: pw.TextStyle(
                  font: fonts['bold'],
                  fontSize: 8,
                  color: _C.navy,
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                '$totalCompleted',
                style: pw.TextStyle(
                  font: fonts['bold'],
                  fontSize: 8,
                  color: _C.navy,
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                '-',
                style: pw.TextStyle(
                  font: fonts['bold'],
                  fontSize: 8,
                  color: _C.navy,
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                '${_fmt(totalPoints)} pts',
                style: pw.TextStyle(
                  font: fonts['bold'],
                  fontSize: 8,
                  color: _C.navy,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Highlighting Exceptional Stats Highlight Box (Page 2) ───────
  static pw.Widget _statHighlightBox({
    required Map<String, pw.Font> fonts,
    required String title,
    required String description,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: pw.BoxDecoration(
        color: _C.gold.shade(0.08),
        borderRadius: pw.BorderRadius.circular(6),
        border: const pw.Border(left: pw.BorderSide(color: _C.gold, width: 4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Text(
                '⭐ ACHIEVEMENT DETECTED',
                style: pw.TextStyle(
                  font: fonts['bold'],
                  fontSize: 7,
                  letterSpacing: 1.5,
                  color: _C.gold,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            title,
            style: pw.TextStyle(
              font: fonts['bold'],
              fontSize: 12,
              color: _C.navy,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            description,
            style: pw.TextStyle(
              font: fonts['regular'],
              fontSize: 8.5,
              color: _C.textMid,
            ),
          ),
        ],
      ),
    );
  }

  // ── LaTeX-style Streak Break Analysis Table (Page 4) ───────────
  static pw.Widget _streakBreakTable({
    required Map<String, pw.Font> fonts,
    required List<StreakBreak> breaks,
  }) {
    if (breaks.isEmpty) {
      return pw.Text(
        'Excellent consistency! No streak breaks logged in the last 90 days.',
        style: pw.TextStyle(
          font: fonts['italic'],
          fontSize: 8,
          color: _C.textLight,
        ),
      );
    }

    final displayBreaks = breaks.take(4).toList();
    final headerStyle = pw.TextStyle(
      font: fonts['bold'],
      fontSize: 7,
      color: _C.white,
    );
    final cellStyle = pw.TextStyle(
      font: fonts['regular'],
      fontSize: 7,
      color: _C.textDark,
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Table(
          border: const pw.TableBorder(
            horizontalInside: pw.BorderSide(
              width: 0.5,
              color: PdfColor.fromInt(0xFFE2E8F0),
            ),
            bottom: pw.BorderSide(
              width: 1,
              color: PdfColor.fromInt(0xFFCBD5E1),
            ),
          ),
          columnWidths: {
            0: const pw.FlexColumnWidth(1.2), // Break Date
            1: const pw.FlexColumnWidth(1.0), // Status
            2: const pw.FlexColumnWidth(2.5), // Reason/Context
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: _C.navy),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text('Date of Break', style: headerStyle),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text('Status Lost', style: headerStyle),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                    'Break Cause / Recovery Plan',
                    style: headerStyle,
                  ),
                ),
              ],
            ),
            ...displayBreaks.asMap().entries.map((e) {
              final idx = e.key;
              final brk = e.value;
              final rowColor = idx % 2 == 0
                  ? _C.white
                  : PdfColor.fromInt(0xFFF8FAFC);

              return pw.TableRow(
                decoration: pw.BoxDecoration(color: rowColor),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      '${brk.date.day}/${brk.date.month}',
                      style: cellStyle,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text('Active Streak', style: cellStyle),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      brk.reason.replaceAll('_', ' ').toUpperCase(),
                      style: cellStyle,
                    ),
                  ),
                ],
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  // ── Graceful Error Page Fallback ────────────────────────────────
  static pw.Page _buildErrorPage({
    required pw.ThemeData theme,
    required Map<String, pw.Font> fonts,
    required String pageTitle,
    required Object error,
  }) {
    return pw.Page(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        margin: const pw.EdgeInsets.all(40),
        buildBackground: (ctx) => pw.Container(color: _C.page),
      ),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'TIME CHART',
            style: pw.TextStyle(
              font: fonts['bold'],
              fontSize: 10,
              color: _C.textLight,
              letterSpacing: 2,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Error Rendering $pageTitle',
            style: pw.TextStyle(
              font: fonts['bold'],
              fontSize: 20,
              color: _C.red,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Divider(height: 1, thickness: 0.5, color: _C.textLight),
          pw.SizedBox(height: 20),
          pw.Text(
            'We apologize, but an unexpected error occurred while rendering this page of your performance report.',
            style: pw.TextStyle(
              font: fonts['regular'],
              fontSize: 10,
              color: _C.textDark,
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: _C.red.shade(0.08),
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: _C.red.shade(0.3)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'TECHNICAL ERROR DETAIL:',
                  style: pw.TextStyle(
                    font: fonts['bold'],
                    fontSize: 7,
                    color: _C.red,
                    letterSpacing: 1,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  error.toString(),
                  style: pw.TextStyle(
                    font: fonts['regular'],
                    fontSize: 8,
                    color: _C.textDark,
                  ),
                ),
              ],
            ),
          ),
          pw.Spacer(),
          pw.Divider(height: 1, thickness: 0.5, color: _C.textLight),
          pw.SizedBox(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Time Chart - Performance Report Error',
                style: pw.TextStyle(
                  font: fonts['regular'],
                  fontSize: 7,
                  color: _C.textLight,
                ),
              ),
              pw.Text(
                'Confidential',
                style: pw.TextStyle(
                  font: fonts['italic'],
                  fontSize: 7,
                  color: _C.textLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Centered dotted decorative separator ───────────────────────
  static pw.Widget _decorativeDots(Map<String, pw.Font> fonts) {
    return pw.Center(
      child: pw.Text(
        '· · · · · · · · · · · · · · ·',
        style: pw.TextStyle(font: fonts['bold'], fontSize: 14, color: _C.gold),
      ),
    );
  }

  // ── Helper to format signupDate into Est. Month Year ──────────
  static String _formattedSignupDate(DateTime? dt) {
    if (dt == null) return '';
    return 'Est. ${_monthName(dt.month)} ${dt.year}';
  }

  // ── Page footer ───────────────────────────────────────────────

  static pw.Widget _pageFooter({
    required Map<String, pw.Font> fonts,
    required String userName,
    required int page,
    int total = 7,
  }) => pw.Column(
    children: [
      pw.Divider(height: 1, thickness: 0.5, color: _C.textLight),
      pw.SizedBox(height: 6),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Time Chart - Performance Report',
            style: pw.TextStyle(
              font: fonts['regular'],
              fontSize: 7,
              color: _C.textLight,
            ),
          ),
          pw.Text(
            'Page $page of $total',
            style: pw.TextStyle(
              font: fonts['regular'],
              fontSize: 7,
              color: _C.textLight,
            ),
          ),
          pw.Text(
            'Confidential - Generated for $userName',
            style: pw.TextStyle(
              font: fonts['italic'],
              fontSize: 7,
              color: _C.textLight,
            ),
          ),
        ],
      ),
    ],
  );

  // ================================================================
  // FONT LOADING
  // Uses GoogleFonts via the printing package — no local assets needed
  // ================================================================

  static Future<Map<String, pw.Font>> _loadFonts() async {
    try {
      final regular = await PdfGoogleFonts.nunitoSansRegular();
      final bold = await PdfGoogleFonts.nunitoSansBold();
      final italic = await PdfGoogleFonts.nunitoSansItalic();
      final boldItalic = await PdfGoogleFonts.nunitoSansBoldItalic();
      return {
        'regular': regular,
        'bold': bold,
        'italic': italic,
        'boldItalic': boldItalic,
      };
    } catch (_) {
      // Fallback to built-in helvetica if Google Fonts unavailable
      final f = pw.Font.helvetica();
      return {
        'regular': f,
        'bold': pw.Font.helveticaBold(),
        'italic': pw.Font.helveticaOblique(),
        'boldItalic': pw.Font.helveticaBoldOblique(),
      };
    }
  }

  // ================================================================
  // UTILITY HELPERS
  // ================================================================

  // Format large numbers with commas
  static String _fmt(num value) {
    final v = value.toInt();
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return '$v';
  }

  static String _monthName(int m) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[m - 1];
  }

  // Map mood value (1-10) to PDF colour
  static PdfColor _moodColor(double v) {
    if (v >= 8) return PdfColor.fromInt(0xFF2196F3);
    if (v >= 6) return PdfColor.fromInt(0xFF4CAF50);
    if (v >= 4) return PdfColor.fromInt(0xFFFFC107);
    if (v >= 2) return PdfColor.fromInt(0xFFFF7043);
    return PdfColor.fromInt(0xFFF44336);
  }

  // Parse AI response into titled sections
  static List<_MindsetSection> _parseMindsetSections(String text) {
    final lines = text.split('\n');
    final sections = <_MindsetSection>[];
    String currentTitle = '';
    final bodyLines = <String>[];

    for (final line in lines) {
      if (line.startsWith('## ')) {
        if (bodyLines.isNotEmpty) {
          sections.add(
            _MindsetSection(
              title: currentTitle,
              body: bodyLines.join(' ').trim(),
            ),
          );
          bodyLines.clear();
        }
        currentTitle = line.replaceFirst('## ', '').trim();
      } else if (line.trim().isNotEmpty) {
        bodyLines.add(line.trim());
      }
    }
    if (bodyLines.isNotEmpty) {
      sections.add(
        _MindsetSection(title: currentTitle, body: bodyLines.join(' ').trim()),
      );
    }

    return sections.isEmpty
        ? [_MindsetSection(title: '', body: text.trim())]
        : sections;
  }
}

// ================================================================
// PRIVATE DATA CLASSES
// ================================================================

class _BarItem {
  final String label;
  final int value;
  final PdfColor color;
  _BarItem(this.label, this.value, this.color);
}

class _StatRow {
  final String label;
  final String value;
  _StatRow(this.label, this.value);
}

class _CalDay {
  final DateTime date;
  final bool active;
  _CalDay(this.date, this.active);
}

class _TierItem {
  final String name;
  final int count;
  final PdfColor color;
  _TierItem(this.name, this.count, this.color);
}

class _MoodLevel {
  final int rating;
  final String label;
  final PdfColor color;
  _MoodLevel(this.rating, this.label, this.color);
}

class _MindsetSection {
  final String title;
  final String body;
  _MindsetSection({required this.title, required this.body});
}

// ================================================================
// FLUTTER Color → PdfColor EXTENSION
// ================================================================

extension _FlutterColorToPdf on Color {
  PdfColor toPdf() => PdfColor.fromInt(value);
}

extension _PdfColorShade on PdfColor {
  PdfColor shade(double opacity) => PdfColor(red, green, blue, opacity);
}

class _RadialWatermarkPainter {
  final PdfColor color;
  _RadialWatermarkPainter({required this.color});

  void call(PdfGraphics canvas, PdfPoint size) {
    final double centerX = size.x / 2;
    final double centerY = size.y / 2;
    canvas.setStrokeColor(color);
    canvas.setLineWidth(0.5);

    // Draw concentric decorative circles centered on the page
    for (double r = 40.0; r <= 320.0; r += 40.0) {
      canvas.drawEllipse(centerX, centerY, r, r);
      canvas.strokePath();
    }
  }
}
