import 'package:flutter/material.dart';

class AppColors {
  // Host (Player A) - Pink Theme
  static const Color hostPrimary = Color(0xFFBD0558);
  static const Color hostSecondary = Color(0xFFFF0077);
  static const Color hostDark = Color(0xFF610C39);
  static const Color hostBackground = Color(0xFF0C0219); // bg-main-a
  static const Color hostTextPrimary = Color(0xFFFF0077);
  static const Color hostTextSecondary = Color(0xFFFFF4F6);

  // Guest (Player B) - Purple Theme
  static const Color guestPrimary = Color(0xFF430887);
  static const Color guestSecondary = Color(0xFF6B14EC);
  static const Color guestDark = Color(0xFF2E0645);
  static const Color guestBackground = Color(0xFF0C0219); // bg-main-b
  static const Color guestTextPrimary = Color(0xFF6B14EC);
  static const Color guestTextSecondary = Color(0xFFFDF9FF);

  // Player Background Tints (Distinctive)
  // Player Background Tints (Distinctive)
  static const Color playerA = Color(0xFFF4E7E8); // Pinkish tint for Host (Spec: #F4E7E8)
  static const Color playerB = Color(0xFFF0E7F4); // Purpleish tint for Guest (Spec: #F0E7F4)

  // Shared
  static const Color bgLight = Color(0xFFFFF9FB);
  static const Color bgDark = Color(0xFF0C0219);
  static const Color inputBackground = Color(0xFFF5F5F5); // Engraved Input BG
  
  static const Color emphasizeWarning = Color(0xFFFF0000);
  static const Color explanation = Color(0xFF68CDFF);
  
  static const Color textDark = Color(0xFF0C0219);

  // Buttons
  static const Color buttonPrimaryHost = hostPrimary;
  static const Color buttonPrimaryGuest = guestPrimary;
  
  static const Color buttonSecondaryHost = Color(0xFFFFF9FB);
  static const Color buttonSecondaryGuest = Color(0xFFFDF9FF); // With hover outline
  
  static const Color buttonDeactivatedHost = Color(0xFFCDBFC1);
  static const Color buttonDeactivatedGuest = Color(0xFFC7BFCD);
}
