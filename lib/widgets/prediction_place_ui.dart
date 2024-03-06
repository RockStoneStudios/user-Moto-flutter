import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:userapp/global/global_var.dart';
import 'package:userapp/models/prediction_model.dart';
import 'package:userapp/models/address_model.dart';
import 'package:userapp/appInfo/app_info.dart';
import 'package:userapp/methods/common_methods.dart';
import 'package:userapp/widgets/loading_dialogs.dart';

class PredictionPlaceUI extends StatefulWidget {
  final PredictionModel? predictedPlaceData;

  PredictionPlaceUI({Key? key, this.predictedPlaceData}) : super(key: key);

  @override
  State<PredictionPlaceUI> createState() => _PredictionPlaceUIState();
}

class _PredictionPlaceUIState extends State<PredictionPlaceUI> {
  void fetchClickedPlaceDetails(String placeID) async {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) => LoadingDialog(messageText: "Obteniendo detalles..."),
    );

    if (placeID.startsWith("custom-")) {
      String coordinates = placeID.replaceFirst("custom-", "");
      List<String> latLng = coordinates.split(",");
      double latitude = double.parse(latLng[0]);
      double longitude = double.parse(latLng[1]);

      AddressModel dropOffLocation = AddressModel(
        placeName: widget.predictedPlaceData?.main_text ?? "Ubicación personalizada",
        latitudePosition: latitude,
        longitudePosition: longitude,
        placeID: placeID,
      );

      Provider.of<AppInfo>(context, listen: false).updateDropOffLocation(dropOffLocation);
      Navigator.pop(context); // Cierra el diálogo de carga
      Navigator.pop(context, "placeSelected");
    } else {
      String urlPlaceDetailsAPI = "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeID&key=$googleMapKey";
      var responseFromPlaceDetailsAPI = await CommonMethods.sendRequestToAPI(urlPlaceDetailsAPI);

      Navigator.pop(context); // Cierra el diálogo de carga

      if (responseFromPlaceDetailsAPI != "error" && responseFromPlaceDetailsAPI["status"] == "OK") {
        var result = responseFromPlaceDetailsAPI["result"];
        AddressModel dropOffLocation = AddressModel(
          placeName: result["name"] ?? "Nombre no disponible",
          latitudePosition: result["geometry"]["location"]["lat"],
          longitudePosition: result["geometry"]["location"]["lng"],
          placeID: placeID,
        );

        Provider.of<AppInfo>(context, listen: false).updateDropOffLocation(dropOffLocation);
        Navigator.pop(context, "placeSelected");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => fetchClickedPlaceDetails(widget.predictedPlaceData?.place_id ?? ""),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Icon(Icons.location_on, color: Colors.grey),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.predictedPlaceData?.main_text ?? "Desconocido",
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    widget.predictedPlaceData?.secondary_text ?? "No hay información adicional",
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}