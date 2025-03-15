part of eid_scanner;

/// A class to scan Emirates ID cards and extract relevant information.
///
/// This class uses Google ML Kit's text recognition capabilities to process
/// the image of an Emirates ID, and it extracts relevant details such as the
/// name, nationality, sex, ID number, and important dates (birth, issue, expiry).
class EIDScanner {
  /// Scans an Emirates ID card and extracts information.
  ///
  /// This method processes the provided image of an Emirates ID and extracts
  /// relevant data, including the name, ID number, nationality, sex, and dates.
  ///
  /// Parameters:
  /// - [image]: The image file of the Emirates ID to be scanned.
  ///
  /// Returns:
  /// - An instance of [EmirateIdModel] containing the extracted data, or
  ///   `null` if the ID could not be scanned or if it does not match the expected
  ///   Emirates ID format.
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

        if (extractDate(cleanedElement)!=null) {
          eIdDates.add(extractDate(cleanedElement)!);
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
        dateOfBirth: eIdDates.length >= 1 ? eIdDates[0] : null,
        issueDate: eIdDates.length >= 2 ? eIdDates[1] : null,
        expiryDate: eIdDates.length >= 3 ? eIdDates[2] : null,
      );
    } catch (e) {
      print("Error scanning Emirates ID: $e");
      return null;
    }
  }

  /// Sorts dates in ascending order.
  ///
  /// This method takes a list of dates in the format `dd/MM/yyyy` and sorts
  /// them in ascending order.
  ///
  /// Parameters:
  /// - [dates]: A list of dates as strings in the format `dd/MM/yyyy`.
  ///
  /// Returns:
  /// - A sorted list of date strings in ascending order.
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

  /// Checks if the given text is a valid date (dd/MM/yyyy).
  ///
  /// This method checks whether the input text matches the format of a valid date
  /// (dd/MM/yyyy). It returns `true` if the text matches the format and `false` otherwise.
  ///
  /// Parameters:
  /// - [text]: The string to be checked for the date format.
  ///
  /// Returns:
  /// - `true` if the text matches the date format, otherwise `false`.
  static String? extractDate(String text) {
    RegExp pattern = RegExp(r'\b\d{1,2}/\d{1,2}/\d{4}\b');
    Match? match = pattern.firstMatch(text);
    return match?.group(0); // Returns the extracted date or null if no match
  }


  /// Extracts gender if present.
  ///
  /// This method checks if the input text contains gender information in the format
  /// `sex:<value>` and extracts the value.
  ///
  /// Parameters:
  /// - [text]: The string to check for gender information.
  ///
  /// Returns:
  /// - The gender value if found, or `null` if not found.
  static String? _isSex({required String text}) {
    return text.startsWith("sex:") ? text.split(":").last.trim() : null;
  }

  /// Extracts name if present.
  ///
  /// This method checks if the input text contains name information in the format
  /// `name:<value>` and extracts the value.
  ///
  /// Parameters:
  /// - [text]: The string to check for name information.
  ///
  /// Returns:
  /// - The name if found, or `null` if not found.
  static String? _isName({required String text}) {
    return text.startsWith("name:") ? text.split(":").last.trim() : null;
  }

  /// Extracts nationality if present.
  ///
  /// This method checks if the input text contains nationality information in the format
  /// `nationality:<value>` and extracts the value.
  ///
  /// Parameters:
  /// - [text]: The string to check for nationality information.
  ///
  /// Returns:
  /// - The nationality if found, or `null` if not found.
  static String? _isNationality({required String text}) {
    return text.startsWith("nationality:") ? text.split(":").last.trim() : null;
  }

  /// Validates Emirates ID number format (XXX-XXXX-XXXXXXX-X).
  ///
  /// This method checks if the input text matches the format of an Emirates ID
  /// number (XXX-XXXX-XXXXXXX-X). If the pattern is found, it returns the ID number.
  ///
  /// Parameters:
  /// - [text]: The string to check for the Emirates ID number.
  ///
  /// Returns:
  /// - The valid Emirates ID number if found, or `null` if not found.
  static String? _isNumberID({required String text}) {
    // Regular expression to find Emirates ID pattern anywhere in the text
    RegExp pattern = RegExp(r'\b\d{3}-\d{4}-\d{7}-\d{1}\b');
    Match? match = pattern.firstMatch(text);

    return match != null ? match.group(0) : null;
  }
}
