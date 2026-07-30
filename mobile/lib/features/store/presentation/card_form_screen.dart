import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    final digits = (value ?? '').replaceAll(' ', '');
    if (digits.length < 12) return l10n.cardFormNumberIncomplete;
    if (!isValidLuhn(digits)) return l10n.cardFormNumberInvalid;
    return null;
  }

  String? _validateExpiry(String? value) {
    final l10n = AppLocalizations.of(context);
    final match = RegExp(r'^(\d{2})/(\d{2})$').firstMatch(value ?? '');
    if (match == null) return l10n.cardFormExpiryFormat;
    final month = int.parse(match.group(1)!);
    final year = 2000 + int.parse(match.group(2)!);
    if (month < 1 || month > 12) return l10n.cardFormExpiryMonthInvalid;
    final now = DateTime.now();
    final expiry = DateTime(year, month + 1); // first day after the expiry month
    if (expiry.isBefore(now)) return l10n.cardFormExpired;
    return null;
  }

  String? _validateCvv(String? value) {
    final l10n = AppLocalizations.of(context);
    if (value == null || value.length < 3 || value.length > 4) return l10n.cardFormCvvInvalid;
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
        _errorMessage = AppLocalizations.of(context).cardFormChargeFailedRetry;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.cardFormTitle)),
      body: switch (_stage) {
        _Stage.form => _buildForm(),
        _Stage.charging => _StatusView(
            icon: Icons.hourglass_top,
            iconColor: AppColors.pinkDark,
            message: l10n.cardFormChargingMessage,
            showSpinner: true,
          ),
        _Stage.success => _StatusView(
            icon: Icons.check_circle,
            iconColor: AppColors.success,
            message: _result?.status == 'pending'
                ? l10n.cardFormPendingMessage
                : l10n.cardFormSuccessMessage(widget.package.coins),
            onDone: () => Navigator.of(context).pop(_result),
          ),
        _Stage.failure => _StatusView(
            icon: Icons.error_outline,
            iconColor: AppColors.danger,
            message: _errorMessage ?? l10n.cardFormChargeFailed,
            isError: true,
            onDone: () => setState(() => _stage = _Stage.form),
            doneLabel: l10n.retryLabel,
          ),
      },
    );
  }

  Widget _buildForm() {
    final l10n = AppLocalizations.of(context);
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
                  const Icon(Icons.monetization_on, size: 26, color: AppColors.yellowDark),
                  const SizedBox(width: 12),
                  Expanded(child: Text(l10n.coinAmountLabel(pkg.coins), style: const TextStyle(fontWeight: FontWeight.bold))),
                  Text('฿${pkg.priceThb}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(labelText: l10n.cardFormNameLabel, prefixIcon: const Icon(Icons.person_outline)),
              validator: (v) => (v == null || v.trim().isEmpty) ? l10n.cardFormNameValidator : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _numberController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, CardNumberFormatter()],
              decoration: InputDecoration(labelText: l10n.cardFormNumberLabel, prefixIcon: const Icon(Icons.credit_card)),
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
            Row(
              children: [
                Icon(Icons.lock_outline, size: 12, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    l10n.cardFormSecurityNote,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            GradientButton(label: l10n.cardFormPayButton(pkg.priceThb), onPressed: _submit),
          ],
        ),
      ),
    );
  }
}

class _StatusView extends StatelessWidget {
  const _StatusView({
    required this.icon,
    required this.iconColor,
    required this.message,
    this.showSpinner = false,
    this.isError = false,
    this.onDone,
    this.doneLabel,
  });

  final IconData icon;
  final Color iconColor;
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
            Icon(icon, size: 64, color: iconColor),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isError ? AppColors.danger : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            if (showSpinner) ...[
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
            ],
            if (onDone != null) ...[
              const SizedBox(height: 24),
              GradientButton(label: doneLabel ?? AppLocalizations.of(context).doneLabel, onPressed: onDone),
            ],
          ],
        ),
      ),
    );
  }
}
