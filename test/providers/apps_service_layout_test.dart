import 'package:flauncher/database.dart';
import 'package:flauncher/models/category.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../mocks.mocks.dart';

const _installed = {
  "com.alpha": "Alpha",
  "com.beta": "Beta",
  "com.gamma": "Gamma",
  "com.delta": "Delta",
};

void main() {
  late FLauncherDatabase database;
  late AppsService appsService;

  setUp(() async {
    final channel = MockFLauncherChannel();
    when(channel.getApplications()).thenAnswer((_) async => [
          for (final MapEntry(key: packageName, value: name) in _installed.entries)
            {"packageName": packageName, "name": name, "version": "1.0"},
        ]);
    when(channel.applicationExists(any)).thenAnswer((_) async => false);
    database = FLauncherDatabase.inMemory();
    addTearDown(database.close);
    appsService = AppsService(channel, database);
    for (var i = 0; i < 100 && !appsService.initialized; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(appsService.initialized, isTrue);
  });

  test("restores sections, skipping missing apps and keeping unlisted ones", () async {
    final result = await appsService.restoreLayout({
      "sections": [
        {
          "kind": "category",
          "name": "Favorites",
          "type": "row",
          "sort": "manual",
          "rowHeight": 110,
          "columnsCount": 6,
          "apps": ["com.beta", "com.not.installed"],
        },
        {"kind": "spacer", "height": 40},
        {
          "kind": "category",
          "name": "All Apps",
          "type": "grid",
          "sort": "alphabetical",
          "rowHeight": 120,
          "columnsCount": 7,
          "apps": ["com.alpha"],
        },
      ],
      "hiddenApps": ["com.gamma"],
    });

    expect(result.skippedApps, 1);
    expect(result.addedApps, 1);
    expect(appsService.launcherSections, hasLength(3));
    expect([for (final category in appsService.categories) category.name], ["Favorites", "All Apps"]);
    expect([
      for (final category in appsService.categories) [for (final app in category.applications) app.packageName],
    ], [
      ["com.beta"],
      ["com.alpha", "com.delta"],
    ]);
    expect(appsService.getApplication("com.gamma")!.hidden, isTrue);

    expect(await appsService.exportLayout(), {
      "sections": [
        {
          "kind": "category",
          "name": "Favorites",
          "type": "row",
          "sort": "manual",
          "rowHeight": 110,
          "columnsCount": 6,
          "apps": ["com.beta"],
        },
        {"kind": "spacer", "height": 40},
        {
          "kind": "category",
          "name": "All Apps",
          "type": "grid",
          "sort": "alphabetical",
          "rowHeight": 120,
          "columnsCount": 7,
          "apps": ["com.alpha", "com.delta"],
        },
      ],
      "hiddenApps": ["com.gamma"],
    });
  });

  test("keeps sizes within what the section editor offers", () async {
    await appsService.restoreLayout({
      "sections": [
        {"kind": "category", "name": "Big", "rowHeight": 999, "columnsCount": 1, "type": "unknown"},
      ],
    });

    final category = appsService.categories.single;
    expect(category.rowHeight, 150);
    expect(category.columnsCount, 5);
    expect(category.type, Category.Type);
    // The only section gets every app the layout does not mention.
    expect(category.applications, hasLength(_installed.length));
  });

  test("leaves the layout alone when the backup is malformed", () async {
    final before = await appsService.exportLayout();

    await expectLater(appsService.restoreLayout({"sections": "nope"}), throwsFormatException);
    await expectLater(
      appsService.restoreLayout({
        "sections": [
          {"kind": "category", "name": "Fine"},
          {"kind": "shelf"},
        ],
      }),
      throwsFormatException,
    );
    await expectLater(
      appsService.restoreLayout({
        "sections": [
          {"kind": "category", "name": "Bad apps", "apps": [1, 2]},
        ],
      }),
      throwsFormatException,
    );

    expect(await appsService.exportLayout(), before);
  });
}
