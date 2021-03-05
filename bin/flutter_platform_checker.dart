import 'dart:io';

import 'package:barbecue/barbecue.dart';
import 'package:pub_api_client/pub_api_client.dart';
import 'package:yaml/yaml.dart';
import 'package:tint/tint.dart';

void main() async {
  final pubspecFile = File('pubspec.yaml');

  if (!pubspecFile.existsSync()) {
    stderr.writeln('pubspec.yaml file not found in current directory'.red());
    exit(1);
  }

  var doc = loadYaml(pubspecFile.readAsStringSync());

  final dependencies = doc['dependencies'];

  if (dependencies is! Map) {
    stderr.writeln('no dependencies found in pubspec.yaml'.red());
    exit(1);
  }

  final client = PubClient();

  final rows = <Row>[];

  print(
      'Checking your packages on pub.dev... (This can take some time)'.blue());

  for (final package in dependencies.keys) {
    final res = await client.packageMetrics(package);

    final derivedTags = res?.scorecard?.derivedTags;

    if (derivedTags == null &&
        !['flutter', 'flutter_localizations'].contains(package)) {
      print('package $package not found on pub.dev'.yellow());
      continue;
    }

    String check(String platform) {
      return (['flutter', 'flutter_localizations'].contains(package) ||
              derivedTags.contains('platform:$platform'))
          ? '✓YES'.green()
          : '✗NO'.red();
    }

    rows.add(Row(cells: [
      Cell(package, style: CellStyle(alignment: TextAlignment.TopRight)),
      Cell(check('android')),
      Cell(check('ios')),
      Cell(check('web')),
      Cell(check('windows')),
      Cell(check('linux')),
      Cell(check('macos')),
    ]));
  }

  print(Table(
      tableStyle: TableStyle(border: true),
      header: TableSection(rows: [
        Row(
          cells: [
            Cell('Package Name  '.bold()),
            Cell('Android  '.bold()),
            Cell('iOS  '.bold()),
            Cell('Web  '.bold()),
            Cell('Windows  '.bold()),
            Cell('Linux  '.bold()),
            Cell('macOS  '.bold()),
          ],
          cellStyle: CellStyle(borderBottom: true),
        ),
      ]),
      body: TableSection(
        cellStyle: CellStyle(paddingRight: 2),
        rows: rows,
      )).render());

  exit(0);
}
