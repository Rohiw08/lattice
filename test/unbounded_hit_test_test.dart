import 'package:lattice/src/core/utils/custom_stack_widget.dart';
import 'package:lattice/src/features/nodes/presentation/flow_no_drag.dart';
import 'package:lattice/src/features/nodes/presentation/node_drag_pan_gesture_recognizer.dart';
import 'package:lattice/src/features/nodes/presentation/unbounded_raw_gesture_detector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'nodes outside viewport-sized layout box still receive taps after pan transform',
    (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 400,
            height: 300,
            child: Transform(
              transform: Matrix4.translationValues(-900, 0, 0),
              child: UnboundedSizedBox(
                width: 400,
                height: 300,
                child: InfiniteHitTestStack(
                  clipBehavior: Clip.none,
                  children: [
                    const UnboundedPositioned.fill(
                      child: SizedBox.expand(),
                    ),
                    Positioned(
                      left: 1000,
                      top: 100,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => tapped = true,
                        child: const SizedBox(
                          width: 150,
                          height: 80,
                          child: ColoredBox(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tapAt(const Offset(100 + 75, 100 + 40));
      await tester.pump();

      expect(tapped, isTrue);
    },
  );

  testWidgets(
    'overflow panel beside node receives taps through UnboundedRawGestureDetector',
    (tester) async {
      var panelTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 400,
            height: 300,
            child: UnboundedSizedBox(
              width: 150,
              height: 40,
              child: InfiniteHitTestStack(
                clipBehavior: Clip.none,
                children: [
                  UnboundedRawGestureDetector(
                    behavior: HitTestBehavior.opaque,
                    gestures: const <Type, GestureRecognizerFactory>{},
                    child: InfiniteHitTestStack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.topLeft,
                      children: [
                        const SizedBox(
                          width: 150,
                          height: 40,
                          child: ColoredBox(color: Colors.blue),
                        ),
                        Positioned(
                          left: 160,
                          top: 0,
                          child: FlowNoDrag(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => panelTapped = true,
                              child: const SizedBox(
                                width: 80,
                                height: 80,
                                child: ColoredBox(color: Colors.green),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tapAt(const Offset(160 + 40, 40));
      await tester.pump();

      expect(panelTapped, isTrue);
    },
  );

  testWidgets(
    'IconButton inside node shell does not start node pan',
    (tester) async {
      var buttonPressed = false;
      var nodeDragStarted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 200,
              height: 80,
              child: NodeDragShell(
                child: UnboundedRawGestureDetector(
                  behavior: HitTestBehavior.opaque,
                  gestures: <Type, GestureRecognizerFactory>{
                    NodeDragPanGestureRecognizer:
                        GestureRecognizerFactoryWithHandlers<
                            NodeDragPanGestureRecognizer>(
                      () => NodeDragPanGestureRecognizer(),
                      (r) {
                        r.onStart = (_) => nodeDragStarted = true;
                      },
                    ),
                  },
                  child: ColoredBox(
                    color: Colors.blue,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        onPressed: () => buttonPressed = true,
                        icon: const Icon(Icons.palette),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.palette));
      await tester.pump();

      expect(buttonPressed, isTrue);
      expect(nodeDragStarted, isFalse);
    },
  );

  testWidgets(
    'Listener under transform blocks taps without UnboundedHitTest (regression)',
    (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 400,
            height: 300,
            child: Transform(
              transform: Matrix4.translationValues(-900, 0, 0),
              child: Listener(
                onPointerDown: (_) {},
                child: SizedBox(
                  width: 400,
                  height: 300,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: 1000,
                        top: 100,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => tapped = true,
                          child: const SizedBox(
                            width: 150,
                            height: 80,
                            child: ColoredBox(color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tapAt(const Offset(100 + 75, 100 + 40));
      await tester.pump();

      expect(tapped, isFalse);
    },
  );
}
