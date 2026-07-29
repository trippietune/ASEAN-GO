import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../data/coins_repository.dart';
import '../data/omise_tokenization.dart';
import 'card_number_formatter.dart';

/// Full-screen card entry + charge flow: collects card details, tokenizes
/// them directly against Omise (never touching our backend), then calls
/// POST /coins/purchase with the resulting token. Returns the purchase
/// result to the caller on success, or null if the user backs out.
Future<CoinPurchaseResult?> showCardFormScreen(
  BuildContext context, {
  required CoinPackage package,
  required Future<CoinPurchaseResult> Function(String omiseToken) onCharge,
}) {
  return Navigator.of(context).push<CoinPurchaseResult>(
    MaterialPageRoute(builder: (_) => CardFormScreen(package: package, onCharge: onCharge)),
  );
}

class CardFormScreen extends StatefulWidget {
  const CardFormScreen({super.key, required this.package, required this.onCharge});

  final CoinPackage package;
  final Future<CoinPurchaseResult> Function(String omiseToken) onCharge;

  @override
  State<CardFormScreen> createState() => _CardFormScreenState();
}

enum _Stage { form, charging, success, failure }

class _CardFormScreenState extends State<CardFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  final _tokenClient = OmiseTokenizationClient();
  _Stage _stage = _Stage.form;
  String? _errorMessage;
  CoinPurchaseResult? _result;

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  String? _validateNumber(String? value) {
    final digits = (value ?? '').replaceAll(' ', '');
    if (digits.length < 12) return 'หมายเลขบัตรไม่ครบ';
    if (!isValidLuhn(digits)) return 'หมายเลขบัตรไม่ถูกต้อง';
    return null;
  }

  String? _validateExpiry(String? value) {
    final match = RegExp(r'^(\d{2})/(\d{2})$').firstMatch(value ?? '');
    if (match == null) return 'รูปแบบ MM/YY';
    final month = int.parse(match.group(1)!);
    final year = 2000 + int.parse(match.group(2)!);
    if (month < 1 || month > 12) return 'เดือนไม่ถูกต้อง';
    final now = DateTime.now();
    final expiry = DateTime(year, month + 1); // first day after the expiry month
    if (expiry.isBefore(now)) return 'บัตรหมดอายุแล้ว';
    return null;
  }

  String? _validateCvv(String? value) {
    if (value == null || value.length < 3 || value.length > 4) return 'CVV ไม่ถูกต้อง';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _stage = _Stage.charging;
      _errorMessage = null;
    });

    try {
      final expiryMatch = RegExp(r'^(\d{2})/(\d{2})$').firstMatch(_expiryController.text)!;
      final token = await _tokenClient.createToken(
        CardDetails(
          name: _nameController.text.trim(),
          number: _numberController.text.replaceAll(' ', ''),
          expirationMonth: int.parse(expiryMatch.group(1)!),
          expirationYear: 2000 + int.parse(expiryMatch.group(2)!),
          securityCode: _cvvController.text,
        ),
      );

      final result = await widget.onCharge(token);
      if (!mounted) return;

      setState(() {
        _result = result;
        _stage = result.success || result.status == 'pending' ? _Stage.success : _Stage.failure;
      });
    } on OmiseTokenizationException catch (e) {
      if (!mounted) return;
      setState(() {
        _stage = _Stage.failure;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _stage = _Stage.failure;
        _errorMessage = 'ชำระเงินไม่สำเร็จ ลองใหม่อีกทีนะ';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ชำระเงิน')),
      body: switch (_stage) {
        _Stage.form => _buildForm(),
        _Stage.charging => const _StatusView(
            emoji: '🍃',
            message: 'กำลังดำเนินการชำระเงิน...',
            showSpinner: true,
          ),
        _Stage.success => _StatusView(
            emoji: '🎉',
            message: _result?.status == 'pending'
                ? 'รับคำขอชำระเงินแล้ว กำลังรอการยืนยัน'
                : 'ชำระเงินสำเร็จแล้ว! ได้เหรียญเพิ่ม ${widget.package.coins} เหรียญ',
            onDone: () => Navigator.of(context).pop(_result),
          ),
        _Stage.failure => _StatusView(
            emoji: '😢',
            message: _errorMessage ?? 'ชำระเงินไม่สำเร็จ',
            isError: true,
            onDone: () => setState(() => _stage = _Stage.form),
            doneLabel: 'ลองใหม่อีกครั้ง',
          ),
      },
    );
  }

  Widget _buildForm() {
    final pkg = widget.package;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.yellowPale,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(child: Text('${pkg.coins} เหรียญ', style: const TextStyle(fontWeight: FontWeight.bold))),
                  Text('฿${pkg.priceThb}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'ชื่อบนบัตร', prefixIcon: Icon(Icons.person_outline)),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'กรุณากรอกชื่อบนบัตร' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _numberController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, CardNumberFormatter()],
              decoration: const InputDecoration(labelText: 'หมายเลขบัตร', prefixIcon: Icon(Icons.credit_card)),
              validator: _validateNumber,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _expiryController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, CardExpiryFormatter()],
                    decoration: const InputDecoration(labelText: 'MM/YY'),
                    validator: _validateExpiry,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _cvvController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    decoration: const InputDecoration(labelText: 'CVV'),
                    validator: _validateCvv,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'ข้อมูลบัตรของคุณจะถูกส่งตรงไปยัง Omise อย่างปลอดภัย ไม่ผ่านเซิร์ฟเวอร์ของเรา 🔒',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
            ),
            const SizedBox(height: 24),
            GradientButton(label: 'ชำระเงิน ฿${pkg.priceThb}', onPressed: _submit),
          ],
        ),
      ),
    );
  }
}

class _StatusView extends StatelessWidget {
  const _StatusView({
    required this.emoji,
    required this.message,
    this.showSpinner = false,
    this.isError = false,
    this.onDone,
    this.doneLabel,
  });

  final String emoji;
  final String message;
  final bool showSpinner;
  final bool isError;
  final VoidCallback? onDone;
  final String? doneLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isError ? AppColors.danger : AppColors.greyDark,
              ),
            ),
            if (showSpinner) ...[
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
            ],
            if (onDone != null) ...[
              const SizedBox(height: 24),
              GradientButton(label: doneLabel ?? 'เสร็จสิ้น', onPressed: onDone),
            ],
          ],
        ),
      ),
    );
  }
}
