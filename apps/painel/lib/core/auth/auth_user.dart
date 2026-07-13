enum UserRole { admin, partner, support }

extension UserRoleX on UserRole {
  String get label {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.partner:
        return 'Partner';
      case UserRole.support:
        return 'Support';
    }
  }

  String get landingRoute {
    switch (this) {
      case UserRole.admin:
        return '/admin/dashboard';
      case UserRole.partner:
        return '/partner/dashboard';
      case UserRole.support:
        return '/support';
    }
  }

  String get rootPathPrefix {
    switch (this) {
      case UserRole.admin:
        return '/admin';
      case UserRole.partner:
        return '/partner';
      case UserRole.support:
        return '/support';
    }
  }
}

class AuthUser {
  const AuthUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.partnerId,
    this.avatarUrl,
  });

  final String uid;
  final String email;
  final String name;
  final UserRole role;
  final String? partnerId;
  final String? avatarUrl;

  AuthUser copyWith({String? name, String? avatarUrl}) {
    return AuthUser(
      uid: uid,
      email: email,
      name: name ?? this.name,
      role: role,
      partnerId: partnerId,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
