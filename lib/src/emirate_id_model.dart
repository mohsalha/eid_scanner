part of eid_scanner;

class EmirateIdModel {
  final String name;
  final String number;
  final String? issueDate;
  final String? expiryDate;
  final String? dateOfBirth;
  final String? nationality;
  final String? sex;

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
    string += name.isEmpty ? "" : 'Holder Name = $name\n';
    string += number.isEmpty ? "" : 'Number = $number\n';
    string += expiryDate == null ? "" : 'Expiry Date = $expiryDate\n';
    string += issueDate == null ? "" : 'Issue Date = $issueDate\n';
    string += dateOfBirth == null ? "" : 'Cnic Holder DoB = $dateOfBirth\n';
    string += nationality == null ? "" : 'Nationality = $nationality\n';
    string += sex == null ? "" : 'Sex = $sex\n';
    return string;
  }
}
