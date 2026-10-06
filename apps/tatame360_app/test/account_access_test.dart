import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tatame360_app/features/account_access.dart';
import 'package:tatame360_app/shared/ui.dart';

void main() {
  testWidgets('reset password validates a strong matching password', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: appTheme(),
          home: const ResetPasswordPage(token: 'valid-looking-token'),
        ),
      ),
    );

    expect(find.text('Criar nova senha'), findsOneWidget);
    expect(find.text('Nova senha'), findsOneWidget);
    expect(find.text('Confirmar nova senha'), findsOneWidget);
    final firstField = tester.getRect(find.byType(TextFormField).first);
    expect(firstField.left, greaterThanOrEqualTo(0));
    expect(firstField.right, lessThanOrEqualTo(390));
    expect(tester.takeException(), isNull);
  });

  testWidgets('invitation without token explains that the link is invalid', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: appTheme(),
          home: const InvitationPage(token: ''),
        ),
      ),
    );

    expect(find.text('Link inválido'), findsOneWidget);
    expect(find.textContaining('novo link de convite'), findsOneWidget);
  });
}
