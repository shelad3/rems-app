import 'package:flutter_test/flutter_test.dart';
import 'package:real_estate_management_system/main.dart';

void main() {
  testWidgets('App loads without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const RealEstateManagementApp());
    expect(find.text('REMS'), findsNothing);
  });
}
