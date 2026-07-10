import 'package:flutter/foundation.dart';

/// A user account. Free of any persistence / serialization concerns —
/// those live in the data layer.
@immutable
class User {
  const User({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.createdAt,
  });

  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final DateTime? createdAt;

  User copyWith({
    String? displayName,
    String? photoUrl,
  }) {
    return User(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          id == other.id &&
          email == other.email &&
          displayName == other.displayName &&
          photoUrl == other.photoUrl;

  @override
  int get hashCode => Object.hash(id, email, displayName, photoUrl);
}
