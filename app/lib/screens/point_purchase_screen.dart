import 'package:flutter/material.dart';
import 'package:talkbingo_app/widgets/animated_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iamport_flutter/iamport_payment.dart';
import 'package:iamport_flutter/model/payment_data.dart';
import 'package:talkbingo_app/utils/ad_state.dart';
import 'package:talkbingo_app/models/game_session.dart';
import 'package:talkbingo_app/styles/app_colors.dart';
import 'package:talkbingo_app/screens/home_screen.dart';
import 'package:talkbingo_app/screens/settings_screen.dart';
import 'dart:math'; // For substring safety

class PointPurchaseScreen extends StatefulWidget {
  const PointPurchaseScreen({super.key});

  @override
  State<PointPurchaseScreen> createState() => _PointPurchaseScreenState();
}

class _PointPurchaseScreenState extends State<PointPurchaseScreen> {
  final GameSession _session = GameSession();
  String _selectedGateway = 'portone'; // 'portone' (Korea) | 'stripe' (Global)

  @override
  void initState() {
    super.initState();
    // Auto-detect Payment Gateway based on Language/Region
    // "Device Payment Info" -> System Language/Region
    if (_session.language == 'ko') {
      _selectedGateway = 'portone'; // Korea Card
    } else {
      _selectedGateway = 'stripe'; // Global Card
    }
    _session.addListener(_onSessionUpdate);
  }

