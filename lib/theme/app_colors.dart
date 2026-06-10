import 'package:flutter/material.dart';

/// Centralized color palette for LVLRISE app
class AppColors {
  AppColors._();

  // ── Backgrounds ──────────────────────────────────────
  static const Color background = Color(0xFF090A12);
  static const Color surface = Color(0xFF11131B);
  static const Color surfaceVariant = Color(0xFF1B1C2D);
  static const Color surfaceDark = Color(0xFF0B0D18);
  static const Color surfaceDeep = Color(0xFF1D1A2F);
  static const Color cardDark = Color(0xFF130F26);
  static const Color cardDeep = Color(0xFF120F22);
  static const Color chipDark = Color(0xFF15152A);
  static const Color gradientStart = Color(0xFF322A5A);

  // ── Primary / Purple ─────────────────────────────────
  static const Color primary = Color(0xFF7D60FF);
  static const Color primaryLight = Color(0xFF9A80FF);
  static const Color primaryMedium = Color(0xFF6D58FF);
  static const Color primarySubtle = Color(0xFF7C80FF);
  static const Color primaryBorder = Color(0xFF4A49B6);
  static const Color primaryOutline = Color(0xFF5A5CC5);
  static const Color primaryDark = Color(0xFF2A2344);
  static const Color primaryGlow = Color(0xFF5C58F5);

  // ── Secondary / Cyan ─────────────────────────────────
  static const Color secondary = Color(0xFF30E7FF);
  static const Color secondaryLight = Color(0xFF51D9FF);
  static const Color secondaryBright = Color(0xFF2CE0FF);
  static const Color secondarySoft = Color(0xFFBBE8FF);
  static const Color secondaryDeep = Color(0xFF6E8CFF);

  // ── Accent / Shield ──────────────────────────────────
  static const Color accentShield = Color(0xFF6F8DFF);

  // ── Grid / Login variants ─────────────────────────────
  static const Color gridLine = Color(0x1A4E8B);
  static const Color loginOverlayDark = Color(0xCC0A1A2E);
  static const Color loginCardGlass = Color(0x14FFFFFF);
  static const Color loginCardStroke = Color(0x33FFFFFF);

  // ── Text ─────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textMuted = Color(0xFF8A8A8A);
  static const Color textFaint = Color(0xFF1F1F1F);

  // ── Shadows / Glows ──────────────────────────────────
  static Color primaryGlowShadow = primary.withValues(alpha: 0.32);
  static Color primaryGlowSoft = primary.withValues(alpha: 0.12);
  static Color secondaryGlow = secondary.withValues(alpha: 0.14);
}
