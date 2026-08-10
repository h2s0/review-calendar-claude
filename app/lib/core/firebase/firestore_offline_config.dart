import 'package:cloud_firestore/cloud_firestore.dart';

void configureFirestoreOffline(FirebaseFirestore firestore) {
  firestore.settings = const Settings(
    persistenceEnabled: true,
    webPersistentTabManager: WebPersistentMultipleTabManager(),
  );
}
