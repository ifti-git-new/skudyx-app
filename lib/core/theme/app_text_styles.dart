import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract class AppTextStyles {
  // Headings
  static TextStyle get h1 => GoogleFonts.inter(
    fontSize: 34,
    fontWeight: FontWeight.w900,
    height: 1.10,
    color: AppColors.text,
  );

  static TextStyle get h1light => GoogleFonts.inter(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    height: 1.10,
    color: AppColors.text,
  );

  static TextStyle get h2 => GoogleFonts.inter(
    fontSize: 26,
    fontWeight: FontWeight.w900,
    height: 1.20,
    color: AppColors.text,
  );

  static TextStyle get h2light => GoogleFonts.inter(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    height: 1.20,
    color: AppColors.text,
  );

  static TextStyle get title => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w900,
    color: AppColors.text,
  );

  static TextStyle get textfont => GoogleFonts.inter(
    fontSize: 12,
    // fontWeight: FontWeight.w900,
    color: AppColors.text,
  );

  static TextStyle get textfont16 =>
      GoogleFonts.inter(fontSize: 16, color: AppColors.text);

  // Body
  static TextStyle get subtitle => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.35,
    color: AppColors.muted,
  );

  static TextStyle get body => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.35,
    color: AppColors.text,
  );

  static TextStyle get caption => GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.muted,
  );

  // Buttons / Links
  static TextStyle get button => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    color: Colors.white,
  );

  static TextStyle get link => GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w800,
    color: AppColors.primary,
    decoration: TextDecoration.underline,
  );
}
