import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rukun_kita/features/shared/widgets/empty_state.dart';

void main() {
  testWidgets('EmptyState renders title and message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icons.info_outline,
            title: 'Kosong',
            message: 'Belum ada data.',
          ),
        ),
      ),
    );

    expect(find.text('Kosong'), findsOneWidget);
    expect(find.text('Belum ada data.'), findsOneWidget);
  });
}
