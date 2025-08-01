class UserData {
  final String? id;
  final String? username;
  final String? accessToken;
  final String? refreshToken;
  final String? expiryDate;
  final bool? confirmed;

  UserData({
    this.id,
    this.username,
    this.accessToken,
    this.refreshToken,
    this.expiryDate,
    this.confirmed,
  });

  UserData copyWith({
    String? id,
    String? username,
    String? accessToken,
    String? refreshToken,
    String? expiryDate,
    bool? confirmed,
  }) {
    return UserData(
      id: id ?? this.id,
      username: username ?? this.username,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiryDate: expiryDate ?? this.expiryDate,
      confirmed: confirmed ?? this.confirmed,
    );
  }
}
