import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _PageA extends StatelessWidget {
  const _PageA();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('A')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => context.go('/b'),
          child: const Text('Go B'),
        ),
      ),
    );
  }
}

class _PageB extends StatelessWidget {
  const _PageB();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('B')),
      body: const Center(child: Text('Page B')),
    );
  }
}

void main() {
  testWidgets('GoRouter basic navigation smoke', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => const _PageA()),
        GoRoute(path: '/b', builder: (context, state) => const _PageB()),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    expect(find.text('A'), findsOneWidget);
    expect(find.text('Page B'), findsNothing);

    await tester.tap(find.text('Go B'));
    await tester.pumpAndSettle();

    expect(find.text('B'), findsOneWidget);
    expect(find.text('Page B'), findsOneWidget);
  });
}
