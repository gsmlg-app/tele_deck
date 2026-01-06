/// Data class representing input method information
class ImeInfo {
  /// Creates a new [ImeInfo] instance
  const ImeInfo({
    required this.id,
    required this.packageName,
    required this.serviceName,
    required this.label,
  });

  /// Full IME ID (packageName/serviceName)
  final String id;

  /// Package name of the IME
  final String packageName;

  /// Service class name
  final String serviceName;

  /// Display label for the IME
  final String label;

  /// Creates an [ImeInfo] from a map
  factory ImeInfo.fromMap(Map<dynamic, dynamic> map) {
    return ImeInfo(
      id: map['id'] as String? ?? '',
      packageName: map['packageName'] as String? ?? '',
      serviceName: map['serviceName'] as String? ?? '',
      label: map['label'] as String? ?? '',
    );
  }

  /// Converts this info to a map
  Map<String, String> toMap() {
    return {
      'id': id,
      'packageName': packageName,
      'serviceName': serviceName,
      'label': label,
    };
  }

  @override
  String toString() {
    return 'ImeInfo(id: $id, label: $label)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ImeInfo && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Data class representing editor info from the current input field
class EditorInfo {
  /// Creates a new [EditorInfo] instance
  const EditorInfo({
    required this.inputType,
    required this.imeOptions,
    this.packageName,
    this.fieldId,
    this.fieldName,
  });

  /// Input type flags (text, number, password, etc.)
  final int inputType;

  /// IME options (action button type, etc.)
  final int imeOptions;

  /// Package name of the app with the input field
  final String? packageName;

  /// Field ID in the editor
  final int? fieldId;

  /// Field name/hint in the editor
  final String? fieldName;

  /// Creates an [EditorInfo] from a map
  factory EditorInfo.fromMap(Map<dynamic, dynamic> map) {
    return EditorInfo(
      inputType: map['inputType'] as int? ?? 0,
      imeOptions: map['imeOptions'] as int? ?? 0,
      packageName: map['packageName'] as String?,
      fieldId: map['fieldId'] as int?,
      fieldName: map['fieldName'] as String?,
    );
  }

  /// Converts this info to a map
  Map<String, dynamic> toMap() {
    return {
      'inputType': inputType,
      'imeOptions': imeOptions,
      'packageName': packageName,
      'fieldId': fieldId,
      'fieldName': fieldName,
    };
  }

  /// Check if this is a password field
  bool get isPassword =>
      (inputType & 0x80) != 0; // TYPE_TEXT_VARIATION_PASSWORD

  /// Check if this is a numeric field
  bool get isNumeric => (inputType & 0x02) != 0; // TYPE_CLASS_NUMBER

  /// Check if this is a multiline field
  bool get isMultiline =>
      (inputType & 0x20000) != 0; // TYPE_TEXT_FLAG_MULTI_LINE

  @override
  String toString() {
    return 'EditorInfo(inputType: $inputType, imeOptions: $imeOptions, package: $packageName)';
  }
}
