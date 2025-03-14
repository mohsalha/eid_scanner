part of eid_scanner;


class EIDScanner {
  /// Scans an Emirates ID card and extracts information
  static Future<EmirateIdModel?> scanEmirateId({required File image}) async {
    try {
      List<String> eIdDates = [];
      TextRecognizer textDetector = GoogleMlKit.vision.textRecognizer();
      final RecognizedText recognizedText = await textDetector.processImage(
        InputImage.fromFilePath(image.path),
      );

      // Normalize text for better recognition and remove non-English characters
      String normalizedText = recognizedText.text
          .replaceAll(RegExp(r'\s+'), ' ') // Replace multiple spaces with a single space
          .replaceAll(RegExp(r'[^a-zA-Z0-9:/\- ]'), '') // Remove non-English characters
          .toLowerCase();

      print('Normalized Text: $normalizedText');

      // Validate if the card is an Emirates ID
      if (!normalizedText.contains("resident") ||
          !normalizedText.contains("united arab emirates") ||
          !normalizedText.contains("id number")) {
        return null;
      }

      // Attributes
      String? name, number, nationality, sex;

      for (var element in recognizedText.blocks) {
        String cleanedElement = element.text
            .replaceAll(RegExp(r'\s+'), ' ')
            .replaceAll(RegExp(r'[^a-zA-Z0-9:/\- ]'), '') // Remove non-English characters
            .toLowerCase();

        print(cleanedElement);

        if (_isDate(text: cleanedElement)) {
          eIdDates.add(cleanedElement);
        } else if (_isName(text: cleanedElement) != null) {
          name = _isName(text: cleanedElement);
        } else if (_isNationality(text: cleanedElement) != null) {
          nationality = _isNationality(text: cleanedElement);
        } else if (_isSex(text: cleanedElement) != null) {
          sex = _isSex(text: cleanedElement);
        } else if (_isNumberID(text: cleanedElement) != null) {
          number = _isNumberID(text: cleanedElement);
        }
      }

      eIdDates = _sortDateList(dates: eIdDates);
      textDetector.close();

      return EmirateIdModel(
        name: name ?? "Unknown",
        number: number ?? "Unknown",
        nationality: nationality,
        sex: sex,
        dateOfBirth: eIdDates.length >= 3 ? eIdDates[0] : null,
        issueDate: eIdDates.length >= 3 ? eIdDates[1] : null,
        expiryDate: eIdDates.length >= 3 ? eIdDates[2] : null,
      );
    } catch (e) {
      print("Error scanning Emirates ID: $e");
      return null;
    }
  }

  /// Sorts dates in ascending order
  static List<String> _sortDateList({required List<String> dates}) {
    List<DateTime> tempList = [];
    DateFormat format = DateFormat("dd/MM/yyyy");
    for (var date in dates) {
      try {
        tempList.add(format.parse(date));
      } catch (_) {}
    }
    tempList.sort((a, b) => a.compareTo(b));
    return tempList.map((date) => format.format(date)).toList();
  }

  /// Checks if the given text is a valid date (dd/MM/yyyy)
  static bool _isDate({required String text}) {
    RegExp pattern = RegExp(r'^\d{2}/\d{2}/\d{4}$');
    return pattern.hasMatch(text);
  }

  /// Extracts gender if present
  static String? _isSex({required String text}) {
    return text.startsWith("sex:") ? text.split(":").last.trim() : null;
  }

  /// Extracts name if present
  static String? _isName({required String text}) {
    return text.startsWith("name:") ? text.split(":").last.trim() : null;
  }

  /// Extracts nationality if present
  static String? _isNationality({required String text}) {
    return text.startsWith("nationality:") ? text.split(":").last.trim() : null;
  }

  /// Validates Emirates ID number format (XXX-XXXX-XXXXXXX-X)
  static String? _isNumberID({required String text}) {
    // Regular expression to find Emirates ID pattern anywhere in the text
    RegExp pattern = RegExp(r'\b\d{3}-\d{4}-\d{7}-\d{1}\b');
    Match? match = pattern.firstMatch(text);

    return match != null ? match.group(0) : null;
  }
}
