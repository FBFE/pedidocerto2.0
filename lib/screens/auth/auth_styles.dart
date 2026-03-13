import 'package:flutter/material.dart';
import '../../theme/pedido_certo_theme.dart';

const Color _grayLabel = Color(0xFF6B7280);
const Color _borderGray = Color(0xFFE0E0E0);

InputDecoration authInputDecoration({
  required String labelText,
  String? hintText,
  Widget? suffixIcon,
  bool obscureText = false,
}) {
  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    labelStyle: const TextStyle(color: _grayLabel, fontSize: 14),
    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
    floatingLabelBehavior: FloatingLabelBehavior.auto,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: _borderGray),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: _borderGray),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: PedidoCertoTheme.primaryBlue, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.red),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    suffixIcon: suffixIcon,
  );
}

Widget authPrimaryButton({
  required VoidCallback onPressed,
  required String label,
  bool loading = false,
}) {
  return SizedBox(
    width: double.infinity,
    height: 48,
    child: FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: PedidoCertoTheme.primaryBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
      child: loading
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            )
          : Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
    ),
  );
}

Widget authTextLink({
  required String text,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Text(
      text,
      style: const TextStyle(
        color: _grayLabel,
        fontSize: 14,
        decoration: TextDecoration.underline,
        decorationColor: _grayLabel,
      ),
    ),
  );
}
