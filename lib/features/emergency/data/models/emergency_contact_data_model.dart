// To parse this JSON data, do
//
//     final emergencyContactDataModel = emergencyContactDataModelFromJson(jsonString);

import 'dart:convert';

EmergencyContactDataModel emergencyContactDataModelFromJson(String str) => EmergencyContactDataModel.fromJson(json.decode(str));

String emergencyContactDataModelToJson(EmergencyContactDataModel data) => json.encode(data.toJson());

class EmergencyContactDataModel {
    bool? success;
    EmergencyContactData? data;

    EmergencyContactDataModel({
        this.success,
        this.data,
    });

    factory EmergencyContactDataModel.fromJson(Map<String, dynamic> json) => EmergencyContactDataModel(
        success: json["success"],
        data: json["data"] == null ? null : EmergencyContactData.fromJson(json["data"]),
    );

    Map<String, dynamic> toJson() => {
        "success": success,
        "data": data?.toJson(),
    };
}

class EmergencyContactData {
    String? id;
    String? userId;
    int? v;
    String? address;
    String? contactName;
    DateTime? createdAt;
    String? email;
    dynamic emailOtp;
    bool? isEmailVerified;
    bool? isPhoneVerified;
    dynamic otpExpiry;
    String? phone;
    dynamic phoneOtp;
    String? relation;
    DateTime? updatedAt;

    EmergencyContactData({
        this.id,
        this.userId,
        this.v,
        this.address,
        this.contactName,
        this.createdAt,
        this.email,
        this.emailOtp,
        this.isEmailVerified,
        this.isPhoneVerified,
        this.otpExpiry,
        this.phone,
        this.phoneOtp,
        this.relation,
        this.updatedAt,
    });

    factory EmergencyContactData.fromJson(Map<String, dynamic> json) => EmergencyContactData(
        id: json["_id"],
        userId: json["userId"],
        v: json["__v"],
        address: json["address"],
        contactName: json["contact_name"],
        createdAt: json["createdAt"] == null ? null : DateTime.parse(json["createdAt"]),
        email: json["email"],
        emailOtp: json["email_otp"],
        isEmailVerified: json["is_email_verified"],
        isPhoneVerified: json["is_phone_verified"],
        otpExpiry: json["otp_expiry"],
        phone: json["phone"],
        phoneOtp: json["phone_otp"],
        relation: json["relation"],
        updatedAt: json["updatedAt"] == null ? null : DateTime.parse(json["updatedAt"]),
    );

    Map<String, dynamic> toJson() => {
        "_id": id,
        "userId": userId,
        "__v": v,
        "address": address,
        "contact_name": contactName,
        "createdAt": createdAt?.toIso8601String(),
        "email": email,
        "email_otp": emailOtp,
        "is_email_verified": isEmailVerified,
        "is_phone_verified": isPhoneVerified,
        "otp_expiry": otpExpiry,
        "phone": phone,
        "phone_otp": phoneOtp,
        "relation": relation,
        "updatedAt": updatedAt?.toIso8601String(),
    };
}
