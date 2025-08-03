class UserData {
  final String? id;
  final String? username;
  final String? accessToken;
  final String? refreshToken;
  final String? expiryDate;
  final bool? confirmed;
  final String? email;

  UserData({
    this.id,
    this.username,
    this.accessToken,
    this.refreshToken,
    this.expiryDate,
    this.confirmed,
    this.email,
  });

  UserData copyWith({
    String? id,
    String? username,
    String? accessToken,
    String? refreshToken,
    String? expiryDate,
    bool? confirmed,
    String? email,
  }) {
    return UserData(
      id: id ?? this.id,
      username: username ?? this.username,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiryDate: expiryDate ?? this.expiryDate,
      confirmed: confirmed ?? this.confirmed,
      email: email ?? this.email,
    );
  }
}
