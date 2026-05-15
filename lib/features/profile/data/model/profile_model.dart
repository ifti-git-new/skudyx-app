// To parse this JSON data, do
//
//     final profileModel = profileModelFromJson(jsonString);

import 'dart:convert';

ProfileModel profileModelFromJson(String str) => ProfileModel.fromJson(json.decode(str));

String profileModelToJson(ProfileModel data) => json.encode(data.toJson());

class ProfileModel {
    bool? success;
    String? message;
    int? completionPercentage;
    ProfileData? data;

    ProfileModel({
        this.success,
        this.message,
        this.completionPercentage,
        this.data,
    });

    factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
        success: json["success"],
        message: json["message"],
        completionPercentage: json["completion_percentage"],
        data: json["data"] == null ? null : ProfileData.fromJson(json["data"]),
    );

    Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
        "completion_percentage": completionPercentage,
        "data": data?.toJson(),
    };
}

class ProfileData {
    Location? location;
    dynamic lockUntil;
    String? id;
    String? userId;
    String? firstName;
    dynamic middleName;
    String? lastName;
    String? email;
    String? phone;
    dynamic emergencyPhone;
    dynamic address;
    dynamic addressLine2;
    dynamic city;
    dynamic state;
    dynamic zipPostalCode;
    dynamic country;
    dynamic profilePhoto;
    dynamic dateOfBirth;
    String? cardType;
    dynamic cardNumber;
    dynamic cardPhoto;
    dynamic cardFirstName;
    dynamic cardLastName;
    dynamic cardAddress;
    dynamic cardDateOfBirth;
    dynamic cardIssueDate;
    dynamic cardExpiryDate;
    
    bool? isTest;
    String? identityStatus;
    bool? isCardVerified;
    dynamic bleDeviceId;
    bool? bleDeviceStatus;
    String? role;
    String? accountStatus;
    String? availabilityStatus;
    String? subscriptionPlan;
    String? subscriptionStatus;
    DateTime? subscriptionUpdatedAt;
    dynamic currentDeviceId;
    List<dynamic>? deviceHistory;
    bool? isVerified;
    bool? emailVerified;
    bool? phoneVerified;
    dynamic fcmToken;
    dynamic platform;
    String? orderStatus;
    int? loginAttempts;
    bool? isDeleted;
    dynamic lastProfileReminderSent;
    int? profileReminderCount;
    List<dynamic>? statusUpdateLogs;
    List<dynamic>? subscriptionHistory;
    DateTime? createdAt;
    DateTime? updatedAt;
    int? v;

    ProfileData({
        this.location,
        this.lockUntil,
        this.id,
        this.userId,
        this.firstName,
        this.middleName,
        this.lastName,
        this.email,
        this.phone,
        this.emergencyPhone,
        this.address,
        this.addressLine2,
        this.city,
        this.state,
        this.zipPostalCode,
        this.country,
        this.profilePhoto,
        this.dateOfBirth,
        this.cardType,
        this.cardNumber,
        this.cardPhoto,
        this.cardFirstName,
        this.cardLastName,
        this.cardAddress,
        this.cardDateOfBirth,
        this.cardIssueDate,
        this.cardExpiryDate,
        this.isTest,
        this.identityStatus,
        this.isCardVerified,
        this.bleDeviceId,
        this.bleDeviceStatus,
        this.role,
        this.accountStatus,
        this.availabilityStatus,
        this.subscriptionPlan,
        this.subscriptionStatus,
        this.subscriptionUpdatedAt,
        this.currentDeviceId,
        this.deviceHistory,
        this.isVerified,
        this.emailVerified,
        this.phoneVerified,
        this.fcmToken,
        this.platform,
        this.orderStatus,
        this.loginAttempts,
        this.isDeleted,
        this.lastProfileReminderSent,
        this.profileReminderCount,
        this.statusUpdateLogs,
        this.subscriptionHistory,
        this.createdAt,
        this.updatedAt,
        this.v,
    });

