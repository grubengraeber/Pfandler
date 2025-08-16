import 'package:latlong2/latlong.dart';

class Store {
  final String id;
  final String name;
  final StoreChain chain;
  final LatLng location;
  final String address;
  final String city;
  final String postalCode;
  final List<AcceptedDepositType> acceptedTypes;
  final StoreHours? hours;
  final double? distance; // Distance from user in km
  final bool hasReturnMachine;
  final int? machineCount;
  final String? phoneNumber;
  final String? website;

  Store({
    required this.id,
    required this.name,
    required this.chain,
    required this.location,
    required this.address,
    required this.city,
    required this.postalCode,
    required this.acceptedTypes,
    this.hours,
    this.distance,
    this.hasReturnMachine = true,
    this.machineCount,
    this.phoneNumber,
    this.website,
  });

  String get fullAddress => '$address, $postalCode $city';
  
  bool get isOpen {
    if (hours == null) return false;
    final now = DateTime.now();
    final todayHours = hours!.getHoursForDay(now.weekday);
    if (todayHours == null) return false;
    
    final currentTime = now.hour * 60 + now.minute;
    return currentTime >= todayHours.openTime && currentTime <= todayHours.closeTime;
  }

  String get acceptedTypesLabel {
    return acceptedTypes.map((t) => t.label).join(', ');
  }
}

enum StoreChain {
  spar,
  billa,
  billaPlus,
  hofer,
  lidl,
  penny,
  merkur,
  mpreis,
  eurospar,
  interspar,
  other,
}

extension StoreChainExtension on StoreChain {
  String get name {
    switch (this) {
      case StoreChain.spar:
        return 'SPAR';
      case StoreChain.billa:
        return 'Billa';
      case StoreChain.billaPlus:
        return 'Billa Plus';
      case StoreChain.hofer:
        return 'Hofer';
      case StoreChain.lidl:
        return 'Lidl';
      case StoreChain.penny:
        return 'Penny';
      case StoreChain.merkur:
        return 'Merkur';
      case StoreChain.mpreis:
        return 'MPreis';
      case StoreChain.eurospar:
        return 'EUROSPAR';
      case StoreChain.interspar:
        return 'INTERSPAR';
      case StoreChain.other:
        return 'Other';
    }
  }

  String get logoAsset {
    return 'assets/logos/${name.toLowerCase()}.png';
  }
}

enum AcceptedDepositType {
  plastic025,
  plastic05,
  plastic1,
  plastic15,
  glass,
  can,
  crate,
}

extension AcceptedDepositTypeExtension on AcceptedDepositType {
  String get label {
    switch (this) {
      case AcceptedDepositType.plastic025:
        return 'Plastic 0.25L';
      case AcceptedDepositType.plastic05:
        return 'Plastic 0.5L';
      case AcceptedDepositType.plastic1:
        return 'Plastic 1L';
      case AcceptedDepositType.plastic15:
        return 'Plastic 1.5L';
      case AcceptedDepositType.glass:
        return 'Glass';
      case AcceptedDepositType.can:
        return 'Cans';
      case AcceptedDepositType.crate:
        return 'Crates';
    }
  }

  double get depositAmount {
    switch (this) {
      case AcceptedDepositType.plastic025:
      case AcceptedDepositType.plastic05:
      case AcceptedDepositType.plastic1:
      case AcceptedDepositType.plastic15:
        return 0.25;
      case AcceptedDepositType.glass:
        return 0.09;
      case AcceptedDepositType.can:
        return 0.25;
      case AcceptedDepositType.crate:
        return 3.00;
    }
  }
}

class StoreHours {
  final Map<int, DayHours> schedule;

  StoreHours({required this.schedule});

  DayHours? getHoursForDay(int weekday) => schedule[weekday];
}

class DayHours {
  final int openTime; // Minutes from midnight
  final int closeTime; // Minutes from midnight
  final bool isClosed;

  DayHours({
    required this.openTime,
    required this.closeTime,
    this.isClosed = false,
  });

  String get formattedHours {
    if (isClosed) return 'Closed';
    final openHour = openTime ~/ 60;
    final openMin = openTime % 60;
    final closeHour = closeTime ~/ 60;
    final closeMin = closeTime % 60;
    return '${openHour.toString().padLeft(2, '0')}:${openMin.toString().padLeft(2, '0')} - ${closeHour.toString().padLeft(2, '0')}:${closeMin.toString().padLeft(2, '0')}';
  }
}