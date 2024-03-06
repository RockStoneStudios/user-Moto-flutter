import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:userapp/global/global_var.dart';
import 'package:userapp/methods/common_methods.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

import '../appInfo/app_info.dart';
import '../models/prediction_model.dart';
import '../widgets/prediction_place_ui.dart';
import 'package:geocoding/geocoding.dart' as geocoding;

class SearchDestinationPage extends StatefulWidget {
  const SearchDestinationPage({super.key});

  @override
  State<SearchDestinationPage> createState() => _SearchDestinationPageState();
}

class _SearchDestinationPageState extends State<SearchDestinationPage> {
  TextEditingController pickUpTextEditingController = TextEditingController();
  TextEditingController destinationTextEditingController = TextEditingController();
  List<PredictionModel> dropOffPredictionsPlacesList = [];

  GoogleMapController? mapController;
  LatLng? selectedLocation;
  Set<Marker> markers = {};
  Location location = Location();

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  void _getUserLocation() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    var _userLocation = await location.getLocation();
    mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(_userLocation.latitude!, _userLocation.longitude!),
          zoom: 14.0,
        ),
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _getUserLocation();
  }

  void _handleTap(LatLng tappedPoint) async {
    setState(() {
      selectedLocation = tappedPoint;
      markers.clear();
      markers.add(
        Marker(
          markerId: MarkerId(tappedPoint.toString()),
          position: tappedPoint,
          infoWindow: InfoWindow(
            title: 'Ubicación Seleccionada',
          ),
        ),
      );
    });

    try {
      List<geocoding.Placemark> placemarks = await geocoding.placemarkFromCoordinates(tappedPoint.latitude, tappedPoint.longitude);
      if (placemarks.isNotEmpty) {
        geocoding.Placemark place = placemarks.first;
        String address = "${place.street}, ${place.locality}, ${place.country}";
        setState(() {
          destinationTextEditingController.text = address;
          // Crea una instancia de PredictionModel para la dirección seleccionada manualmente
          PredictionModel manualLocation = PredictionModel(
            place_id: "custom-${tappedPoint.latitude},${tappedPoint.longitude}",
            main_text: address,  // O cualquier otra descripción que prefieras
            secondary_text: "Ubicación seleccionada manualmente",
          );
          dropOffPredictionsPlacesList = [manualLocation];  // Agrega esta ubicación personalizada a la lista de predicciones
        });
      }
    } catch (e) {
      print("Error al realizar la geocodificación inversa: $e");
    }
  }

  void searchLocation(String locationName) async {
    if (locationName.length > 1) {
      String apiPlacesUrl = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$locationName&key=$googleMapKey&components=country:CO";
      var responseFromPlacesApi = await CommonMethods.sendRequestToAPI(apiPlacesUrl);

      if (responseFromPlacesApi == "error") {
        return;
      }
      if (responseFromPlacesApi["status"] == "OK") {
        var predictionResultInJson = responseFromPlacesApi["predictions"];
        var predictionsList = (predictionResultInJson as List)
            .map((eachPlacePrediction) => PredictionModel.fromJson(eachPlacePrediction))
            .toList();

        setState(() {
          dropOffPredictionsPlacesList = predictionsList.isEmpty ? dropOffPredictionsPlacesList : predictionsList;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String userAddress = Provider
        .of<AppInfo>(context, listen: false)
        .pickUpLocation
        ?.humanReadableAddress ?? "";

    pickUpTextEditingController.text = userAddress;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Card(
              elevation: 10,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black38,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 5.0,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 24, top: 48, right: 24, bottom: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 6),
                      Stack(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                          const Center(
                            child: Text(
                              "Set Dropoff Location",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Image.asset(
                            "assets/images/initial.png",
                            height: 16,
                            width: 16,
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(3),
                                child: TextField(
                                  controller: pickUpTextEditingController,
                                  decoration: const InputDecoration(
                                      hintText: "Direccion de Recogida",
                                      fillColor: Colors.white12,
                                      filled: true,
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.only(left: 11, top: 9, bottom: 9)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 11),
                      Row(
                        children: [
                          Image.asset(
                            "assets/images/final.png",
                            height: 16,
                            width: 16,
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(3),
                                child: TextField(
                                  controller: destinationTextEditingController,
                                  onChanged: (inputText) {
                                    searchLocation(inputText);
                                  },
                                  decoration: const InputDecoration(
                                      hintText: "Direccion Destino",
                                      fillColor: Colors.white12,
                                      filled: true,
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.only(left: 11, top: 9, bottom: 9)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            (dropOffPredictionsPlacesList.length > 0)
                ? Padding(
              padding:
              const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: ListView.separated(
                padding: const EdgeInsets.all(0),
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 3,
                    child: PredictionPlaceUI(
                      predictedPlaceData:
                      dropOffPredictionsPlacesList[index],
                    ),
                  );
                },
                separatorBuilder: (BuildContext context, int index) =>
                const SizedBox(
                  height: 2,
                ),
                itemCount: dropOffPredictionsPlacesList.length,
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
              ),
            )
                : Container(),
            Container(
              height: 600, // Adjust the height as needed
              child: GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: LatLng(0, 0),
                  // This will be overridden in _getUserLocation
                  zoom: 14.0,
                ),
                markers: markers,
                onTap: _handleTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
