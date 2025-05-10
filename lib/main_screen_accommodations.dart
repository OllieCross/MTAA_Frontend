import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'search_results_screen.dart';
import 'main.dart';
import 'bottom_navbar.dart';
import 'accommondation_detail.dart';
import 'server_config.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'app_settings.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'offline_sync_repository.dart';
import 'dart:async';

class SyncToast extends StatefulWidget {
  const SyncToast({super.key, required this.child, this.onSynced});
  final Widget child;
  final VoidCallback? onSynced;

  @override
  State<SyncToast> createState() => _SyncToastState();
}

class _SyncToastState extends State<SyncToast> {
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _sub = OfflineSyncRepository.instance.uploadSuccess.listen((draft) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${draft.name}" synced successfully!'),
          duration: const Duration(seconds: 2),
        ),
      );
      widget.onSynced?.call();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class MainScreenAccommodations extends StatefulWidget {
  const MainScreenAccommodations({super.key});

  @override
  State<MainScreenAccommodations> createState() =>
      _MainScreenAccommodationsState();
}

class _MainScreenAccommodationsState extends State<MainScreenAccommodations> {
  final TextEditingController locationController = TextEditingController();
  final TextEditingController guestController = TextEditingController();
  final ValueNotifier<DateTime?> dateFromNotifier = ValueNotifier(null);
  final ValueNotifier<DateTime?> dateToNotifier = ValueNotifier(null);

  final Map<int, Future<Uint8List?>> _imageFutures = {};

  Future<Uint8List?> _cachedFetch(int aid) {
    return _imageFutures.putIfAbsent(aid, () => fetchAccommodationImage(aid));
  }

  List<dynamic> accommodations = [];
  String? jwtToken = globalToken;

  @override
  void initState() {
    super.initState();
    _loadInitialRecommendations();
  }

  Future<void> _loadInitialRecommendations() async {
    jwtToken = globalToken;
    final response = await http.get(
      Uri.parse('http://$serverIp:$serverPort/main-screen-accommodations'),
      headers: {
        'Content-Type': 'application/json',
        if (jwtToken != null) 'Authorization': 'Bearer $jwtToken',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final baseList = data['results'];
      if (!mounted) return;
      setState(() {
        accommodations =
            baseList
                .map((item) => {...item, 'is_liked': item['is_liked'] ?? false})
                .toList();
      });
    }
  }

  Future<Uint8List?> fetchAccommodationImage(int aid) async {
    final response = await http.get(
      Uri.parse('http://$serverIp:$serverPort/accommodations/$aid/image/1'),
      headers: {if (jwtToken != null) 'Authorization': 'Bearer $jwtToken'},
    );
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      return null;
    }
  }

  Future<void> toggleLike(int aid, int index) async {
    final response = await http.post(
      Uri.parse('http://$serverIp:$serverPort/like_dislike'),
      headers: {
        'Content-Type': 'application/json',
        if (jwtToken != null) 'Authorization': 'Bearer $jwtToken',
      },
      body: jsonEncode({'aid': aid}),
    );
    if (response.statusCode == 200) {
      final message = jsonDecode(response.body)['message'];
      if (!mounted) return;
      setState(() {
        accommodations[index]['is_liked'] = message == 'Liked accommodation';
      });
    }
  }

