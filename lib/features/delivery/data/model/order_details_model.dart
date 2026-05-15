// To parse this JSON data, do
//
//     final orderDetailsModel = orderDetailsModelFromJson(jsonString);

import 'dart:convert';

OrderDetailsModel orderDetailsModelFromJson(String str) => OrderDetailsModel.fromJson(json.decode(str));

String orderDetailsModelToJson(OrderDetailsModel data) => json.encode(data.toJson());

class OrderDetailsModel {
    bool? success;
    Data? data;

    OrderDetailsModel({
        this.success,
        this.data,
    });

    factory OrderDetailsModel.fromJson(Map<String, dynamic> json) => OrderDetailsModel(
        success: json["success"],
        data: json["data"] == null ? null : Data.fromJson(json["data"]),
    );

    Map<String, dynamic> toJson() => {
        "success": success,
        "data": data?.toJson(),
    };
}

class Data {
    DeliveryAddress? deliveryAddress;
    String? id;
    String? userId;
    String? orderId;
    String? subscriptionPlan;
    String? status;
    List<Timeline>? timeline;
    DateTime? createdAt;
    DateTime? updatedAt;
    int? v;

    Data({
        this.deliveryAddress,
        this.id,
        this.userId,
        this.orderId,
        this.subscriptionPlan,
        this.status,
        this.timeline,
        this.createdAt,
        this.updatedAt,
        this.v,
    });

    factory Data.fromJson(Map<String, dynamic> json) => Data(
        deliveryAddress: json["deliveryAddress"] == null ? null : DeliveryAddress.fromJson(json["deliveryAddress"]),
        id: json["_id"],
        userId: json["userId"],
        orderId: json["orderId"],
        subscriptionPlan: json["subscriptionPlan"],
        status: json["status"],
        timeline: json["timeline"] == null ? [] : List<Timeline>.from(json["timeline"]!.map((x) => Timeline.fromJson(x))),
        createdAt: json["createdAt"] == null ? null : DateTime.parse(json["createdAt"]),
        updatedAt: json["updatedAt"] == null ? null : DateTime.parse(json["updatedAt"]),
        v: json["__v"],
    );

    Map<String, dynamic> toJson() => {
        "deliveryAddress": deliveryAddress?.toJson(),
        "_id": id,
        "userId": userId,
        "orderId": orderId,
        "subscriptionPlan": subscriptionPlan,
        "status": status,
        "timeline": timeline == null ? [] : List<dynamic>.from(timeline!.map((x) => x.toJson())),
        "createdAt": createdAt?.toIso8601String(),
        "updatedAt": updatedAt?.toIso8601String(),
        "__v": v,
    };
}

class DeliveryAddress {
    String? fullName;
    String? phone;
    String? addressLine1;
    String? addressLine2;
    String? city;
    String? state;
    String? zipCode;
    String? country;

    DeliveryAddress({
        this.fullName,
        this.phone,
        this.addressLine1,
        this.addressLine2,
        this.city,
        this.state,
        this.zipCode,
        this.country,
    });

    factory DeliveryAddress.fromJson(Map<String, dynamic> json) => DeliveryAddress(
        fullName: json["fullName"],
        phone: json["phone"],
        addressLine1: json["addressLine1"],
        addressLine2: json["addressLine2"],
        city: json["city"],
        state: json["state"],
        zipCode: json["zipCode"],
        country: json["country"],
    );

    Map<String, dynamic> toJson() => {
        "fullName": fullName,
        "phone": phone,
        "addressLine1": addressLine1,
        "addressLine2": addressLine2,
        "city": city,
        "state": state,
        "zipCode": zipCode,
        "country": country,
    };
}

class Timeline {
    String? status;
    String? message;
    String? id;
    DateTime? timestamp;

    Timeline({
        this.status,
        this.message,
        this.id,
        this.timestamp,
    });

    factory Timeline.fromJson(Map<String, dynamic> json) => Timeline(
        status: json["status"],
        message: json["message"],
        id: json["_id"],
        timestamp: json["timestamp"] == null ? null : DateTime.parse(json["timestamp"]),
    );

    Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "_id": id,
        "timestamp": timestamp?.toIso8601String(),
    };
}
