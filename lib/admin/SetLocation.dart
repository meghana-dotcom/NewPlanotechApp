import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:planotech/baseurl.dart';

class SetLocation extends StatefulWidget {
  const SetLocation({super.key});

  @override
  State<SetLocation> createState() => _SetLocationState();
}

class _SetLocationState extends State<SetLocation> {
  String? _latitude;
  String? _longitude;
  String? _address;
  String? _currentDate;
  String? _currentDay;
  String? _currentTime;
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _isFetching = false;
  String? _deletingId;
  List<Map<String, dynamic>> _locations = [];

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnackbar("Please enable location services");
      setState(() => _isLoading = false);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackbar("Location permission denied");
        setState(() => _isLoading = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showSnackbar("Location permission permanently denied");
      setState(() => _isLoading = false);
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    DateTime now = DateTime.now();
    _currentDate = DateFormat('dd-MM-yyyy').format(now);
    _currentDay = DateFormat('EEEE').format(now);
    _currentTime = DateFormat('hh:mm a').format(now);

    setState(() {
      _latitude = position.latitude.toString();
      _longitude = position.longitude.toString();
      _address = "Fetching address...";
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      Placemark place = placemarks.first;

      setState(() {
        _address =
            "${place.street}, ${place.locality}, ${place.postalCode}, ${place.country}";
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _address = "Address not found";
        _isLoading = false;
      });
    }
  }

  Future<void> _submitLocation() async {
    bool confirm = await _showConfirmationDialog(
        "Confirm Submission", "Are you sure you want to submit this location?");
    if (!confirm) return;

    setState(() => _isSubmitting = true);

    try {
      var response = await http.post(
        Uri.parse(baseurl + "/admin/addlocation"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "date": _currentDate!,
          "time": _currentTime!,
          "day": _currentDay!,
          "latitude": "$_latitude",
          "longitude": "$_longitude",
          "address": _address!,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackbar("Location submitted successfully!", Colors.green);

        // Clear input fields after submission
        setState(() {
          _latitude = null;
          _longitude = null;
          _address = null;
          _currentDate = null;
          _currentDay = null;
          _currentTime = null;
        });

        _fetchAllLocations();
      } else {
        _showSnackbar("Error: ${response.body}", Colors.red);
      }
    } catch (e) {
      _showSnackbar("Network Error: ${e.toString()}", Colors.red);
    }

    setState(() => _isSubmitting = false);
  }

  Future<void> _fetchAllLocations() async {
    setState(() => _isFetching = true);
    try {
      var response =
          await http.get(Uri.parse(baseurl + "/admin/fetchalllocation"));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        print('*');
        print(data);
        if (data["status"] == true) {
          setState(() =>
              _locations = List<Map<String, dynamic>>.from(data["userList"]));
        }
      }
    } catch (_) {
      _showSnackbar("Failed to fetch locations", Colors.red);
    }
    setState(() => _isFetching = false);
  }

  Future<void> _deleteLocation(String locationId) async {
    bool confirm = await _showConfirmationDialog(
        "Confirm Deletion", "Are you sure you want to delete this location?");
    if (!confirm) return;

    setState(() => _deletingId = locationId);

    try {
      var response = await http.post(
          Uri.parse(baseurl + "/admin/deletelocationbyid?id=$locationId"));
      if (response.statusCode == 200) {
        _showSnackbar("Location deleted successfully!", Colors.green);
        _fetchAllLocations();
      } else {
        _showSnackbar("Error deleting location", Colors.red);
      }
    } catch (_) {
      _showSnackbar("Network Error", Colors.red);
    }
    setState(() => _deletingId = null);
  }

  Future<bool> _showConfirmationDialog(String title, String message) async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Cancel")),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("Confirm")),
            ],
          ),
        ) ??
        false;
  }

  void _showSnackbar(String message, [Color color = Colors.black]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchAllLocations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Set Location',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 214, 190, 124),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color.fromARGB(255, 214, 190, 124),
              const Color.fromARGB(255, 136, 138, 138)
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Lottie.asset('assets/map.json', width: 150, height: 150),
              // "Get Location" button
              ElevatedButton.icon(
                onPressed: _getCurrentLocation,
                icon: const Icon(Icons.my_location, color: Colors.black),
                label: const Text("Get Location",
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 178, 182, 164),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 2),
              _isLoading
                  ? const CircularProgressIndicator()
                  : _latitude != null && _longitude != null
                      ? _buildLocationCard()
                      : const SizedBox(),

              const SizedBox(height: 2),
              if (_latitude != null && _longitude != null)
                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitLocation,
                  icon: const Icon(Icons.send, color: Colors.black),
                  label: _isSubmitting
                      ? const CircularProgressIndicator()
                      : const Text("Submit",
                          style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 178, 182, 164),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),

              const SizedBox(height: 20),

              Expanded(
                child: _isFetching
                    ? const Center(child: CircularProgressIndicator())
                    : _locations.isEmpty
                        ? Center(
                            child: Lottie.asset('assets/empty.json',
                                width: 400, height: 400))
                        : ListView.builder(
                            itemCount: _locations.length,
                            itemBuilder: (context, index) {
                              var loc = _locations[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  leading: Icon(Icons.location_on,
                                      color: Colors.green[300]),
                                  title: Text(
                                    loc["address"],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Lattitude : ${loc["latitude"]}",
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      Text(
                                        "Longitude : ${loc["longitude"]}",
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      Text(
                                          "${loc["day"]} - ${loc["date"]} at ${loc["time"]}"),
                                    ],
                                  ),
                                  trailing: _deletingId == loc["id"]
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        )
                                      : IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () => _deleteLocation(
                                              loc["id"].toString()),
                                        ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 3,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.blueGrey.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.location_on, color: Colors.blueAccent, size: 28),
              SizedBox(width: 8),
              Text(
                "Current Location",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const Divider(thickness: 1.2, color: Colors.blueGrey),
          const SizedBox(height: 10),
          _buildKeyValuePair("Latitude       :", _latitude!),
          _buildKeyValuePair("Longitude    :", _longitude!),
          _buildKeyValuePair("Address       :", _address!),
          _buildKeyValuePair("Date             :", _currentDate!),
          _buildKeyValuePair("Time            :", _currentTime!),
          _buildKeyValuePair("Day               :", _currentDay!),
        ],
      ),
    );
  }

  Widget _buildKeyValuePair(String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              key,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
