import 'package:flutter/material.dart';

class RecallColors {
  static const neutral900 = Color(0xFF171717);
  static const neutral700 = Color(0xFF404040);
  static const neutral600 = Color(0xFF525252);
  static const neutral500 = Color(0xFF737373);
  static const neutral400 = Color(0xFFA1A1A1);
  static const neutral300 = Color(0xFFD4D4D4);
  static const neutral200 = Color(0xFFE5E5E5);
  static const neutral100 = Color(0xFFF5F5F5);
  static const neutral050 = Color(0xFFFAFAFA);
  static const white = Colors.white;

  static const linkPurple = Color(0xFF4F39F6);
  static const tagGreenBg = Color(0xFFDCFCE7);
  static const tagGreenText = Color(0xFF008236);
  static const favorite = Color(0xFFFACC15);
  static const shadow = Color(0x1A000000);
}

class RecallShadows {
  static const quickSaveCard = [
    BoxShadow(
      color: RecallColors.shadow,
      blurRadius: 25,
      offset: Offset(0, 20),
    ),
    BoxShadow(color: RecallColors.shadow, blurRadius: 10, offset: Offset(0, 8)),
  ];
}

class RecallTextStyles {
  static const drawerBrand = TextStyle(
    fontSize: 20,
    height: 1.4,
    fontWeight: FontWeight.w700,
    color: RecallColors.neutral900,
  );

  static const drawerSectionHeader = TextStyle(
    fontSize: 12,
    height: 1.33,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.6,
    color: RecallColors.neutral400,
  );

  static const drawerItem = TextStyle(
    fontSize: 14,
    height: 1.43,
    fontWeight: FontWeight.w500,
    color: RecallColors.neutral600,
  );

  static const drawerItemSelected = TextStyle(
    fontSize: 14,
    height: 1.43,
    fontWeight: FontWeight.w500,
    color: RecallColors.neutral900,
  );

  static const drawerCount = TextStyle(
    fontSize: 12,
    height: 1.33,
    fontWeight: FontWeight.w400,
    color: RecallColors.neutral400,
  );

  static const drawerAvatar = TextStyle(
    fontSize: 12,
    height: 1.33,
    fontWeight: FontWeight.w500,
    color: RecallColors.neutral600,
  );

  static const headerTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: RecallColors.neutral900,
  );

  static const headerCount = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: RecallColors.neutral400,
  );

  static const itemTitle = TextStyle(
    fontSize: 16,
    height: 1.4,
    fontWeight: FontWeight.w600,
    color: RecallColors.neutral900,
  );

  static const itemExcerpt = TextStyle(
    fontSize: 14,
    height: 1.43,
    fontWeight: FontWeight.w400,
    color: RecallColors.neutral500,
  );

  static const itemDomain = TextStyle(
    fontSize: 12,
    height: 1.33,
    fontWeight: FontWeight.w500,
    color: RecallColors.neutral500,
  );

  static const itemMeta = TextStyle(
    fontSize: 12,
    height: 1.33,
    fontWeight: FontWeight.w400,
    color: RecallColors.neutral400,
  );

  static const detailTitle = TextStyle(
    fontSize: 24,
    height: 1.25,
    fontWeight: FontWeight.w700,
    color: RecallColors.neutral900,
  );

  static const detailUrl = TextStyle(
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w500,
    color: RecallColors.linkPurple,
  );

  static const detailSectionLabel = TextStyle(
    fontSize: 12,
    height: 1.33,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
    color: RecallColors.neutral400,
  );

  static const detailSectionValue = TextStyle(
    fontSize: 14,
    height: 1.43,
    fontWeight: FontWeight.w400,
    color: RecallColors.neutral700,
  );

  static const detailTag = TextStyle(
    fontSize: 12,
    height: 1.33,
    fontWeight: FontWeight.w500,
  );

  static const detailNotesLabel = TextStyle(
    fontSize: 14,
    height: 1.43,
    fontWeight: FontWeight.w600,
    color: RecallColors.neutral900,
  );

  static const tag = TextStyle(
    fontSize: 12,
    height: 1.33,
    fontWeight: FontWeight.w400,
    color: RecallColors.neutral600,
  );

  static const faviconFallback = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: RecallColors.neutral400,
  );

  static const quickSaveInput = TextStyle(
    fontSize: 14,
    height: 1.43,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.1504,
    color: RecallColors.neutral900,
  );

  static const quickSavePlaceholder = TextStyle(
    fontSize: 14,
    height: 1.43,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.1504,
    color: Color(0x80171717),
  );

  static const quickSaveButton = TextStyle(
    fontSize: 14,
    height: 1.43,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.1504,
  );
}
