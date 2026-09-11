import 'package:lattice/lattice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _ThemeProbe extends StatelessWidget {
  const _ThemeProbe({required this.onTheme, this.onMaybe});

  final ValueChanged<FlowCanvasTheme> onTheme;
  final ValueChanged<FlowCanvasTheme?>? onMaybe;

  @override
  Widget build(BuildContext context) {
    onTheme(context.flowCanvasTheme);
    onMaybe?.call(FlowCanvasThemeProvider.maybeOf(context));
    return const SizedBox.shrink();
  }
}

Widget _app({
  Brightness brightness = Brightness.light,
  ColorScheme? colorScheme,
  bool useMaterial3 = true,
  required Widget child,
}) {
  return MaterialApp(
    // Zero duration so theme switches apply immediately in tests
    // (MaterialApp animates theme changes by default).
    themeAnimationDuration: Duration.zero,
    theme: ThemeData(
      brightness: brightness,
      colorScheme: colorScheme,
      useMaterial3: useMaterial3,
    ),
    home: child,
  );
}

void main() {
  testWidgets('without a provider, adapts to app brightness', (tester) async {
    FlowCanvasTheme? seen;
    await tester.pumpWidget(
      _app(
        brightness: Brightness.light,
        child: _ThemeProbe(onTheme: (t) => seen = t),
      ),
    );
    expect(seen, FlowCanvasTheme.light());

    await tester.pumpWidget(
      _app(
        brightness: Brightness.dark,
        child: _ThemeProbe(onTheme: (t) => seen = t),
      ),
    );
    expect(seen, FlowCanvasTheme.dark());
  });

  testWidgets('maybeOf is null and of falls back without a provider',
      (tester) async {
    FlowCanvasTheme? theme;
    FlowCanvasTheme? maybe;
    await tester.pumpWidget(
      _app(
        child: _ThemeProbe(
          onTheme: (t) => theme = t,
          onMaybe: (t) => maybe = t,
        ),
      ),
    );
    expect(maybe, isNull);
    expect(theme, FlowCanvasTheme.light());
  });

  testWidgets('explicit theme overrides parent brightness', (tester) async {
    FlowCanvasTheme? seen;
    await tester.pumpWidget(
      _app(
        brightness: Brightness.light,
        child: FlowCanvasThemeProvider(
          theme: FlowCanvasTheme.dark(),
          child: _ThemeProbe(onTheme: (t) => seen = t),
        ),
      ),
    );
    expect(seen, FlowCanvasTheme.dark());
  });

  testWidgets('partial theme is resolved against the parent brightness',
      (tester) async {
    final node = FlowNodeStyle.colored(color: Colors.red);
    FlowCanvasTheme? seen;
    await tester.pumpWidget(
      _app(
        brightness: Brightness.dark,
        child: FlowCanvasThemeProvider(
          theme: FlowCanvasTheme(node: node),
          child: _ThemeProbe(onTheme: (t) => seen = t),
        ),
      ),
    );
    expect(seen?.node?.decoration, node.decoration);
    expect(seen?.background, FlowCanvasTheme.dark().background);
    expect(seen?.edge, FlowCanvasTheme.dark().edge);
  });

  testWidgets('a partial theme always fills gaps from the parent brightness',
      (tester) async {
    FlowCanvasTheme? seen;
    await tester.pumpWidget(
      _app(
        child: FlowCanvasThemeProvider(
          theme: FlowCanvasTheme(node: FlowNodeStyle.colored(color: Colors.red)),
          child: _ThemeProbe(onTheme: (t) => seen = t),
        ),
      ),
    );
    expect(seen?.node, isNotNull);
    expect(seen?.background, FlowCanvasTheme.light().background);
  });

  testWidgets('named light()/dark() constructors force a brightness',
      (tester) async {
    FlowCanvasTheme? lightSeen;
    await tester.pumpWidget(
      _app(
        brightness: Brightness.dark,
        child: FlowCanvasThemeProvider.light(
          child: _ThemeProbe(onTheme: (t) => lightSeen = t),
        ),
      ),
    );
    expect(lightSeen, FlowCanvasTheme.light());

    FlowCanvasTheme? darkSeen;
    await tester.pumpWidget(
      _app(
        brightness: Brightness.light,
        child: FlowCanvasThemeProvider.dark(
          child: _ThemeProbe(onTheme: (t) => darkSeen = t),
        ),
      ),
    );
    expect(darkSeen, FlowCanvasTheme.dark());
  });

  testWidgets('adaptive(brightness) wins over parent brightness',
      (tester) async {
    FlowCanvasTheme? seen;
    await tester.pumpWidget(
      _app(
        brightness: Brightness.light,
        child: FlowCanvasThemeProvider.adaptive(
          brightness: Brightness.dark,
          child: _ThemeProbe(onTheme: (t) => seen = t),
        ),
      ),
    );
    expect(seen, FlowCanvasTheme.dark());
  });

  testWidgets('auto() generates from the Material color scheme', (tester) async {
    FlowCanvasTheme? seen;
    await tester.pumpWidget(
      _app(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
        child: FlowCanvasThemeProvider.auto(
          child: _ThemeProbe(onTheme: (t) => seen = t),
        ),
      ),
    );
    expect(seen, isNotNull);
    expect(
      (seen!.node?.decoration as BoxDecoration).color,
      isNot(
        (FlowCanvasTheme.light().node?.decoration as BoxDecoration).color,
      ),
    );
    expect(seen!.background, isNotNull);
  });

  testWidgets('a nested provider merges over the parent flow theme',
      (tester) async {
    FlowCanvasTheme? seen;
    await tester.pumpWidget(
      _app(
        child: FlowCanvasThemeProvider.dark(
          child: FlowCanvasThemeProvider(
            theme: FlowCanvasTheme(node: FlowNodeStyle.colored(color: Colors.red)),
            child: _ThemeProbe(onTheme: (t) => seen = t),
          ),
        ),
      ),
    );
    // Inner override wins for node, dark parent fills the rest.
    expect(seen?.node?.decoration, isNotNull);
    expect(
      (seen!.node!.decoration as BoxDecoration).color,
      Colors.red,
    );
    expect(seen!.edge, FlowCanvasTheme.dark().edge);
  });

  testWidgets('toThemeData extension is picked up without a provider',
      (tester) async {
    FlowCanvasTheme? seen;
    await tester.pumpWidget(
      MaterialApp(
        theme: FlowCanvasTheme.dark().toThemeData(),
        home: _ThemeProbe(onTheme: (t) => seen = t),
      ),
    );
    expect(seen, FlowCanvasTheme.dark());
  });

  testWidgets('provider preserves unrelated theme extensions', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: const [_MarkerExtension()],
          brightness: Brightness.light,
        ),
        home: FlowCanvasThemeProvider.dark(
          child: Builder(
            builder: (context) {
              expect(
                Theme.of(context).extension<_MarkerExtension>(),
                isNotNull,
              );
              expect(
                context.flowCanvasTheme,
                FlowCanvasTheme.dark(),
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  });
}

class _MarkerExtension extends ThemeExtension<_MarkerExtension> {
  const _MarkerExtension();

  @override
  _MarkerExtension copyWith() => this;

  @override
  _MarkerExtension lerp(
    covariant ThemeExtension<_MarkerExtension>? other,
    double t,
  ) =>
      this;
}