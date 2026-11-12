import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/di/service_locator.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/settings/setting_value.dart';
import 'package:mangabaka_app/core/settings/settings_enums.dart';
import 'package:mangabaka_app/core/settings/settings_manager.dart';
import 'package:mangabaka_app/desktop/screens/settings/desktop_settings_screen.dart';
import 'package:mangabaka_app/features/browse/models/search_filters.dart';
import 'package:mangabaka_app/features/browse/widgets/filters/search_filter_details_section.dart';
import 'package:mangabaka_app/features/profile/services/profile_auth_service.dart';
import 'package:mangabaka_app/features/profile/widgets/dialogs/general_settings_dialogs.dart';
import 'package:mangabaka_app/features/series/widgets/rating_selection_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeAuthService extends ChangeNotifier implements ProfileAuthService {
  @override
  bool get isLoggedIn => false;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SettingsManager.resetForTesting();
    await SettingsManager().init();
    await LocalizationService().init();
    if (getIt.isRegistered<ProfileAuthService>()) {
      getIt.unregister<ProfileAuthService>();
    }
    getIt.registerSingleton<ProfileAuthService>(FakeAuthService());
  });

  testWidgets('select rating step in DesktopSettingsScreen', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: const Scaffold(
          body: DesktopSettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(LocalizationService().translate('content')));
    await tester.pumpAndSettle();

    expect(SettingsManager().ratingSliderStep, RatingSliderStep.step1);

    final menuButton = find.text('1');
    expect(menuButton, findsOneWidget);

    await tester.tap(menuButton);
    await tester.pumpAndSettle();

    await tester.tap(find.text('5').last);
    await tester.pumpAndSettle();

    expect(SettingsManager().ratingSliderStep, RatingSliderStep.step5);
  });

  testWidgets('select rating step in mobile dialog', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => GeneralSettingsDialogs.showRatingSliderStepSelectionDialog(context),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(SettingsManager().ratingSliderStep, RatingSliderStep.step1);

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Tap option '5'
    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();

    expect(SettingsManager().ratingSliderStep, RatingSliderStep.step5);
  });

  testWidgets('RatingSelectionDialog snaps initialRating to nearest step', (tester) async {
    await SettingsManager().setRatingSliderStep(RatingSliderStep.step5);

    int? changedRating;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RatingSelectionDialog(
            initialRating: 87,
            onRatingChanged: (val) => changedRating = val,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 87 snaps to 85 when step is 5
    expect(find.text('85'), findsOneWidget);
    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.divisions, 20);
    expect(slider.value, 85.0);

    // Update sends the snapped value
    await tester.tap(find.text(LocalizationService().translate('update')));
    await tester.pumpAndSettle();

    expect(changedRating, 85);
  });

  testWidgets('RatingSelectionDialog dragging snaps to step multiples', (tester) async {
    await SettingsManager().setRatingSliderStep(RatingSliderStep.step5);

    int? changedRating;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RatingSelectionDialog(
            initialRating: 0,
            onRatingChanged: (val) => changedRating = val,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final sliderFinder = find.byType(Slider);
    final sliderRect = tester.getRect(sliderFinder);

    // Tap at approximately 42% of the slider width -> should snap to 40
    await tester.tapAt(Offset(sliderRect.left + sliderRect.width * 0.42, sliderRect.center.dy));
    await tester.pumpAndSettle();

    final updatedSlider = tester.widget<Slider>(sliderFinder);
    expect(updatedSlider.value % 5, 0.0);
    expect(updatedSlider.value, 40.0);
    expect(find.text('40'), findsOneWidget);

    await tester.tap(find.text(LocalizationService().translate('update')));
    await tester.pumpAndSettle();

    expect(changedRating, 40);
  });

  test('EnumSetting loads string or int safely', () async {
    final setting = EnumSetting(
      'test_step',
      RatingSliderStep.step1,
      RatingSliderStep.values,
    );

    SharedPreferences.setMockInitialValues({'test_step': 1});
    final prefs = await SharedPreferences.getInstance();
    setting.load(prefs);
    expect(setting.value, RatingSliderStep.step5);

    // Should also handle string representation
    await prefs.setString('test_step', 'step10');
    setting.load(prefs);
    expect(setting.value, RatingSliderStep.step10);
  });

  testWidgets('SearchFilterDetailsSection uses ratingSliderStep divisions', (tester) async {
    await SettingsManager().setRatingSliderStep(RatingSliderStep.step10);

    SearchFilters filters = SearchFilters(ratingLower: 20, ratingUpper: 80);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchFilterDetailsSection(
            filters: filters,
            onFiltersChanged: (f) => filters = f,
            l10n: LocalizationService(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final rangeSlider = tester.widget<RangeSlider>(find.byType(RangeSlider).first);
    expect(rangeSlider.divisions, 10);
  });
}
