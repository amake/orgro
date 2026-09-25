import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orgro/src/components/scroll.dart';

void main() {
  Future<ScrollDirection?> directionWhenScrollStops(
    WidgetTester tester,
    List<Offset> offsets,
  ) async {
    final controller = SnapDirectionScrollController();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ListView(
          controller: controller,
          children: const [SizedBox(height: 2000)],
        ),
      ),
    );
    controller.jumpTo(300);
    await tester.pump();

    ScrollDirection? direction;
    var wasScrolling = false;
    controller.position.isScrollingNotifier.addListener(() {
      if (wasScrolling && !controller.position.isScrollingNotifier.value) {
        direction = controller.position.userScrollDirection;
      }
      wasScrolling = controller.position.isScrollingNotifier.value;
    });

    final gesture = await tester.startGesture(const Offset(200, 400));
    for (final offset in offsets) {
      await gesture.moveBy(offset);
      await tester.pump();
    }
    await gesture.up();
    await tester.pumpAndSettle();
    controller.dispose();
    return direction;
  }

  testWidgets('keeps the main direction through a small reversal', (
    tester,
  ) async {
    expect(
      await directionWhenScrollStops(tester, const [
        Offset(0, 100),
        Offset(0, -12),
      ]),
      ScrollDirection.forward,
    );
  });

  testWidgets('accepts a deliberate reversal', (tester) async {
    expect(
      await directionWhenScrollStops(tester, const [
        Offset(0, 100),
        Offset(0, -24),
      ]),
      ScrollDirection.reverse,
    );
  });

  testWidgets('provides its controller to the document scroll view', (
    tester,
  ) async {
    late ScrollController controller;
    late ScrollController descendantController;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SnapDirectionScrollScope(
          builder: (context) {
            controller = PrimaryScrollController.of(context);
            return CustomScrollView(
              controller: controller,
              slivers: [
                SliverToBoxAdapter(
                  child: Builder(
                    builder: (context) {
                      descendantController = PrimaryScrollController.of(
                        context,
                      );
                      return const SizedBox(height: 1);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );

    expect(controller, isA<SnapDirectionScrollController>());
    expect(controller.hasClients, isTrue);
    expect(descendantController, same(controller));
  });
}
