class UserProfile {
  const UserProfile({
    required this.id,
    required this.phone,
    required this.firstName,
    required this.lastName,
    required this.address,
    required this.birthDate,
    required this.referralCode,
    required this.personalTurnover,
    required this.teamTurnover,
    required this.bonusBalance,
  });

  final String id;
  final String phone;
  final String firstName;
  final String lastName;
  final String address;
  final String? birthDate;
  final String referralCode;
  final String personalTurnover;
  final String teamTurnover;
  final String bonusBalance;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: (json['id'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      firstName: (json['first_name'] ?? '').toString(),
      lastName: (json['last_name'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      birthDate: json['birth_date']?.toString(),
      referralCode: (json['referral_code'] ?? '').toString(),
      personalTurnover: (json['personal_turnover'] ?? '0.00').toString(),
      teamTurnover: (json['team_turnover'] ?? '0.00').toString(),
      bonusBalance: (json['bonus_balance'] ?? '0.00').toString(),
    );
  }
}

class AuthState {
  const AuthState({
    this.accessToken,
    this.refreshToken,
    this.profile,
  });

  final String? accessToken;
  final String? refreshToken;
  final UserProfile? profile;

  bool get isAuthenticated =>
      accessToken != null && accessToken!.isNotEmpty;

  AuthState copyWith({
    String? accessToken,
    String? refreshToken,
    UserProfile? profile,
    bool clearProfile = false,
  }) {
    return AuthState(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      profile: clearProfile ? null : (profile ?? this.profile),
    );
  }
}
