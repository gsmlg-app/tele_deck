#!/usr/bin/env dart
// ignore_for_file: avoid_print

import 'dart:io';

/// Script to update mason bricks from the flutter-app-template repository.
///
/// This script:
/// 1. Verifies the project has been renamed (not still flutter_app_template)
/// 2. Clones/fetches the template repository
/// 3. Syncs the bricks/ directory to the current project
///
/// Usage: dart run bin/update_bricks.dart [--force]
void main(List<String> args) async {
  const templateName = 'flutter_app_template';
  const templateRepo = 'https://github.com/gsmlg-app/flutter-app-template.git';
  const tempDir = '.template-sync';

  final forceUpdate = args.contains('--force') || args.contains('-f');

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

  // Check if project has been renamed
  if (currentName == templateName) {
    print('Error: Project has not been renamed yet.');
    print('');
    print('This script is for updating bricks in projects that have been');
    print('forked/cloned from the template and renamed.');
    print('');
    print('To rename the project, run:');
    print('  dart run bin/setup_project.dart');
    exit(1);
  }

  print('Updating bricks from template repository...');
  print('Current project: $currentName');
  print('');

  // Clean up any existing temp directory
  final tempDirectory = Directory(tempDir);
  if (tempDirectory.existsSync()) {
    tempDirectory.deleteSync(recursive: true);
  }

  try {
    // Clone template repo with sparse checkout (only bricks directory)
    print('Fetching template repository...');

    var result = Process.runSync('git', [
      'clone',
      '--depth=1',
      '--filter=blob:none',
      '--sparse',
      templateRepo,
      tempDir,
    ]);

    if (result.exitCode != 0) {
      print('Error cloning repository:');
      print(result.stderr);
      exit(1);
    }

    // Set sparse checkout to only include bricks
    result = Process.runSync(
      'git',
      ['sparse-checkout', 'set', 'bricks', 'mason.yaml'],
      workingDirectory: tempDir,
    );

    if (result.exitCode != 0) {
      print('Error setting sparse checkout:');
      print(result.stderr);
      exit(1);
    }

    // Check if bricks directory exists in template
    final templateBricksDir = Directory('$tempDir/bricks');
    if (!templateBricksDir.existsSync()) {
      print('Error: bricks/ directory not found in template repository.');
      exit(1);
    }

    // Sync bricks directory
    print('Syncing bricks...');
    print('');

    final localBricksDir = Directory('bricks');
    if (!localBricksDir.existsSync()) {
      localBricksDir.createSync();
    }

    // Get list of bricks in template
    final templateBricks = templateBricksDir
        .listSync()
        .whereType<Directory>()
        .map((d) => d.path.split('/').last)
        .toList();

    // Get list of local bricks
    final localBricks = localBricksDir
        .listSync()
        .whereType<Directory>()
        .map((d) => d.path.split('/').last)
        .toSet();

    var syncedCount = 0;
    var addedCount = 0;

    for (final brick in templateBricks) {
      final templateBrick = Directory('$tempDir/bricks/$brick');
      final localBrick = Directory('bricks/$brick');

      if (localBricks.contains(brick)) {
        // Update existing brick
        if (forceUpdate || _shouldUpdateBrick(templateBrick, localBrick)) {
          _copyDirectory(templateBrick, localBrick);
          print('  Updated: $brick');
          syncedCount++;
        } else {
          print('  Unchanged: $brick');
        }
      } else {
        // Add new brick
        _copyDirectory(templateBrick, localBrick);
        print('  Added: $brick');
        addedCount++;
      }
    }

    // Update mason.yaml
    final templateMasonYaml = File('$tempDir/mason.yaml');
    if (templateMasonYaml.existsSync()) {
      templateMasonYaml.copySync('mason.yaml');
      print('  Updated: mason.yaml');
    }

    print('');
    print('Sync complete!');
    print('  Updated: $syncedCount bricks');
    print('  Added: $addedCount new bricks');
    print('');
    print('Next steps:');
    print('  1. Run: mason get');
    print('  2. Review changes and commit if satisfied');
    print('');
  } finally {
    // Clean up temp directory
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  }
}

/// Check if a brick should be updated by comparing file contents
bool _shouldUpdateBrick(Directory template, Directory local) {
  final templateFiles = _listFilesRecursive(template);

  for (final templateFile in templateFiles) {
    final relativePath = templateFile.path.substring(template.path.length);
    final localFile = File('${local.path}$relativePath');

    if (!localFile.existsSync()) {
      return true; // New file in template
    }

    if (templateFile.readAsStringSync() != localFile.readAsStringSync()) {
      return true; // File content differs
    }
  }

  return false;
}

/// Recursively list all files in a directory
List<File> _listFilesRecursive(Directory dir) {
  final files = <File>[];

  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File) {
      files.add(entity);
    }
  }

  return files;
}

/// Copy a directory recursively
void _copyDirectory(Directory source, Directory destination) {
  if (destination.existsSync()) {
    destination.deleteSync(recursive: true);
  }
  destination.createSync(recursive: true);

  for (final entity in source.listSync(recursive: false)) {
    final newPath = '${destination.path}/${entity.path.split('/').last}';

    if (entity is File) {
      entity.copySync(newPath);
    } else if (entity is Directory) {
      _copyDirectory(entity, Directory(newPath));
    }
  }
}
