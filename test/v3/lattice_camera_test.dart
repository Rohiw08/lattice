import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/src/v3/v3.dart';

void main() {
  group('LatticeCameraController', () {
    test('setViewport then viewport round-trips', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const viewport =
          LatticeViewportValue(offset: Offset(10, 20), zoom: 2.0);
      container.read(latticeCameraProvider.notifier).setViewport(viewport);
      expect(
        container.read(latticeCameraProvider.notifier).viewport,
        equals(viewport),
      );
    });

    test('matrix maps flow point p to offset + zoom * p', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const viewport =
          LatticeViewportValue(offset: Offset(10, 20), zoom: 2.0);
      container.read(latticeCameraProvider.notifier).setViewport(viewport);
      const p = Offset(3, 4);
      final mapped = MatrixUtils.transformPoint(
        container.read(latticeCameraProvider),
        p,
      );
      expect(mapped.dx, moreOrLessEquals(10 + 2 * 3));
      expect(mapped.dy, moreOrLessEquals(20 + 2 * 4));
    });

    test('panBy shifts mapped point by exactly the delta', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(latticeCameraProvider.notifier).setViewport(
            const LatticeViewportValue(offset: Offset(10, 20), zoom: 2.0),
          );
      const p = Offset(3, 4);
      final before = MatrixUtils.transformPoint(
        container.read(latticeCameraProvider),
        p,
      );
      container.read(latticeCameraProvider.notifier).panBy(const Offset(10, 20));
      final after = MatrixUtils.transformPoint(
        container.read(latticeCameraProvider),
        p,
      );
      expect(after.dx - before.dx, moreOrLessEquals(10));
      expect(after.dy - before.dy, moreOrLessEquals(20));
    });

    test('zoomBy(2) about origin doubles mapped coords', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(latticeCameraProvider.notifier).setViewport(
            const LatticeViewportValue(),
          );
      container.read(latticeCameraProvider.notifier).zoomBy(2);
      const p = Offset(3, 4);
      final mapped = MatrixUtils.transformPoint(
        container.read(latticeCameraProvider),
        p,
      );
      expect(mapped.dx, moreOrLessEquals(6));
      expect(mapped.dy, moreOrLessEquals(8));
    });

    test('zoomBy about focal keeps the focal point fixed', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(latticeCameraProvider.notifier).setViewport(
            const LatticeViewportValue(),
          );
      const focal = Offset(100, 50);
      final before = MatrixUtils.transformPoint(
        container.read(latticeCameraProvider),
        focal,
      );
      container
          .read(latticeCameraProvider.notifier)
          .zoomBy(2, focal: focal);
      final after = MatrixUtils.transformPoint(
        container.read(latticeCameraProvider),
        focal,
      );
      expect(after.dx, moreOrLessEquals(before.dx));
      expect(after.dy, moreOrLessEquals(before.dy));
    });

    test('settled fires after quiescence', () {
      fakeAsync((async) {
        final container = ProviderContainer();
        var fired = 0;
        final sub = container
            .read(latticeCameraProvider.notifier)
            .settled
            .listen((_) => fired++);
        container.read(latticeCameraProvider.notifier).setViewport(
              const LatticeViewportValue(offset: Offset(5, 5), zoom: 1.5),
            );
        async.elapse(const Duration(milliseconds: 50));
        expect(fired, equals(0));
        async.elapse(const Duration(milliseconds: 100));
        expect(fired, equals(1));
        sub.cancel();
        container.dispose();
      });
    });
  });
}
