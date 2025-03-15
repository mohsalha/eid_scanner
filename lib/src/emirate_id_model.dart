part of eid_scanner;

/// A model class that represents the details of an Emirates ID.
class EmirateIdModel {
  /// The name of the Emirates ID holder.
  final String name;

  /// The Emirates ID number.
  final String number;

  /// The issue date of the Emirates ID, optional.
  final String? issueDate;

  /// The expiry date of the Emirates ID, optional.
  final String? expiryDate;

  /// The date of birth of the Emirates ID holder, optional.
  final String? dateOfBirth;

  /// The nationality of the Emirates ID holder, optional.
  final String? nationality;

  /// The sex/gender of the Emirates ID holder, optional.
  final String? sex;

  /// Creates an [EmirateIdModel] with the given parameters.
  ///
  /// The [name] and [number] are required, while other fields are optional.
  EmirateIdModel({
    required this.name,
    required this.number,
    this.issueDate,
    this.expiryDate,
    this.dateOfBirth,
    this.nationality,
    this.sex,
  });

  @override
  String toString() {
    var string = '';

    // Append each non-null and non-empty field to the string
    string += name.isEmpty ? "" : 'Holder Name = $name\n';
    string += number.isEmpty ? "" : 'Number = $number\n';
    string += expiryDate == null ? "" : 'Expiry Date = $expiryDate\n';
    string += issueDate == null ? "" : 'Issue Date = $issueDate\n';
    string += dateOfBirth == null ? "" : 'DoB = $dateOfBirth\n';
    string += nationality == null ? "" : 'Nationality = $nationality\n';
    string += sex == null ? "" : 'Sex = $sex\n';

    return string;
  }
}
