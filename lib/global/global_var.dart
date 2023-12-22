import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

String userName = "";
String userPhone = "";
String googleMapKey = "AIzaSyCgKqjnuXCtqB_0_MM_7K-_4Gu3W-pyvOM";
String userID = FirebaseAuth.instance.currentUser!.uid;
String serverKeyFCM =
    "key=AAAAP8rHIZ0:APA91bF-ofuIMzB8kOwO-Pmz-2Tib_7rrpGQLJ7dexUnABcAdUBCVl79HO6xCGuWANcDEInEtQxknGKRDZknZsiB19XtGCSR9zVabFqqUe735iJ7KjSDTNnS6GeL-S8ABTQdxpnWPseY";

const CameraPosition googlePlexInitialPosition = CameraPosition(
  target: LatLng(37.42796133580664, -122.085749655962),
  zoom: 14.4746,
);
