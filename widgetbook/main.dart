import 'package:flutter/material.dart';
import 'package:flutter_test_develop/widgets/logout_button.dart';
import 'package:widgetbook/widgetbook.dart';

/// Widgetbook のエントリーポイント。
///
/// 起動:
///   flutter run -d chrome -t widgetbook/main.dart
/// もしくは Web サーバとして:
///   flutter run -d web-server --web-port 8080 -t widgetbook/main.dart
void main() {
  runApp(const WidgetbookApp());
}

class WidgetbookApp extends StatelessWidget {
  const WidgetbookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      addons: [
        // テーマ切り替え（ライト / ダーク）。
        ThemeAddon<ThemeData>(
          themes: [
            WidgetbookTheme(name: 'Light', data: ThemeData.light()),
            WidgetbookTheme(name: 'Dark', data: ThemeData.dark()),
          ],
          themeBuilder: (context, theme, child) {
            return Theme(data: theme, child: child);
          },
        ),
        // 画面サイズ（ビューポート）切り替え。
        ViewportAddon(
          [
            IosViewports.iPhone13,
            IosViewports.iPhoneSE,
            AndroidViewports.samsungGalaxyS20,
          ],
        ),
        // 余白を付けて中身を見やすくする。
        AlignmentAddon(),
      ],
      directories: [
        WidgetbookFolder(
          name: 'アカウント',
          children: [
            WidgetbookComponent(
              name: 'LogoutButton',
              useCases: [
                WidgetbookUseCase(
                  name: 'デフォルト',
                  builder: (context) => Center(
                    child: LogoutButton(onPressed: () {}),
                  ),
                ),
                WidgetbookUseCase(
                  name: '無効 (disabled)',
                  builder: (context) => const Center(
                    child: LogoutButton(),
                  ),
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'WithdrawLink',
              useCases: [
                WidgetbookUseCase(
                  name: 'デフォルト',
                  builder: (context) => Center(
                    child: WithdrawLink(onPressed: () {}),
                  ),
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'ログアウト / 退会エリア',
              useCases: [
                WidgetbookUseCase(
                  name: 'Figma再現 (1742-10957)',
                  builder: (context) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        LogoutButton(onPressed: () {}),
                        const SizedBox(height: 16),
                        WithdrawLink(onPressed: () {}),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
