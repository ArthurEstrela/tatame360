import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tatame360_app/features/login.dart';
import 'package:tatame360_app/shared/ui.dart';

void main() {
  testWidgets('login renders the essential fields on a compact screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: appTheme(), home: const LoginPage()),
      ),
    );
    expect(find.text('Bem-vindo ao tatame.'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'E-mail'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Senha'), findsOneWidget);
    expect(find.text('Entrar na academia'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
