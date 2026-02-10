import 'package:flutter/material.dart';
import 'package:talkbingo_app/widgets/animated_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:talkbingo_app/utils/ad_state.dart';
import 'package:talkbingo_app/models/game_session.dart';
import 'package:talkbingo_app/styles/app_colors.dart';
import 'package:talkbingo_app/screens/home_screen.dart';
import 'package:talkbingo_app/screens/settings_screen.dart';
import 'package:talkbingo_app/services/payment_service.dart';
import 'dart:math'; // For substring safety
import 'package:talkbingo_app/utils/localization.dart';

class PointPurchaseScreen extends StatefulWidget {
  const PointPurchaseScreen({super.key});

  @override
  State<PointPurchaseScreen> createState() => _PointPurchaseScreenState();
}

class _PointPurchaseScreenState extends State<PointPurchaseScreen> with TickerProviderStateMixin {
  final GameSession _session = GameSession();
  PaymentGateway _selectedGateway = PaymentGateway.tossDomestic;
  final PaymentService _paymentService = PaymentService();
  bool _isProcessingPayment = false;

  // GP Badge wobble + spin animation
  late AnimationController _gpBadgeController;
  late Animation<double> _gpBadgeAnimation;

  @override
  void initState() {
    super.initState();
    // Auto-detect Payment Gateway based on Language/Region
    _selectedGateway = PaymentService.getDefaultGateway(_session.language);
    _session.addListener(_onSessionUpdate);

    // Wobble → full spin animation (4s cycle)
    _gpBadgeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );
    // Custom tween: 0→0.6 wobble, 0.6→1.0 full spin
    _gpBadgeAnimation = TweenSequence<double>([
      // Wobble right
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.06), weight: 8),
      // Wobble left
      TweenSequenceItem(tween: Tween(begin: 0.06, end: -0.06), weight: 10),
      // Wobble right small
      TweenSequenceItem(tween: Tween(begin: -0.06, end: 0.04), weight: 8),
      // Wobble left small
      TweenSequenceItem(tween: Tween(begin: 0.04, end: -0.03), weight: 6),
      // Settle
      TweenSequenceItem(tween: Tween(begin: -0.03, end: 0.0), weight: 8),
      // Pause
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 20),
      // Full spin (2π radians = 1 full rotation mapped via transform)
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 6.2832), weight: 40),
    ]).animate(CurvedAnimation(
      parent: _gpBadgeController,
      curve: Curves.easeInOut,
    ));
    _gpBadgeController.repeat();
  }

  @override
  void dispose() {
    _gpBadgeController.dispose();
    _session.removeListener(_onSessionUpdate);
    super.dispose();
  }

  void _onSessionUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Enable Ad show
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AdState.showAd.value = true;
    });

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomeScreen()), 
              (route) => false,
            );
          },
          child: SvgPicture.asset(
            'assets/images/logo_vector.svg',
            height: 30,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          // Language Toggle (EN / KO)
          GestureDetector(
            onTap: () {
              final newLang = _session.language == 'en' ? 'ko' : 'en';
              setState(() {
                _session.setLanguage(newLang);
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _session.language.toUpperCase(),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // History
          IconButton(
            icon: const Icon(Icons.history, color: Colors.black),
            onPressed: _showHistory,
            tooltip: AppLocalizations.get('purchase_history'),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Current Points Header
            _buildPointsOverview(),
            const SizedBox(height: 16),

            // 2. Ad Catalog — selectable ad categories
            _buildRewardedAdCatalog(),
            const SizedBox(height: 16),

            // 3. Permanent Ad Removal
            if (!_session.permanentAdFree)
              _buildPermanentAdRemoval(),
            if (!_session.permanentAdFree)
              const SizedBox(height: 16),

            // 4. Payment Method Row
            if (_session.paymentCardNumber != null && _session.paymentCardNumber!.isNotEmpty) 
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
              ),
              child: Row(
                children: [
                   Container(
                     padding: const EdgeInsets.all(6),
                     decoration: const BoxDecoration(color: Colors.blueGrey, shape: BoxShape.circle),
                     child: const Icon(Icons.credit_card, color: Colors.white, size: 16),
                   ),
                   const SizedBox(width: 8),
                   Expanded(
                     child: SingleChildScrollView(
                       scrollDirection: Axis.horizontal,
                       child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                               Text(
                                    (_session.paymentHolderName?.isNotEmpty == true && _session.paymentHolderName!.replaceAll(RegExp(r'[^0-9]'), '').length < 6) 
                                      ? _session.paymentHolderName! 
                                      : "My Card", 
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13) 
                               ),
                               const SizedBox(width: 6),
                               Text(
                                  "Visa", 
                                  style: TextStyle(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.bold)
                               ),
                               const SizedBox(width: 6),
                               Text(
                                 "•••• ${_session.paymentCardNumber!.substring(max(0, _session.paymentCardNumber!.length - 4))}",
                                 style: TextStyle(color: Colors.grey[400], fontSize: 12)
                               ),
                               const SizedBox(width: 6),
                               Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(4)),
                                    child: const Text("Active", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                               )
                          ],
                       ),
                     ),
                   ),
                   const SizedBox(width: 8),
                   InkWell(
                     onTap: _showPaymentInputModal,
                     child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                           AppLocalizations.get('purchase_view'),
                           style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)
                        ),
                     ),
                   )
                ],
              ),
            ) else 
             // Add Button if no card
             Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  width: double.infinity,
                  child: AnimatedOutlinedButton(
                      onPressed: _showPaymentInputModal,
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          foregroundColor: AppColors.hostPrimary,
                          side: const BorderSide(color: AppColors.hostPrimary)
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_card),
                          const SizedBox(width: 8),
                          Text(AppLocalizations.get('purchase_add_payment')),
                        ],
                      ),
                  ),
             ),
             
            // 5. Usage Info — styled card with accent border
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.hostPrimary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.get('purchase_how_to_use'),
                        style: GoogleFonts.alexandria(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildUsageRow(Icons.block, AppLocalizations.get('purchase_ad_remove_1game')),
                  const SizedBox(height: 8),
                  _buildUsageRow(Icons.verified_user, AppLocalizations.get('purchase_ad_remove_permanent')),
                  const SizedBox(height: 8),
                  _buildUsageRow(Icons.play_circle_outline, AppLocalizations.get('purchase_watch_ad_earn')),
                  const SizedBox(height: 16),
                  // Free tip
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.hostPrimary.withOpacity(0.08), AppColors.hostSecondary.withOpacity(0.08)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      AppLocalizations.get('purchase_free_tip'),
                      style: AppLocalizations.getTextStyle(
                        baseStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.hostPrimary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Bottom safe area for Ad Banner
            const SizedBox(height: 80), 
          ],
        ),
      ),
    );
  }

  Widget _buildUsageRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppLocalizations.getTextStyle(
              baseStyle: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ),
        ),
      ],
    );
  }



  // ── GP Tier Definitions ──
  Map<String, dynamic> _getGpTier(int gp) {
    if (gp >= 8000) {
      return {'key': 'tier_queen_royal', 'icon': Icons.auto_awesome, 'color': const Color(0xFFE040FB), 'bg': const Color(0xFFFCE4EC)};
    } else if (gp >= 4000) {
      return {'key': 'tier_king_royal', 'icon': Icons.auto_awesome, 'color': const Color(0xFFFF6F00), 'bg': const Color(0xFFFFF3E0)};
    } else if (gp >= 1500) {
      return {'key': 'tier_platinum', 'icon': Icons.diamond_outlined, 'color': const Color(0xFF00BCD4), 'bg': const Color(0xFFE0F7FA)};
    } else if (gp >= 500) {
      return {'key': 'tier_gold', 'icon': Icons.workspace_premium, 'color': const Color(0xFFFFB300), 'bg': const Color(0xFFFFF8E1)};
    } else if (gp >= 100) {
      return {'key': 'tier_silver', 'icon': Icons.workspace_premium, 'color': const Color(0xFF90A4AE), 'bg': const Color(0xFFECEFF1)};
    } else {
      return {'key': 'tier_bronze', 'icon': Icons.workspace_premium, 'color': const Color(0xFF8D6E63), 'bg': const Color(0xFFEFEBE9)};
    }
  }

  Widget _buildPointsOverview() {
    final tier = _getGpTier(_session.gp);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(color: Colors.grey.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // GP — Crown Tier Display (no outer circle, large badge with wobble+spin)
          Column(
            children: [
              AnimatedBuilder(
                animation: _gpBadgeAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _gpBadgeAnimation.value,
                    child: child,
                  );
                },
                child: Icon(
                  tier['icon'] as IconData,
                  color: tier['color'] as Color,
                  size: 56,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _session.gp.toString(),
                style: GoogleFonts.alexandria(fontSize: 15, fontWeight: FontWeight.bold, color: tier['color'] as Color),
              ),
              const SizedBox(height: 2),
              Text(
                AppLocalizations.get(tier['key'] as String),
                style: GoogleFonts.alexandria(fontSize: 12, fontWeight: FontWeight.w600, color: (tier['color'] as Color).withValues(alpha: 0.7)),
              ),
            ],
          ),
          Container(width: 1, height: 80, color: Colors.grey[200]),
          // VP — Purchase Display
          _buildVpItem(),
        ],
      ),
    );
  }

  Widget _buildVpItem() {
    return GestureDetector(
      onTap: _openPurchasePopup,
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.hostPrimary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.hostPrimary.withValues(alpha: 0.3), width: 2),
            ),
            child: Center(
              child: TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: _session.vp),
                duration: const Duration(seconds: 2),
                builder: (context, value, child) {
                  return Text(
                    value.toString(),
                    style: GoogleFonts.alexandria(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.hostPrimary),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("VP", style: GoogleFonts.alexandria(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.hostPrimary)),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(color: AppColors.hostPrimary, shape: BoxShape.circle),
                child: const Icon(Icons.add, color: Colors.white, size: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Ad Catalog — selectable ad categories ──
  Widget _buildRewardedAdCatalog() {
    final remaining = _session.remainingRewardedAds;
    final isAvailable = remaining > 0;
    final progress = (10 - remaining) / 10;

    final adCategories = [
      {'icon': Icons.sports_esports, 'key': 'ad_cat_gaming', 'color': const Color(0xFF4CAF50)},
      {'icon': Icons.shopping_bag, 'key': 'ad_cat_shopping', 'color': const Color(0xFFFF9800)},
      {'icon': Icons.restaurant, 'key': 'ad_cat_food', 'color': const Color(0xFFE91E63)},
      {'icon': Icons.phone_iphone, 'key': 'ad_cat_apps', 'color': const Color(0xFF2196F3)},
      {'icon': Icons.flight, 'key': 'ad_cat_travel', 'color': const Color(0xFF9C27B0)},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(color: Colors.grey.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.movie_creation_outlined, color: Color(0xFF4CAF50), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.get('ad_catalog_title'),
                      style: GoogleFonts.alexandria(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppLocalizations.get('ad_catalog_subtitle'),
                      style: GoogleFonts.alexandria(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[200],
                    color: isAvailable ? const Color(0xFF4CAF50) : Colors.grey,
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "$remaining/10",
                style: GoogleFonts.alexandria(fontSize: 12, fontWeight: FontWeight.bold, color: isAvailable ? const Color(0xFF4CAF50) : Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Ad Category List
          ...adCategories.map((cat) => _buildAdCategoryItem(
            icon: cat['icon'] as IconData,
            labelKey: cat['key'] as String,
            accentColor: cat['color'] as Color,
            isAvailable: isAvailable,
            onTap: isAvailable ? _watchRewardedAd : null,
          )),
        ],
      ),
    );
  }

  Widget _buildAdCategoryItem({
    required IconData icon,
    required String labelKey,
    required Color accentColor,
    required bool isAvailable,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isAvailable ? accentColor.withValues(alpha: 0.06) : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isAvailable ? accentColor.withValues(alpha: 0.15) : Colors.grey[300]!,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: isAvailable ? accentColor : Colors.grey, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppLocalizations.get(labelKey),
                  style: GoogleFonts.alexandria(fontSize: 14, fontWeight: FontWeight.w600, color: isAvailable ? Colors.black87 : Colors.grey),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isAvailable ? accentColor.withValues(alpha: 0.12) : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "+5 VP",
                  style: GoogleFonts.alexandria(fontSize: 11, fontWeight: FontWeight.bold, color: isAvailable ? accentColor : Colors.grey),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isAvailable ? accentColor : Colors.grey[300],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  isAvailable ? AppLocalizations.get('rewarded_ad_watch') : AppLocalizations.get('rewarded_ad_done'),
                  style: GoogleFonts.alexandria(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String desc, {VoidCallback? onExchange}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text(desc, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      )
    );
  }

  void _showHistory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          height: 500,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Point History", style: GoogleFonts.alexandria(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              
              // Column Headers
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    SizedBox(width: 80, child: Text("Date", style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.bold))),
                    Expanded(child: Center(child: Text("Point", style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.bold)))),
                    SizedBox(width: 80, child: Align(alignment: Alignment.centerRight, child: Text("Detail", style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.bold)))),
                  ],
                ),
              ),
              const Divider(height: 1),

              Expanded(
                child: _session.pointHistory.isEmpty 
                  ? Center(child: Text("No history yet.", style: TextStyle(color: Colors.grey[400])))
                  : ListView.separated(
                      padding: const EdgeInsets.only(top: 12),
                      itemCount: _session.pointHistory.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final item = _session.pointHistory[index];
                        final isPositive = (item['amount'] as int) > 0;
                        final type = item['type'];
                        
                        return Row(
                          children: [
                            // Date
                            SizedBox(
                              width: 80, 
                              child: Text(
                                item['date'] ?? '', 
                                style: const TextStyle(fontSize: 12, color: Colors.black87)
                              )
                            ),
                            
                            // Point (+/-)
                            Expanded(
                              child: Center(
                                child: Text(
                                  "${isPositive ? '+' : ''}${item['amount']} ${type == 'use' ? 'VP' : 'VP'}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: isPositive ? AppColors.hostPrimary : Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                            
                            // Amount or Room Name
                            SizedBox( // Fixed width for alignment
                              width: 100,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  isPositive 
                                    ? (item['price'] ?? '') 
                                    : (item['roomName'] ?? ''),
                                  style: TextStyle(
                                    fontSize: 12, 
                                    fontWeight: isPositive ? FontWeight.bold : FontWeight.normal,
                                    color: isPositive ? Colors.black : Colors.grey[600]
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                          ],
                        );
                      },
                    ),
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildPurchaseOption(String title, String price, VoidCallback onTap) {
    // Helper to format price with smaller decimals
    Widget buildRichPrice(String priceStr) {
      // Split "$4.75" into "$4" and ".75"
      final parts = priceStr.split('.');
      final integerPart = parts[0];
      final decimalPart = parts.length > 1 ? ".${parts[1]}" : "";

      return RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          children: [
            TextSpan(text: integerPart, style: const TextStyle(fontSize: 14)), // Base size
            if (decimalPart.isNotEmpty)
              TextSpan(text: decimalPart, style: const TextStyle(fontSize: 9)), // ~60% of base (40% smaller)
          ],
        ),
      );
    }
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.hostPrimary.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber),
                const SizedBox(width: 12),
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
            Container(
              // Fixed width for alignment
              width: 80, 
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.hostPrimary,
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: buildRichPrice(price),
            ),
          ],
        ),
      ),
    );
  }
  
  void _handlePurchase(int points) {
    if (!kIsWeb) {
      _initiateIAP(points);
      return;
    }
    // Find matching VP package
    final pkg = vpPackages.firstWhere(
      (p) => p.totalVp == points || p.vp == points,
      orElse: () => vpPackages.first,
    );
    _initiateTossPayment(pkg);
  }

  Future<void> _initiateTossPayment(VPPackage pkg) async {
    if (_isProcessingPayment) return;
    setState(() => _isProcessingPayment = true);

    try {
      final request = PaymentRequest(
        package: pkg,
        gateway: _selectedGateway,
      );

      // Step 1: Create payment session via Edge Function
      final paymentInfo = await _paymentService.createPayment(request);

      if (!mounted) return;

      // Step 2: For now (no Toss SDK key), simulate payment success
      // When Toss keys are ready, replace this with TossPaymentService.requestPayment()
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF222222),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            _selectedGateway == PaymentGateway.tossDomestic ? '결제 확인' : 'Confirm Payment',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${pkg.labelKo}', style: const TextStyle(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 8),
              Text(
                '${paymentInfo.orderName} — ${pkg.displayPrice(request.currency)}',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.amber, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _session.language == 'ko'
                            ? '토스 API 키 설정 후 실결제가 연동됩니다.\n현재는 테스트 모드입니다.'
                            : 'Payment will be live after Toss API key setup.\nCurrently in test mode.',
                        style: const TextStyle(color: Colors.amber, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                _session.language == 'ko' ? '취소' : 'Cancel',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.hostPrimary,
                foregroundColor: Colors.white,
              ),
              child: Text(_session.language == 'ko' ? '결제하기' : 'Pay Now'),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted) return;

      // Step 3: Verify payment (dev mode auto-confirms)
      final result = await _paymentService.verifyPayment(
        paymentKey: 'dev_test_${DateTime.now().millisecondsSinceEpoch}',
        orderId: paymentInfo.orderId,
        amount: paymentInfo.amount,
      );

      if (!mounted) return;

      // Step 4: Refresh VP from session and show success
      await _session.refreshVp();
      _finalizePurchaseSuccess(result.vpGranted, pkg.displayPrice(request.currency));

    } on PaymentException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint('Payment error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_session.language == 'ko' ? '결제 중 오류가 발생했습니다.' : 'Payment error occurred.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessingPayment = false);
    }
  }

  void _initiateIAP(int points) {
      // Placeholder for IAP
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF222222),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("In-App Purchase", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Text(
            "Connecting to Store for $points VP purchase...\n(This will trigger Apple/Google IAP in production)", 
            style: const TextStyle(color: Colors.white70)
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Mock Success for Testing
                _finalizePurchaseSuccess(points, "IAP Mock"); 
              },
              child: const Text("Test Success", style: TextStyle(color: Colors.greenAccent)),
            ),
             TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      );
  }

  // _initiatePortOnePayment removed — replaced by _initiateTossPayment above

  void _finalizePurchaseSuccess(int vpGranted, String priceLabel) {
    _session.addHistory("earn", vpGranted, "Purchased Points", price: priceLabel);
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            _session.language == 'ko' ? '결제 완료' : 'Success',
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          content: Text(
            _session.language == 'ko'
                ? '$vpGranted VP가 충전되었습니다!'
                : 'Successfully purchased $vpGranted VP!',
            style: const TextStyle(color: Colors.black87),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.hostPrimary,
                foregroundColor: Colors.white,
              ),
              child: const Text('OK'),
            )
          ],
        ),
      );
    }
  }

  Future<bool?> _showPaymentInputModal() {
    // 1. App (Mobile) - IAP
    if (!kIsWeb) {
      return showModalBottomSheet<bool>(
        context: context,
        backgroundColor: const Color(0xFF222222),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        builder: (context) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.store_mall_directory, size: 48, color: Colors.white),
              const SizedBox(height: 16),
              Text(
                "In-App Purchase",
                style: GoogleFonts.alexandria(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(
                "Payments are securely processed by your device's Store (Apple/Google). Please manage your payment methods in your OS settings.",
                style: GoogleFonts.alexandria(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: AnimatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.hostPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text("OK"),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 2. Web - Toss Domestic (Korea)
    if (_selectedGateway == PaymentGateway.tossDomestic) {
      return showModalBottomSheet<bool>(
        context: context,
        backgroundColor: const Color(0xFF222222),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        builder: (context) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.payment, size: 48, color: Colors.white),
              const SizedBox(height: 16),
              Text(
                "PortOne Payment",
                style: GoogleFonts.alexandria(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(
                "You will be redirected to the secure payment gateway (PG). Supported methods: Card, KakaoPay, NaverPay, etc.",
                style: GoogleFonts.alexandria(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.hostPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text("Understood"),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 3. Web - Global (Stripe) [Manual Input]
    final cardController = TextEditingController();
    final expiryController = TextEditingController();
    final cvvController = TextEditingController();
    final holderController = TextEditingController();

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF222222),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 24, 
          right: 24, 
          top: 24
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Add Global Card (Stripe)", style: GoogleFonts.alexandria(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 24),
            
            // Card Number
            TextField(
              controller: cardController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Card Number",
                labelStyle: const TextStyle(color: Colors.white70),
                border: const OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[700]!)),
                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.hostPrimary)),
                prefixIcon: const Icon(Icons.credit_card, color: Colors.white70),
                isDense: true,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                 FilteringTextInputFormatter.digitsOnly,
                 LengthLimitingTextInputFormatter(16),
                 _CardNumberFormatter(),
              ],
            ),
            const SizedBox(height: 12),
            
            // Expiry & CVV
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: expiryController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Expiry (MM/YY)",
                      labelStyle: const TextStyle(color: Colors.white70),
                      border: const OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[700]!)),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.hostPrimary)),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                      _ExpiryDateFormatter(),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: cvvController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "CVV",
                      labelStyle: const TextStyle(color: Colors.white70),
                      border: const OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[700]!)),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.hostPrimary)),
                      isDense: true,
                    ),
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Holder Name
            TextField(
              controller: holderController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Cardholder Name",
                labelStyle: const TextStyle(color: Colors.white70),
                border: const OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[700]!)),
                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.hostPrimary)),
                isDense: true,
              ),
            ),
            const SizedBox(height: 24),
            
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (cardController.text.length < 16) {
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid Card Number")));
                         return;
                      }
                      
                      await _session.savePaymentInfo(
                        holderController.text,
                        cardController.text,
                        expiryController.text,
                        cvvController.text,
                      );
                      
                      if (context.mounted) Navigator.pop(context, true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.hostPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text("Save & Continue"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // _mockPurchase removed — replaced by _initiateTossPayment

  void _openPurchasePopup() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      isScrollControlled: true, // Allow full height if needed
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
             return SingleChildScrollView(
               controller: scrollController,
               padding: const EdgeInsets.all(16),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.stretch,
                 children: [
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Text("Purchase VP", style: GoogleFonts.alexandria(fontSize: 18, fontWeight: FontWeight.bold)),
                       IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                     ],
                   ),
                   const SizedBox(height: 16),
                   _buildPurchaseList(fromBottomSheet: true), // Pass true here
                   const SizedBox(height: 32),
                 ],
               ),
             );
          }
        );
      },
    );
  }

  // Update signature to accept fromBottomSheet
  Widget _buildPurchaseList({bool fromBottomSheet = false}) {
    final currency = _selectedGateway == PaymentGateway.tossDomestic ? 'KRW' : 'USD';

    return Column(
      children: vpPackages.map((pkg) {
         final bonusLabel = pkg.bonusVp > 0
             ? (pkg.isBestValue ? '⭐ Best Value' : '+${pkg.bonusVp} Bonus')
             : '';
         final price = pkg.displayPrice(currency);
         
         final title = bonusLabel.isNotEmpty 
             ? "${pkg.totalVp} VP  $bonusLabel"
             : "${pkg.totalVp} VP";
         
         return Column(
           children: [
             _buildPurchaseOption(title, price, () { 
               if(fromBottomSheet) Navigator.pop(context); 
               _handlePurchase(pkg.totalVp); 
             }),
             const SizedBox(height: 12),
           ],
         );
      }).toList(),
    );
  }


  void _watchRewardedAd() {
    AdState.loadRewardedAd();
    // Show a brief loading indicator, then show ad
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF222222),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(width: 16),
            Text("Loading Ad...", style: GoogleFonts.alexandria(color: Colors.white)),
          ],
        ),
      ),
    );

    // Delay to allow ad to load, then show
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog
      
      AdState.showRewardedAd(
        onRewarded: () {
          final success = _session.rewardVpFromAd();
          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("+5 VP earned! (${_session.remainingRewardedAds}/10 remaining)"),
                backgroundColor: const Color(0xFF4CAF50),
                duration: const Duration(seconds: 2),
              ),
            );
          } else if (!success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Daily limit reached (10/10)"),
                backgroundColor: Colors.orange,
              ),
            );
          }
        },
        onDismissed: () {
          if (mounted) setState(() {});
        },
      );
    });
  }

  // ── Permanent Ad Removal ──
  Widget _buildPermanentAdRemoval() {
    final hasEnough = _session.vp >= 8000;
    const purple = Color(0xFF7C4DFF);
    
    return InkWell(
      onTap: hasEnough ? _confirmPermanentAdRemoval : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasEnough ? const Color(0xFFF3E5F5) : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasEnough ? purple.withValues(alpha: 0.25) : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: hasEnough ? purple.withValues(alpha: 0.12) : Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.shield_outlined, color: hasEnough ? purple : Colors.grey, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.get('permanent_ad_removal'),
                    style: GoogleFonts.alexandria(
                      fontSize: 14, fontWeight: FontWeight.bold,
                      color: hasEnough ? Colors.black87 : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppLocalizations.get('permanent_ad_removal_desc'),
                    style: GoogleFonts.alexandria(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: hasEnough ? purple : Colors.grey[300],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                AppLocalizations.get('permanent_ad_removal_cost'),
                style: GoogleFonts.alexandria(
                  fontWeight: FontWeight.bold, fontSize: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmPermanentAdRemoval() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Remove Ads Permanently?",
          style: GoogleFonts.alexandria(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "This will use 8,000 VP to permanently remove all ads from TalkBingo.",
              style: GoogleFonts.alexandria(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Text(
              "Current VP: ${_session.vp}",
              style: GoogleFonts.alexandria(
                fontWeight: FontWeight.bold, fontSize: 16,
                color: const Color(0xFFE91E63),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: GoogleFonts.alexandria(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final success = _session.useVpForPermanentAdRemoval();
              Navigator.pop(ctx);
              if (success && mounted) {
                AdState.showAd.value = false;
                showDialog(
                  context: context,
                  builder: (ctx2) => AlertDialog(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: const Text("🎉"),
                    content: Text(
                      "Ads removed permanently!\nEnjoy ad-free TalkBingo!",
                      style: GoogleFonts.alexandria(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx2),
                        child: Text("OK", style: GoogleFonts.alexandria(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE91E63),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text("Confirm", style: GoogleFonts.alexandria(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text;
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }
    
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != text.length) {
        buffer.write(' ');
      }
    }
    
    var string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length)
    );
  }
}

class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text;
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }
    
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
        buffer.write(text[i]);
        var nonZeroIndex = i + 1;
        if (nonZeroIndex % 2 == 0 && nonZeroIndex != text.length) {
            buffer.write('/');
        }
    }
    
    var string = buffer.toString();
    return newValue.copyWith(
        text: string,
        selection: TextSelection.collapsed(offset: string.length)
    );
  }
}
