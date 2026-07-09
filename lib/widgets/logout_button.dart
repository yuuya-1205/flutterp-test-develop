import 'package:flutter/material.dart';

/// Figma「自動車マッチングApp」の "対応ボタン"（node-id: 1742-10958）を
/// もとにしたログアウトボタン。
///
/// デザイントークン:
///   - 背景 primary[300] : #1FA2CB
///   - 文字 primary[50]  : #ECF7FB
class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  static const Color _background = Color(0xFF1FA2CB); // primary[300]
  static const Color _foreground = Color(0xFFECF7FB); // primary[50]

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 357,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _background,
          foregroundColor: _foreground,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
          ),
        ),
        child: const Text(
          'ログアウト',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// Figma「退会する」リンク（node-id: 1742-10959）。
///
/// デザイントークン:
///   - 文字 alert : #FF4242（下線付き）
class WithdrawLink extends StatelessWidget {
  const WithdrawLink({super.key, this.onPressed});

  final VoidCallback? onPressed;

  static const Color _alert = Color(0xFFFF4242); // alert

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: const Text(
        '退会する',
        style: TextStyle(
          color: _alert,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.underline,
          decorationColor: _alert,
        ),
      ),
    );
  }
}
