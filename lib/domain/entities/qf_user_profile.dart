import 'package:equatable/equatable.dart';

/// User profile decoded from Quran.Foundation ID token.
class QfUserProfile extends Equatable {
  final String userId;
  final String? email;
  final String? firstName;
  final String? lastName;

  String get displayName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    if (firstName != null) return firstName!;
    if (lastName != null) return lastName!;
    if (email != null) return email!;
    return userId;
  }

  String get initials {
    final parts = <String>[];
    if (firstName != null && firstName!.isNotEmpty) {
      parts.add(firstName![0].toUpperCase());
    }
    if (lastName != null && lastName!.isNotEmpty) {
      parts.add(lastName![0].toUpperCase());
    }
    if (parts.isEmpty && email != null && email!.isNotEmpty) {
      parts.add(email![0].toUpperCase());
    }
    if (parts.isEmpty) {
      return userId.isNotEmpty ? userId[0].toUpperCase() : '?';
    }
    return parts.join();
  }

  const QfUserProfile({
    required this.userId,
    this.email,
    this.firstName,
    this.lastName,
  });

  factory QfUserProfile.fromIdTokenClaims(Map<String, dynamic> claims) {
    return QfUserProfile(
      userId: claims['sub']?.toString() ?? '',
      email: claims['email']?.toString(),
      firstName: claims['first_name']?.toString(),
      lastName: claims['last_name']?.toString(),
    );
  }

  @override
  List<Object?> get props => [userId, email, firstName, lastName];
}
