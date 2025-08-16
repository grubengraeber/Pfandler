import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:pfandler/models/store.dart';

void main() {
  group('Store Model Tests', () {
    test('Store creation with all properties', () {
      final location = LatLng(48.2082, 16.3738);
      final hours = StoreHours(
        schedule: {
          1: DayHours(openTime: 420, closeTime: 1260), // 7:00 - 21:00
          2: DayHours(openTime: 420, closeTime: 1260),
          3: DayHours(openTime: 420, closeTime: 1260),
          4: DayHours(openTime: 420, closeTime: 1260),
          5: DayHours(openTime: 420, closeTime: 1320), // 7:00 - 22:00
          6: DayHours(openTime: 420, closeTime: 1200), // 7:00 - 20:00
          7: DayHours(openTime: 0, closeTime: 0, isClosed: true),
        },
      );
      
      final store = Store(
        id: 'store_123',
        name: 'Billa Hauptbahnhof',
        chain: StoreChain.billa,
        location: location,
        address: 'Hauptbahnhof 1',
        city: 'Wien',
        postalCode: '1100',
        acceptedTypes: [
          AcceptedDepositType.plastic025,
          AcceptedDepositType.plastic05,
          AcceptedDepositType.glass,
          AcceptedDepositType.can,
        ],
        hours: hours,
        hasReturnMachine: true,
        machineCount: 2,
        phoneNumber: '+43 1 234567',
        website: 'https://www.billa.at',
        distance: 1.5,
      );

      expect(store.id, 'store_123');
      expect(store.name, 'Billa Hauptbahnhof');
      expect(store.chain, StoreChain.billa);
      expect(store.location.latitude, 48.2082);
      expect(store.location.longitude, 16.3738);
      expect(store.address, 'Hauptbahnhof 1');
      expect(store.city, 'Wien');
      expect(store.postalCode, '1100');
      expect(store.acceptedTypes.length, 4);
      expect(store.hasReturnMachine, true);
      expect(store.machineCount, 2);
      expect(store.phoneNumber, '+43 1 234567');
      expect(store.website, 'https://www.billa.at');
      expect(store.distance, 1.5);
    });

    test('Store full address formatting', () {
      final store = Store(
        id: 'store_456',
        name: 'Test Store',
        chain: StoreChain.spar,
        location: LatLng(48.2, 16.3),
        address: 'Teststraße 123',
        city: 'Graz',
        postalCode: '8010',
        acceptedTypes: [AcceptedDepositType.plastic05],
      );

      expect(store.fullAddress, 'Teststraße 123, 8010 Graz');
    });

    test('Store accepted types label', () {
      final store = Store(
        id: 'store_789',
        name: 'Test Store',
        chain: StoreChain.hofer,
        location: LatLng(48.2, 16.3),
        address: 'Test',
        city: 'Wien',
        postalCode: '1010',
        acceptedTypes: [
          AcceptedDepositType.plastic05,
          AcceptedDepositType.glass,
          AcceptedDepositType.can,
        ],
      );

      expect(store.acceptedTypesLabel, 'Plastic 0.5L, Glass, Cans');
    });

    test('StoreChain enum values and names', () {
      expect(StoreChain.billa.name, 'Billa');
      expect(StoreChain.billaPlus.name, 'Billa Plus');
      expect(StoreChain.spar.name, 'SPAR');
      expect(StoreChain.eurospar.name, 'EUROSPAR');
      expect(StoreChain.interspar.name, 'INTERSPAR');
      expect(StoreChain.hofer.name, 'Hofer');
      expect(StoreChain.lidl.name, 'Lidl');
      expect(StoreChain.penny.name, 'Penny');
      expect(StoreChain.merkur.name, 'Merkur');
      expect(StoreChain.mpreis.name, 'MPreis');
      expect(StoreChain.other.name, 'Other');
    });

    test('AcceptedDepositType enum values and deposit amounts', () {
      expect(AcceptedDepositType.plastic025.depositAmount, 0.25);
      expect(AcceptedDepositType.plastic05.depositAmount, 0.25);
      expect(AcceptedDepositType.plastic1.depositAmount, 0.25);
      expect(AcceptedDepositType.plastic15.depositAmount, 0.25);
      expect(AcceptedDepositType.glass.depositAmount, 0.09);
      expect(AcceptedDepositType.can.depositAmount, 0.25);
      expect(AcceptedDepositType.crate.depositAmount, 3.00);
    });

    test('AcceptedDepositType labels', () {
      expect(AcceptedDepositType.plastic025.label, 'Plastic 0.25L');
      expect(AcceptedDepositType.plastic05.label, 'Plastic 0.5L');
      expect(AcceptedDepositType.plastic1.label, 'Plastic 1L');
      expect(AcceptedDepositType.plastic15.label, 'Plastic 1.5L');
      expect(AcceptedDepositType.glass.label, 'Glass');
      expect(AcceptedDepositType.can.label, 'Cans');
      expect(AcceptedDepositType.crate.label, 'Crates');
    });

    test('DayHours formatting', () {
      final openHours = DayHours(openTime: 480, closeTime: 1200); // 8:00 - 20:00
      expect(openHours.formattedHours, '08:00 - 20:00');
      
      final closedHours = DayHours(openTime: 0, closeTime: 0, isClosed: true);
      expect(closedHours.formattedHours, 'Closed');
      
      final earlyHours = DayHours(openTime: 360, closeTime: 1080); // 6:00 - 18:00
      expect(earlyHours.formattedHours, '06:00 - 18:00');
    });

    test('Store isOpen calculation', () {
      // Note: This test may fail depending on the current time
      // For a proper test, we would need to mock DateTime.now()
      final hours = StoreHours(
        schedule: {
          DateTime.now().weekday: DayHours(openTime: 0, closeTime: 1440), // Open all day
        },
      );
      
      final store = Store(
        id: 'test',
        name: 'Test Store',
        chain: StoreChain.other,
        location: LatLng(48.2, 16.3),
        address: 'Test',
        city: 'Wien',
        postalCode: '1010',
        acceptedTypes: [],
        hours: hours,
      );
      
      expect(store.isOpen, true);
      
      final closedStore = Store(
        id: 'test2',
        name: 'Closed Store',
        chain: StoreChain.other,
        location: LatLng(48.2, 16.3),
        address: 'Test',
        city: 'Wien',
        postalCode: '1010',
        acceptedTypes: [],
        hours: StoreHours(
          schedule: {
            DateTime.now().weekday: DayHours(openTime: 0, closeTime: 0, isClosed: true),
          },
        ),
      );
      
      expect(closedStore.isOpen, false);
    });

    test('Store without hours', () {
      final store = Store(
        id: 'no_hours',
        name: 'No Hours Store',
        chain: StoreChain.other,
        location: LatLng(48.2, 16.3),
        address: 'Test',
        city: 'Wien',
        postalCode: '1010',
        acceptedTypes: [],
        hours: null,
      );
      
      expect(store.isOpen, false);
    });

    test('Store logo asset path', () {
      expect(StoreChain.billa.logoAsset, 'assets/logos/billa.png');
      expect(StoreChain.spar.logoAsset, 'assets/logos/spar.png');
      expect(StoreChain.hofer.logoAsset, 'assets/logos/hofer.png');
    });
  });
}