  void _pickDate({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    required ValueChanged<DateTime> onDateSelected,
  }) {
    if (Platform.isIOS) {
      showCupertinoModalPopup(
        context: context,
        builder:
            (_) => Container(
              height: 260,
              color: CupertinoColors.systemBackground.resolveFrom(context),
              child: Column(
                children: [
                  Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('Done'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  Expanded(
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.date,
                      initialDateTime: initialDate,
                      minimumDate: firstDate,
                      maximumDate: lastDate,
                      onDateTimeChanged: onDateSelected,
                    ),
                  ),
                ],
              ),
            ),
      );
    } else {
      showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
      ).then((picked) {
        if (picked != null) onDateSelected(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final highContrast = settings.highContrast;
    final bigText = settings.bigText;
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final backgroundColor =
        highContrast
            ? (isDark ? AppColors.colorBgDarkHigh : AppColors.colorBgHigh)
            : (isDark ? AppColors.colorBgDark : AppColors.colorBg);

    return Scaffold(
      backgroundColor: backgroundColor,
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 600) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: SizedBox(
                    width: constraints.maxWidth * 0.8,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: locationController,
                                        style: TextStyle(
                                          color:
                                              Theme.of(
                                                context,
                                              ).textTheme.bodyMedium!.color,
                                        ),
                                        decoration: InputDecoration(
                                          prefixIcon: Icon(
                                            Icons.location_on_outlined,
                                            color:
                                                Theme.of(
                                                  context,
                                                ).textTheme.bodyMedium!.color,
                                          ),
                                          hintText: 'Location',
                                          hintStyle: TextStyle(
                                            fontSize: bigText ? 24 : 18,
                                            color:
                                                highContrast
                                                    ? (isDark
                                                        ? AppColors
                                                            .colorTextDarkHigh
                                                        : AppColors
                                                            .colorTextHigh)
                                                    : (isDark
                                                        ? AppColors
                                                            .colorTextDark
                                                        : AppColors.colorText),
                                            fontFamily: 'Helvetica',
                                            fontWeight:
                                                bigText
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                          ),
                                          filled: true,
                                          fillColor:
                                              isDark
                                                  ? Color.fromARGB(
                                                    255,
                                                    66,
                                                    66,
                                                    66,
                                                  )
                                                  : const Color.fromARGB(
                                                    255,
                                                    224,
                                                    224,
                                                    224,
                                                  ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            borderSide: BorderSide.none,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: Icon(
                                        Icons.my_location,
                                        color:
                                            Theme.of(
                                              context,
                                            ).textTheme.bodyMedium!.color,
                                      ),
                                      tooltip: 'Use my location',
                                      onPressed: () async {
                                        LocationPermission permission =
                                            await Geolocator.checkPermission();
                                        if (permission ==
                                            LocationPermission.denied) {
                                          permission =
                                              await Geolocator.requestPermission();
                                          if (permission ==
                                              LocationPermission.denied) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Location permission was denied.',
                                                ),
                                              ),
                                            );
                                            return;
                                          }
                                        }
                                        if (permission ==
                                            LocationPermission.deniedForever) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Location permission is permanently denied. Please enable it in settings.',
                                              ),
                                            ),
                                          );
                                          return;
                                        }
                                        final position =
                                            await Geolocator.getCurrentPosition(
                                              locationSettings:
                                                  const LocationSettings(
                                                    accuracy:
                                                        LocationAccuracy.medium,
                                                  ),
                                            );
                                        final response = await http.post(
                                          Uri.parse(
                                            'http://$serverIp:$serverPort/get-address',
                                          ),
                                          headers: {
                                            'Content-Type': 'application/json',
                                            if (jwtToken != null)
                                              'Authorization':
                                                  'Bearer $jwtToken',
                                          },
                                          body: jsonEncode({
                                            'latitude': position.latitude,
                                            'longitude': position.longitude,
                                          }),
                                        );
                                        if (response.statusCode == 200) {
                                          final data = jsonDecode(
                                            response.body,
                                          );
                                          setState(() {
                                            locationController.text =
                                                data['address'];
                                          });
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              _buildDateField(isDark),
                              _buildInputField(
                                controller: guestController,
                                icon: Icons.group_outlined,
                                hint: 'Guests',
                                keyboardType: TextInputType.number,
                                isDark: isDark,
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: () {
                                  final from = dateFromNotifier.value;
                                  final to = dateToNotifier.value;
                                  final loc = locationController.text;
                                  final guestsText = guestController.text;
                                  if (loc.isEmpty ||
                                      guestsText.isEmpty ||
                                      from == null ||
                                      to == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please fill in location, dates, and guest count.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  if (to.isBefore(from)) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'End date cant be before start date.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => SearchResultsScreen(
                                            location: loc,
                                            dateFrom: from,
                                            dateTo: to,
                                            guests: int.parse(guestsText),
                                          ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      highContrast
                                          ? (isDark
                                              ? AppColors.color1DarkHigh
                                              : AppColors.color1High)
                                          : (isDark
                                              ? AppColors.color1Dark
                                              : AppColors.color1),
                                  minimumSize: const Size(double.infinity, 50),
                                ),
                                child: Text(
                                  "Search",
                                  style: TextStyle(
                                    fontSize: bigText ? 24 : 18,
                                    fontWeight:
                                        bigText
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                    color:
                                        highContrast
                                            ? AppColors.colorTextDarkHigh
                                            : AppColors.colorTextDark,
                                    fontFamily: 'Helvetica',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              if (accommodations.isEmpty)
                                Text(
                                  "No accommodations available.",
                                  style: TextStyle(
                                    fontSize: bigText ? 20 : 16,
                                    fontWeight:
                                        bigText
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                    color:
                                        Theme.of(
                                          context,
                                        ).textTheme.bodyMedium!.color,
                                  ),
                                )
                              else
                                ListView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  itemCount: accommodations.length,
                                  itemBuilder: (context, index) {
                                    final item = accommodations[index];
                                    final isLiked = item['is_liked'] ?? false;
                                    final aid = accommodations[index]['aid'];
                                    return FutureBuilder<Uint8List?>(
                                      future: _cachedFetch(aid),
                                      builder: (context, snapshot) {
                                        // ignore: unused_local_variable
                                        Widget imageWidget;
                                        if (snapshot.connectionState ==
                                                ConnectionState.done &&
                                            snapshot.hasData) {
                                          imageWidget = CachedNetworkImage(
                                            imageUrl:
                                                'http://$serverIp:$serverPort/accommodations/${item['aid']}/image/1',
                                            httpHeaders: {
                                              if (jwtToken != null)
                                                'Authorization':
                                                    'Bearer $jwtToken',
                                            },
                                            // while loading:
                                            placeholder:
                                                (context, url) => SizedBox(
                                                  height: 180,
                                                  child: Center(
                                                    child:
                                                        CircularProgressIndicator(),
                                                  ),
                                                ),
                                            // if image fails:
                                            errorWidget:
                                                (context, url, error) =>
                                                    SizedBox(
                                                      height: 180,
                                                      child: Center(
                                                        child: Icon(
                                                          Icons.broken_image,
                                                        ),
                                                      ),
                                                    ),
                                            fit: BoxFit.cover,
                                            height: 180,
                                            width: double.infinity,
                                          );
                                        } else if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          imageWidget = const SizedBox(
                                            height: 180,
                                            child: Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          );
                                        } else {
                                          imageWidget = const SizedBox(
                                            height: 180,
                                            child: Placeholder(),
                                          );
                                        }
                                        return GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (_) =>
                                                        AccommodationDetailScreen(
                                                          aid: item['aid'],
                                                        ),
                                              ),
                                            );
                                          },
                                          child: Card(
                                            margin: const EdgeInsets.only(
                                              bottom: 16,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                      const BorderRadius.vertical(
                                                        top: Radius.circular(
                                                          10,
                                                        ),
                                                      ),
                                                  child: CachedNetworkImage(
                                                    imageUrl:
                                                        'http://$serverIp:$serverPort/accommodations/${item['aid']}/image/1',
                                                    httpHeaders: {
                                                      if (jwtToken != null) 'Authorization': 'Bearer $jwtToken',
                                                    },
                                                    placeholder: (ctx, url) => SizedBox(
                                                      height: 180,
                                                      child: Center(child: CircularProgressIndicator()),
                                                    ),
                                                    errorWidget: (ctx, url, error) => SizedBox(
                                                      height: 180,
                                                      child: Center(child: Icon(Icons.broken_image)),
                                                    ),
                                                    fit: BoxFit.cover,
                                                    height: 180,
                                                    width: double.infinity,
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.all(
                                                    12,
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            item['location'],
                                                            style: TextStyle(
                                                              fontSize:
                                                                  bigText
                                                                      ? 24
                                                                      : 18,
                                                              fontWeight:
                                                                  bigText
                                                                      ? FontWeight
                                                                          .bold
                                                                      : FontWeight
                                                                          .normal,
                                                              color:
                                                                  highContrast
                                                                      ? (isDark
                                                                          ? AppColors
                                                                              .colorTextDarkHigh
                                                                          : AppColors
                                                                              .colorTextHigh)
                                                                      : (isDark
                                                                          ? AppColors
                                                                              .colorTextDark
                                                                          : AppColors
                                                                              .colorText),
                                                              fontFamily:
                                                                  'Helvetica',
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            height: 4,
                                                          ),
                                                          Text(
                                                            '${item['price_per_night']} € / Night',
                                                            style: TextStyle(
                                                              fontSize:
                                                                  bigText
                                                                      ? 20
                                                                      : 16,
                                                              fontWeight:
                                                                  bigText
                                                                      ? FontWeight
                                                                          .bold
                                                                      : FontWeight
                                                                          .normal,
                                                              color:
                                                                  highContrast
                                                                      ? (isDark
                                                                          ? AppColors
                                                                              .colorTextDarkHigh
                                                                          : AppColors
                                                                              .colorTextHigh)
                                                                      : (isDark
                                                                          ? AppColors
                                                                              .colorTextDark
                                                                          : AppColors
                                                                              .colorText),
                                                              fontFamily:
                                                                  'Helvetica',
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      IconButton(
                                                        icon: Icon(
                                                          isLiked
                                                              ? Icons.favorite
                                                              : Icons
                                                                  .favorite_border,
                                                          color:
                                                              isLiked
                                                                  ? Colors.red
                                                                  : (isDark
                                                                      ? Colors
                                                                          .white
                                                                      : Colors
                                                                          .black),
                                                        ),
                                                        onPressed:
                                                            () => toggleLike(
                                                              item['aid'],
                                                              index,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: locationController,
                            style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodyMedium!.color,
                            ),
                            decoration: InputDecoration(
                              prefixIcon: Icon(
                                Icons.location_on_outlined,
                                color:
                                    Theme.of(
                                      context,
                                    ).textTheme.bodyMedium!.color,
                              ),
                              hintText: 'Location',
                              hintStyle: TextStyle(
                                fontSize: bigText ? 24 : 18,
                                color:
                                    highContrast
                                        ? (isDark
                                            ? AppColors.colorTextDarkHigh
                                            : AppColors.colorTextHigh)
                                        : (isDark
                                            ? AppColors.colorTextDark
                                            : AppColors.colorText),
                                fontFamily: 'Helvetica',
                                fontWeight:
                                    bigText
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                              filled: true,
                              fillColor:
                                  isDark
                                      ? Color.fromARGB(255, 66, 66, 66)
                                      : const Color.fromARGB(
                                        255,
                                        224,
                                        224,
                                        224,
                                      ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            Icons.my_location,
                            color:
                                Theme.of(context).textTheme.bodyMedium!.color,
                          ),
                          tooltip: 'Use my location',
                          onPressed: () async {
                            LocationPermission permission =
                                await Geolocator.checkPermission();
                            if (permission == LocationPermission.denied) {
                              permission = await Geolocator.requestPermission();
                              if (permission == LocationPermission.denied) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Location permission was denied.',
                                    ),
                                  ),
                                );
                                return;
                              }
                            }
                            if (permission ==
                                LocationPermission.deniedForever) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Location permission is permanently denied. Please enable it in settings.',
                                  ),
                                ),
                              );
                              return;
                            }
                            final position =
                                await Geolocator.getCurrentPosition(
                                  locationSettings: const LocationSettings(
                                    accuracy: LocationAccuracy.medium,
                                  ),
                                );
                            final response = await http.post(
                              Uri.parse(
                                'http://$serverIp:$serverPort/get-address',
                              ),
                              headers: {
                                'Content-Type': 'application/json',
                                if (jwtToken != null)
                                  'Authorization': 'Bearer $jwtToken',
                              },
                              body: jsonEncode({
                                'latitude': position.latitude,
                                'longitude': position.longitude,
                              }),
                            );
                            if (response.statusCode == 200) {
                              final data = jsonDecode(response.body);
                              setState(() {
                                locationController.text = data['address'];
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  _buildDateField(isDark),
                  _buildInputField(
                    controller: guestController,
                    icon: Icons.group_outlined,
                    hint: 'Guests',
                    keyboardType: TextInputType.number,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      final from = dateFromNotifier.value;
                      final to = dateToNotifier.value;
                      final loc = locationController.text;
                      final guestsText = guestController.text;
                      if (loc.isEmpty ||
                          guestsText.isEmpty ||
                          from == null ||
                          to == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please fill in location, dates, and guest count.',
                            ),
                          ),
                        );
                        return;
                      }
                      if (to.isBefore(from)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'End date cant be before start date.',
                            ),
                          ),
                        );
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => SearchResultsScreen(
                                location: loc,
                                dateFrom: from,
                                dateTo: to,
                                guests: int.parse(guestsText),
                              ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          highContrast
                              ? (isDark
                                  ? AppColors.color1DarkHigh
                                  : AppColors.color1High)
                              : (isDark
                                  ? AppColors.color1Dark
                                  : AppColors.color1),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: Text(
                      "Search",
                      style: TextStyle(
                        fontSize: bigText ? 24 : 18,
                        fontWeight:
                            bigText ? FontWeight.bold : FontWeight.normal,
                        color:
                            highContrast
                                ? AppColors.colorTextDarkHigh
                                : AppColors.colorTextDark,
                        fontFamily: 'Helvetica',
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (accommodations.isEmpty)
                    Text(
                      "No accommodations available.",
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).textTheme.bodyMedium!.color,
                      ),
                    )
                  else
                    ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: accommodations.length,
                      itemBuilder: (context, index) {
                        final item = accommodations[index];
                        final isLiked = item['is_liked'] ?? false;
                        return FutureBuilder<Uint8List?>(
                          future: _cachedFetch(item['aid']),
                          builder: (context, snapshot) {
                            // ignore: unused_local_variable
                            Widget imageWidget;
                            if (snapshot.connectionState ==
                                    ConnectionState.done &&
                                snapshot.hasData) {
                              imageWidget = CachedNetworkImage(
                                imageUrl:
                                    'http://$serverIp:$serverPort/accommodations/${item['aid']}/image/1',
                                httpHeaders: {
                                  if (jwtToken != null)
                                    'Authorization': 'Bearer $jwtToken',
                                },
                                // while loading:
                                placeholder:
                                    (context, url) => SizedBox(
                                      height: 180,
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                // if image fails:
                                errorWidget:
                                    (context, url, error) => SizedBox(
                                      height: 180,
                                      child: Center(
                                        child: Icon(Icons.broken_image),
                                      ),
                                    ),
                                fit: BoxFit.cover,
                                height: 180,
                                width: double.infinity,
                              );
                            } else if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              imageWidget = const SizedBox(
                                height: 180,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            } else {
                              imageWidget = const SizedBox(
                                height: 180,
                                child: Placeholder(),
                              );
                            }
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => AccommodationDetailScreen(
                                          aid: item['aid'],
                                        ),
                                  ),
                                );
                              },
                              child: Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(10),
                                      ),
                                      child: CachedNetworkImage(
                                        imageUrl:
                                            'http://$serverIp:$serverPort/accommodations/${item['aid']}/image/1',
                                        httpHeaders: {
                                          if (jwtToken != null) 'Authorization': 'Bearer $jwtToken',
                                        },
                                        placeholder: (ctx, url) => SizedBox(
                                          height: 180,
                                          child: Center(child: CircularProgressIndicator()),
                                        ),
                                        errorWidget: (ctx, url, error) => SizedBox(
                                          height: 180,
                                          child: Center(child: Icon(Icons.broken_image)),
                                        ),
                                        fit: BoxFit.cover,
                                        height: 180,
                                        width: double.infinity,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item['location'],
                                                style: TextStyle(
                                                  fontSize: bigText ? 24 : 18,
                                                  fontWeight:
                                                      bigText
                                                          ? FontWeight.bold
                                                          : FontWeight.normal,
                                                  color:
                                                      highContrast
                                                          ? (isDark
                                                              ? AppColors
                                                                  .colorTextDarkHigh
                                                              : AppColors
                                                                  .colorTextHigh)
                                                          : (isDark
                                                              ? AppColors
                                                                  .colorTextDark
                                                              : AppColors
                                                                  .colorText),
                                                  fontFamily: 'Helvetica',
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${item['price_per_night']} € / Night',
                                                style: TextStyle(
                                                  fontSize: bigText ? 20 : 16,
                                                  fontWeight:
                                                      bigText
                                                          ? FontWeight.bold
                                                          : FontWeight.normal,
                                                  color:
                                                      highContrast
                                                          ? (isDark
                                                              ? AppColors
                                                                  .colorTextDarkHigh
                                                              : AppColors
                                                                  .colorTextHigh)
                                                          : (isDark
                                                              ? AppColors
                                                                  .colorTextDark
                                                              : AppColors
                                                                  .colorText),
                                                  fontFamily: 'Helvetica',
                                                ),
                                              ),
                                            ],
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              isLiked
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              color:
                                                  isLiked
                                                      ? Colors.red
                                                      : (isDark
                                                          ? Colors.white
                                                          : Colors.black),
                                            ),
                                            onPressed:
                                                () => toggleLike(
                                                  item['aid'],
                                                  index,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final bigText = context.watch<AppSettings>().bigText;
    final highContrast = context.watch<AppSettings>().highContrast;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color),
        decoration: InputDecoration(
          prefixIcon: Icon(
            icon,
            color: Theme.of(context).textTheme.bodyMedium!.color,
          ),
          hintText: hint,
          hintStyle: TextStyle(
            fontSize: bigText ? 24 : 18,
            color:
                highContrast
                    ? (isDark
                        ? AppColors.colorTextDarkHigh
                        : AppColors.colorTextHigh)
                    : (isDark ? AppColors.colorTextDark : AppColors.colorText),
            fontWeight: bigText ? FontWeight.bold : FontWeight.normal,
            fontFamily: 'Helvetica',
          ),
          filled: true,
          fillColor: isDark ? Colors.grey[800] : Colors.grey[300],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildDateField(bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ValueListenableBuilder<DateTime?>(
                valueListenable: dateFromNotifier,
                builder: (context, dateFrom, _) {
                  return _buildDateTile(
                    label:
                        dateFrom == null
                            ? 'from'
                            : DateFormat.yMMMMd().format(dateFrom),
                    context: context,
                    onTap: () {
                      final now = DateTime.now();
                      _pickDate(
                        context: context,
                        initialDate: dateFrom ?? now,
                        firstDate: now.subtract(const Duration(days: 1)),
                        lastDate: now.add(const Duration(days: 365)),
                        onDateSelected:
                            (picked) => dateFromNotifier.value = picked,
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ValueListenableBuilder<DateTime?>(
                valueListenable: dateToNotifier,
                builder: (context, dateTo, _) {
                  return _buildDateTile(
                    label:
                        dateTo == null
                            ? 'to'
                            : DateFormat.yMMMMd().format(dateTo),
                    context: context,
                    onTap: () {
                      if (dateFromNotifier.value == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please pick a start date first.'),
                          ),
                        );
                        return;
                      }
                      final now = DateTime.now();
                      final min = dateFromNotifier.value!;
                      final initial = dateTo ?? min;
                      _pickDate(
                        context: context,
                        initialDate: initial,
                        firstDate: min,
                        lastDate: now.add(const Duration(days: 365)),
                        onDateSelected:
                            (picked) => dateToNotifier.value = picked,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildDateTile({
    required String label,
    required VoidCallback onTap,
    required BuildContext context,
  }) {
    final bigText = context.watch<AppSettings>().bigText;
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 55,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.calendar,
              size: bigText ? 28 : 24,
              color: Theme.of(context).iconTheme.color,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium!.color,
                  fontSize: bigText ? 24 : 18,
                  fontWeight: bigText ? FontWeight.bold : FontWeight.normal,
                  fontFamily: 'Helvetica',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
