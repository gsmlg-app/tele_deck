#!/usr/bin/env dart
// ignore_for_file: avoid_print

import 'dart:io';

/// Script to rename the flutter-app-template to a new project name.
///
/// This script:
/// 1. Prompts for a new project name
/// 2. Renames all references from 'flutter_app_template' to the new name
/// 3. Removes test_bricks/ directory (only needed for template development)
///
/// Usage: dart run bin/setup_project.dart [project_name]
void main(List<String> args) async {
  const templateName = 'flutter_app_template';

  // Get current project name from pubspec.yaml
  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    print('Error: pubspec.yaml not found. Run this script from the project root.');
    exit(1);
  }

  final pubspecContent = pubspecFile.readAsStringSync();
  final nameMatch = RegExp(r'^name:\s*(\S+)', multiLine: true).firstMatch(pubspecContent);
  final currentName = nameMatch?.group(1);

  if (currentName == null) {
    print('Error: Could not parse project name from pubspec.yaml');
    exit(1);
  }

  if (currentName != templateName) {
    print('Project has already been renamed from "$templateName" to "$currentName".');
    print('This script is only for initial project setup.');
    exit(0);
  }

  // Get new project name
  String newName;
  if (args.isNotEmpty) {
    newName = args[0];
  } else {
    stdout.write('Enter new project name (snake_case): ');
    newName = stdin.readLineSync()?.trim() ?? '';
  }

  // Validate project name
  if (newName.isEmpty) {
    print('Error: Project name cannot be empty.');
    exit(1);
  }

  if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(newName)) {
    print('Error: Project name must be in snake_case (lowercase letters, numbers, underscores).');
    print('       Must start with a letter.');
    exit(1);
  }

  if (newName == templateName) {
    print('Error: New project name must be different from "$templateName".');
    exit(1);
  }

  print('');
  print('Renaming project from "$templateName" to "$newName"...');
  print('');

  // Files to update
  final filesToUpdate = [
    'pubspec.yaml',
    'README.md',
    'CLAUDE.md',
    'GEMINI.md',
    'AGENTS.md',
    '.metadata',
    'melos_flutter_app_template.iml',
  ];

  // Update files with template name references
  var updatedFiles = 0;
  for (final filePath in filesToUpdate) {
    final file = File(filePath);
    if (file.existsSync()) {
      final content = file.readAsStringSync();
      if (content.contains(templateName)) {
        final newContent = content.replaceAll(templateName, newName);
        file.writeAsStringSync(newContent);
        print('  Updated: $filePath');
        updatedFiles++;
      }
    }
  }

  // Rename melos iml file if it exists
  final melosImlFile = File('melos_$templateName.iml');
  if (melosImlFile.existsSync()) {
    melosImlFile.renameSync('melos_$newName.iml');
    print('  Renamed: melos_$templateName.iml -> melos_$newName.iml');
    updatedFiles++;
  }

  // Remove test_bricks directory
  final testBricksDir = Directory('test_bricks');
  if (testBricksDir.existsSync()) {
    testBricksDir.deleteSync(recursive: true);
    print('  Removed: test_bricks/');
  }

  // Remove brick-test workflow
  final brickTestWorkflow = File('.github/workflows/brick-test.yml');
  if (brickTestWorkflow.existsSync()) {
    brickTestWorkflow.deleteSync();
    print('  Removed: .github/workflows/brick-test.yml');
  }

  print('');
  print('Project renamed successfully! ($updatedFiles files updated)');
  print('');
  print('Next steps:');
  print('  1. Run: melos bootstrap');
  print('  2. Update app icons in app_widget/artwork/assets/icon/');
  print('  3. Update app info in android/app/build.gradle and ios/Runner/Info.plist');
  print('  4. In Claude Code, run: /speckit.constitution');
  print('     (This regenerates the project constitution for your new project)');
  print('  5. Commit your changes: git add -A && git commit -m "chore: initialize project as $newName"');
  print('');
}
