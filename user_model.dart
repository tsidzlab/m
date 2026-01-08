import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class User {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String? companyName;
  final String? companyLogo;
  final String? address;
  final String? wilaya;
  final String? municipality;
  final String? taxNumber;
  final int maxUsers;
  final DateTime? subscriptionExpires;
  final String planStatus;
  
  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.companyName,
    this.companyLogo,
    this.address,
    this.wilaya,
    this.municipality,
    this.taxNumber,
    this.maxUsers = 1,
    this.subscriptionExpires,
    this.planStatus = 'Active',
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? companyName,
    String? companyLogo,
    String? address,
    String? wilaya,
    String? municipality,
    String? taxNumber,
    int? maxUsers,
    DateTime? subscriptionExpires,
    String? planStatus,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      companyName: companyName ?? this.companyName,
      companyLogo: companyLogo ?? this.companyLogo,
      address: address ?? this.address,
      wilaya: wilaya ?? this.wilaya,
      municipality: municipality ?? this.municipality,
      taxNumber: taxNumber ?? this.taxNumber,
      maxUsers: maxUsers ?? this.maxUsers,
      subscriptionExpires: subscriptionExpires ?? this.subscriptionExpires,
      planStatus: planStatus ?? this.planStatus,
    );
  }

  bool get isSubscriptionActive {
    if (planStatus != 'Active') return false;
    if (subscriptionExpires == null) return false;
    return subscriptionExpires!.isAfter(DateTime.now());
  }

  int get daysUntilExpiry {
    if (subscriptionExpires == null) return -1;
    return subscriptionExpires!.difference(DateTime.now()).inDays;
  }
}

@JsonSerializable()
class AuthResponse {
  final bool success;
  final String message;
  final String? token;
  final User? user;

  AuthResponse({
    required this.success,
    required this.message,
    this.token,
    this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}

@JsonSerializable()
class LoginRequest {
  final String email;
  final String password;
  final String deviceId;
  final String deviceName;
  final String deviceType;
  final String appVersion;
  final String? osVersion;
  final String? deviceModel;
  final String? fcmToken;

  LoginRequest({
    required this.email,
    required this.password,
    required this.deviceId,
    required this.deviceName,
    required this.deviceType,
    required this.appVersion,
    this.osVersion,
    this.deviceModel,
    this.fcmToken,
  });

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);
  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}

@JsonSerializable()
class RegisterRequest {
  final String name;
  final String email;
  final String phone;
  final String password;
  final String passwordConfirm;
  final String licenseKey;
  final String companyName;
  final String? companyLogo;
  final String? address;
  final String? wilaya;
  final String? municipality;
  final String? taxNumber;

  RegisterRequest({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.passwordConfirm,
    required this.licenseKey,
    required this.companyName,
    this.companyLogo,
    this.address,
    this.wilaya,
    this.municipality,
    this.taxNumber,
  });

  factory RegisterRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterRequestFromJson(json);
  Map<String, dynamic> toJson() => _$RegisterRequestToJson(this);
}