    factory ProfileData.fromJson(Map<String, dynamic> json) => ProfileData(
        location: json["location"] == null ? null : Location.fromJson(json["location"]),
        lockUntil: json["lockUntil"],
        id: json["_id"],
        userId: json["user_id"],
        firstName: json["first_name"],
        middleName: json["middle_name"],
        lastName: json["last_name"],
        email: json["email"],
        phone: json["phone"],
        emergencyPhone: json["emergency_phone"],
        address: json["address"],
        addressLine2: json["address_line_2"],
        city: json["city"],
        state: json["state"],
        zipPostalCode: json["zip_postal_code"],
        country: json["country"],
        profilePhoto: json["profile_photo"],
        dateOfBirth: json["date_of_birth"],
        cardType: json["card_type"],
        cardNumber: json["card_number"],
        cardPhoto: json["card_photo"],
        cardFirstName: json["card_first_name"],
        cardLastName: json["card_last_name"],
        cardAddress: json["card_address"],
        cardDateOfBirth: json["card_date_of_birth"],
        cardIssueDate: json["card_issue_date"],
        cardExpiryDate: json["card_expiry_date"],
        isTest: json["is_test"],
        identityStatus: json["identityStatus"],
        isCardVerified: json["isCardVerified"],
        bleDeviceId: json["ble_device_id"],
        bleDeviceStatus: json["ble_device_status"],
        role: json["role"],
        accountStatus: json["account_status"],
        availabilityStatus: json["availability_status"],
        subscriptionPlan: json["subscriptionPlan"],
        subscriptionStatus: json["subscriptionStatus"],
        subscriptionUpdatedAt: json["subscriptionUpdatedAt"] == null ? null : DateTime.parse(json["subscriptionUpdatedAt"]),
        currentDeviceId: json["currentDeviceId"],
        deviceHistory: json["deviceHistory"] == null ? [] : List<dynamic>.from(json["deviceHistory"]!.map((x) => x)),
        isVerified: json["isVerified"],
        emailVerified: json["emailVerified"],
        phoneVerified: json["phoneVerified"],
        fcmToken: json["fcm_token"],
        platform: json["platform"],
        orderStatus: json["order_status"],
        loginAttempts: json["loginAttempts"],
        isDeleted: json["isDeleted"],
        lastProfileReminderSent: json["lastProfileReminderSent"],
        profileReminderCount: json["profileReminderCount"],
        statusUpdateLogs: json["statusUpdateLogs"] == null ? [] : List<dynamic>.from(json["statusUpdateLogs"]!.map((x) => x)),
        subscriptionHistory: json["subscriptionHistory"] == null ? [] : List<dynamic>.from(json["subscriptionHistory"]!.map((x) => x)),
        createdAt: json["createdAt"] == null ? null : DateTime.parse(json["createdAt"]),
        updatedAt: json["updatedAt"] == null ? null : DateTime.parse(json["updatedAt"]),
        v: json["__v"],
    );

    Map<String, dynamic> toJson() => {
        "location": location?.toJson(),
        "lockUntil": lockUntil,
        "_id": id,
        "user_id": userId,
        "first_name": firstName,
        "middle_name": middleName,
        "last_name": lastName,
        "email": email,
        "phone": phone,
        "emergency_phone": emergencyPhone,
        "address": address,
        "address_line_2": addressLine2,
        "city": city,
        "state": state,
        "zip_postal_code": zipPostalCode,
        "country": country,
        "profile_photo": profilePhoto,
        "date_of_birth": dateOfBirth,
        "card_type": cardType,
        "card_number": cardNumber,
        "card_photo": cardPhoto,
        "card_first_name": cardFirstName,
        "card_last_name": cardLastName,
        "card_address": cardAddress,
        "card_date_of_birth": cardDateOfBirth,
        "card_issue_date": cardIssueDate,
        "card_expiry_date": cardExpiryDate,
        "is_test": isTest,
        "identityStatus": identityStatus,
        "isCardVerified": isCardVerified,
        "ble_device_id": bleDeviceId,
        "ble_device_status": bleDeviceStatus,
        "role": role,
        "account_status": accountStatus,
        "availability_status": availabilityStatus,
        "subscriptionPlan": subscriptionPlan,
        "subscriptionStatus": subscriptionStatus,
        "subscriptionUpdatedAt": subscriptionUpdatedAt?.toIso8601String(),
        "currentDeviceId": currentDeviceId,
        "deviceHistory": deviceHistory == null ? [] : List<dynamic>.from(deviceHistory!.map((x) => x)),
        "isVerified": isVerified,
        "emailVerified": emailVerified,
        "phoneVerified": phoneVerified,
        "fcm_token": fcmToken,
        "platform": platform,
        "order_status": orderStatus,
        "loginAttempts": loginAttempts,
        "isDeleted": isDeleted,
        "lastProfileReminderSent": lastProfileReminderSent,
        "profileReminderCount": profileReminderCount,
        "statusUpdateLogs": statusUpdateLogs == null ? [] : List<dynamic>.from(statusUpdateLogs!.map((x) => x)),
        "subscriptionHistory": subscriptionHistory == null ? [] : List<dynamic>.from(subscriptionHistory!.map((x) => x)),
        "createdAt": createdAt?.toIso8601String(),
        "updatedAt": updatedAt?.toIso8601String(),
        "__v": v,
    };
}

class Location {
    String? type;
    List<int>? coordinates;

    Location({
        this.type,
        this.coordinates,
    });

    factory Location.fromJson(Map<String, dynamic> json) => Location(
        type: json["type"],
        coordinates: json["coordinates"] == null ? [] : List<int>.from(json["coordinates"]!.map((x) => x)),
    );

    Map<String, dynamic> toJson() => {
        "type": type,
        "coordinates": coordinates == null ? [] : List<dynamic>.from(coordinates!.map((x) => x)),
    };
}