  @override
  void dispose() {
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
            'assets/images/Logo Vector.svg',
            height: 30,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0, // Prevent scroll tint
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.black),
            onPressed: _showHistory,
          )
        ],
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Current Points Header
            _buildPointsOverview(),
            const SizedBox(height: 24),

            // 2. Explanation
            // 2. Explanation Removed (Redundant with Top Bar)
            
            const SizedBox(height: 12),


            // 2.5 Payment Method Row
            if (_session.paymentCardNumber != null && _session.paymentCardNumber!.isNotEmpty) 
            Container(
              margin: const EdgeInsets.only(bottom: 24),
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
                     padding: const EdgeInsets.all(6), // Reduced padding
                     decoration: const BoxDecoration(color: Colors.blueGrey, shape: BoxShape.circle),
                     child: const Icon(Icons.credit_card, color: Colors.white, size: 16), // Reduced size
                   ),
                   const SizedBox(width: 8),
                   Expanded(
                     child: SingleChildScrollView( // Allow scrolling if still too tight, or just truncation
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
                        child: const Text(
                           "View",
                           style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)
                        ),
                     ),
                   )
                ],
              ),
            ) else 
             // Add Button if no card
             Container(
                  margin: const EdgeInsets.only(bottom: 24),
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
                        children: const [
                          Icon(Icons.add_card),
                          SizedBox(width: 8),
                          Text("Add Payment Method"),
                        ],
                      ),
                  ),
             ),


            const SizedBox(height: 24),

            // 3. Purchase Section
            Text(
              "Purchase Points (${_selectedGateway == 'portone' ? 'KRW' : 'USD'})",
              style: GoogleFonts.alexandria(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.hostPrimary),
            ),
            const SizedBox(height: 12),
            _buildPurchaseList(),
             const SizedBox(height: 16),
             
             // 4. Usage Info
             Container(
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: Colors.grey[100],
                 borderRadius: BorderRadius.circular(12),
               ),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text("How to use VP Points?", style: GoogleFonts.alexandria(fontWeight: FontWeight.bold)),
                   const SizedBox(height: 8),
                   Text("- Remove Ads: 200 VP / new game", style: GoogleFonts.alexandria(fontSize: 14)),
                   Text("- Buy Items: Coming Soon", style: GoogleFonts.alexandria(fontSize: 14)),
                 ],
               ),
             ),
             // Extra padding for Ad Banner
             const SizedBox(height: 120), 
          ],
        ),
      ),
    );
  }



  Widget _buildPointsOverview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.hostSecondary, AppColors.hostPrimary]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.hostPrimary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildScoreItem("VP", _session.vp, isVP: true, onTap: _openPurchasePopup),
          Container(width: 1, height: 40, color: Colors.white30),
          _buildScoreItem("AP", _session.ap, onExchange: () {
             if (_session.convertApToVp()) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Exchanged 100 AP to 50 VP!")));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Not enough AP (Need 100)")));
              }
          }, tooltip: "100 AP → 50 VP"),
          Container(width: 1, height: 40, color: Colors.white30),
          _buildScoreItem("EP", _session.ep, onExchange: () {
             if (_session.convertEpToVp()) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Exchanged 100 EP to 50 VP!")));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Not enough EP (Need 100)")));
              }
          }, tooltip: "100 EP → 50 VP"),
        ],
      ),
    );
  }

  Widget _buildScoreItem(String label, int score, {bool isVP = false, VoidCallback? onExchange, VoidCallback? onTap, String? tooltip}) {
    return Column(
      children: [
        // Score with Animation
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: score),
          duration: const Duration(seconds: 2), // Slower animation (2s)
          builder: (context, value, child) {
             final isAnimating = value != score;
             return Text(
               value.toString(), 
               style: GoogleFonts.alexandria(
                 fontSize: 24, 
                 fontWeight: FontWeight.bold, 
                 color: isAnimating ? Colors.greenAccent : Colors.white // Highlight change
               )
             );
          },
        ),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.alexandria(fontSize: 12, color: Colors.white70)),
        
        const SizedBox(height: 8),
        
        // Action Button
        if (isVP)
          InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white24),
              child: const Icon(Icons.add, color: Colors.white, size: 16),
            ),
          )
        else if (onExchange != null)
           Tooltip(
             message: tooltip ?? "",
             triggerMode: TooltipTriggerMode.tap, // Also show on tap for mobile
             child: InkWell(
              onTap: onExchange,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text("Exchange", style: GoogleFonts.alexandria(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.hostPrimary)),
              ),
            ),
           )
      ],
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
                                  "${isPositive ? '+' : ''}${item['amount']} ${type == 'use' ? 'AP' : 'VP'}", // Assuming VP for purchase, adjust if needed
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
      // Mobile - In-App Purchase logic
      // Note: Actual IAP implementation would go here using in_app_purchase package
      _initiateIAP(points);
    } else if (_selectedGateway == 'portone') {
      // 1000 VP = 1400 KRW (approx $1)
      int priceKrw = (points * 1.4).round();
      // Round to nice numbers
      if (points == 1000) priceKrw = 1400;
      if (points == 2000) priceKrw = 2800;
      if (points == 3000) priceKrw = 4200;
      if (points == 5000) priceKrw = 7000;
      if (points == 10000) priceKrw = 14000;
      
      _initiatePortOnePayment(points, priceKrw);
    } else {
      // Stripe (Mock for now)
      double priceUsd = points / 1000.0; // 1000 VP = $1.00
      _mockPurchase(points, "\$${priceUsd.toStringAsFixed(2)}");
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
                _finalizePurchase(points, "IAP Mock"); 
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

  void _initiatePortOnePayment(int points, int amount) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => IamportPayment(
          appBar: AppBar(title: const Text('TalkBingo Payment')),
          initialChild: Container(
            child: const Center(child: Text('Loading Payment...')),
          ),
          userCode: 'imp19424728', // Test Code
          data: PaymentData(
            pg: 'html5_inicis', // KG Inicis
            payMethod: 'card',
            name: '$points VP',
            merchantUid: 'mid_${DateTime.now().millisecondsSinceEpoch}',
            amount: amount,
            buyerName: _session.hostNickname ?? 'Guest',
            buyerTel: _session.hostPhone ?? '010-0000-0000', // Added buyerTel
            appScheme: 'talkbingo',
          ),
          callback: (Map<String, String> result) {
            Navigator.pop(context); // Close Payment Screen
            if (result['imp_success'] == 'true') {
              _finalizePurchase(points, "₩$amount");
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Payment Failed: ${result['error_msg']}"), backgroundColor: Colors.red)
                );
              }
            }
          },
        ),
      ),
    );
  }

  Future<void> _finalizePurchase(int points, String priceLabel) async {
     try {
       await _session.chargePointsSecurely(points);
       _session.addHistory("earn", points, "Purchased Points", price: priceLabel);
       
       if (mounted) {
         showDialog(
           context: context,
           builder: (context) => AlertDialog(
             backgroundColor: Colors.white,
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
             title: const Text("Success", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
             content: Text("Successfully purchased $points VP!", style: const TextStyle(color: Colors.black87)),
             actions: [
               ElevatedButton(
                 onPressed: () => Navigator.pop(context),
                 style: ElevatedButton.styleFrom(
                   backgroundColor: AppColors.hostPrimary,
                   foregroundColor: Colors.white,
                 ),
                 child: const Text("OK"),
               )
             ],
           ),
         );
       }
     } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text("Error saving points: $e"), backgroundColor: Colors.red)
           );
        }
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

    // 2. Web - Korea (PortOne)
    if (_selectedGateway == 'portone') {
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

  void _mockPurchase(int points, String price) async {
    // Keep existing mock logic for Stripe/Fallback
    // ... (Simplified for brevity, or reuse existing logic)
    
    // For now, just direct success for Stripe Mock
     _finalizePurchase(points, price);
  }

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
    // Define packages
    final packages = [
      {'vp': 1000, 'usd': 1.00, 'krw': 1400},
      {'vp': 2000, 'usd': 1.95, 'krw': 2800},
      {'vp': 3000, 'usd': 2.90, 'krw': 4200},
      {'vp': 5000, 'usd': 4.75, 'krw': 7000},
      {'vp': 10000, 'usd': 9.50, 'krw': 14000},
    ];

    return Column(
      children: packages.map((pkg) {
         final vp = pkg['vp'] as int;
         final price = _selectedGateway == 'portone' 
             ? "₩${pkg['krw']}" 
             : "\$${pkg['usd']}";
         
         return Column(
           children: [
             _buildPurchaseOption("$vp VP", price, () { 
               if(fromBottomSheet) Navigator.pop(context); 
               _handlePurchase(vp); 
             }),
             const SizedBox(height: 12),
           ],
         );
      }).toList(),
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
