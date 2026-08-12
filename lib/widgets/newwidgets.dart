import 'package:nextfind/networking/apiconn.dart';
import 'package:nextfind/pages/focusedviewed.dart';
import 'package:nextfind/pages/homepage.dart';
import 'package:nextfind/pages/userpage.dart';
import 'package:nextfind/utils/businessManager.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:nextfind/utils/arbitStore.dart';
import 'package:nextfind/pages/searchpage.dart';
import 'package:intl/intl.dart';

final mlog = Logger();
final searchBarTextController = TextEditingController();

bool isBetween(DateTime start, DateTime end, DateTime now) {
  return now.isAfter(start) && now.isBefore(end);
}

bool isCached(ImageProvider provider) {
  final key = provider.obtainKey(const ImageConfiguration());
  final cache = PaintingBinding.instance.imageCache;

  return cache.containsKey(key);
}

void startPreloading(
  BuildContext context,
  List<String> urls,
) {
  _runPreloadTask(urls, context); // fire-and-forget
}

Future<void> _runPreloadTask(List<String> urls, BuildContext context) async {
  for (final url in urls) {
    log.i("CHACHED $url");

    Future.microtask(() async {
      await precacheImage(NetworkImage("$serverUrl/image/$url"), context);
    });

    await Future.delayed(const Duration(milliseconds: 30)); // throttle
  }
}

String parseAddress(Map address, int houseNumber) {
  String addressString = "";

  addressString += houseNumber.toString();

  addressString += " ${address["road"] ?? "INVALID POSITION"}";

  addressString += "\n${address["postcode"] ?? "INVALID POSITION"}";

  return addressString;
}
// double dist(List<double> a, List<double> b) {
//   final dx = a[0] - b[0];
//   final dy = a[1] - b[1];
//   return math.sqrt(dx * dx + dy * dy);
// }

class Point {
  final double x;
  final double y;
  const Point(this.x, this.y);
}

double dist2(Point a, Point b) {
  final dx = a.x - b.x;
  final dy = a.y - b.y;
  return dx * dx + dy * dy;
}

List<double> nearestDistances(List<Point> points) {
  final result = List<double>.filled(points.length, 0);

  for (int i = 0; i < points.length; i++) {
    double best = double.infinity;
    final p = points[i];

    for (int j = 0; j < points.length; j++) {
      if (i == j) continue;

      final d = dist2(p, points[j]);
      if (d < best) best = d;
    }

    result[i] = best;
  }

  return result;
}

class AppColors {
  static const background = Color.fromARGB(255, 255, 255, 255);
  static const leveled = Color.fromARGB(255, 230, 230, 230);
  static const text = Color.fromARGB(255, 0, 0, 0);
  static const primary = Color.fromARGB(255, 252, 130, 74);
  static const secondary = Color.fromARGB(255, 101, 44, 145);
  static const accent = Color.fromARGB(255, 34, 139, 219);
}

class MyInputField extends StatelessWidget {
  const MyInputField(
      {super.key,
      this.hint = "",
      this.textColor = AppColors.text,
      this.backgroundColor = AppColors.primary,
      this.size = 30.0,
      this.controller,
      this.onSubmitted,
      this.padding = const EdgeInsets.all(10),
      this.borderRadius});

  final Color textColor;
  final Color backgroundColor;
  final double size;
  final String hint;
  final TextEditingController? controller;
  final void Function(String value)? onSubmitted;
  final EdgeInsets padding;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: padding,
          child: ClipRRect(
            borderRadius: borderRadius ?? BorderRadius.circular(20),
            child: Container(
              color: backgroundColor,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 15,
                  ),
                  Expanded(
                    child: HeaderInput(
                      hint: hint,
                      controller: controller,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class MyButton extends StatelessWidget {
  const MyButton(
      {super.key,
      this.child = const MyText("Button"),
      required this.width,
      required this.height,
      this.onPressed,
      this.padding = const EdgeInsets.symmetric(vertical: 18, horizontal: 40),
      this.borderRadius,
      this.backgroundColor = AppColors.primary});

  final Widget child;
  final double width;
  final double height;
  final VoidCallback? onPressed;
  final EdgeInsets padding;
  final BorderRadius? borderRadius;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: padding,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(12),
          ),
          backgroundColor: backgroundColor,
        ),
        child: child,
      ),
    );
  }
}

class HeaderInput extends StatefulWidget {
  const HeaderInput(
      {super.key,
      this.hint = "",
      this.color = AppColors.background,
      this.size = 30.0,
      this.controller,
      this.onSubmitted});

  final Color color;
  final double size;
  final String hint;
  final TextEditingController? controller;
  final void Function(String value)? onSubmitted;

  @override
  State<HeaderInput> createState() => HeaderInputState();
}

class HeaderInputState extends State<HeaderInput> {
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      onSubmitted: (value) {
        if (widget.onSubmitted != null) {
          widget.onSubmitted!(value);
        }
      },
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: TextStyle(
          fontSize: widget.size,
          fontWeight: FontWeight.w400,
          fontFamily: "LilitaOne",
          color: const Color.fromARGB(106, 255, 255, 255),
        ),
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
      style: TextStyle(
        fontSize: widget.size,
        fontWeight: FontWeight.w400,
        fontFamily: "LilitaOne",
        color: widget.color,
      ),
    );
  }
}

class Heading extends StatelessWidget {
  const Heading(this.text, {super.key, this.color = AppColors.text});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
          color: color,
          fontSize: 50,
          fontFamily: "LilitaOne",
          fontWeight: FontWeight.w400),
    );
  }
}

class SubHeading extends StatelessWidget {
  const SubHeading(this.text, {super.key, this.color = AppColors.text});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
          color: color,
          fontSize: 40,
          fontFamily: "LilitaOne",
          fontWeight: FontWeight.w400),
    );
  }
}

class Body extends StatelessWidget {
  const Body(this.text, {super.key, this.color = AppColors.text});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
          color: color,
          fontSize: 20,
          fontFamily: "LilitaOne",
          fontWeight: FontWeight.w400),
    );
  }
}

class Small extends StatelessWidget {
  const Small(this.text, {super.key, this.color = AppColors.text});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
          color: color,
          fontSize: 15,
          fontFamily: "LilitaOne",
          fontWeight: FontWeight.w400),
    );
  }
}

class MyText extends StatelessWidget {
  const MyText(this.text,
      {super.key,
      this.color = AppColors.text,
      this.size = 20,
      this.fontWeight = FontWeight.w400,
      this.overflow = TextOverflow.visible,
      this.maxlines = 2,
      this.textAlign = TextAlign.left});

  final String text;
  final Color color;
  final double size;
  final int maxlines;
  final FontWeight fontWeight;
  final TextOverflow overflow;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: maxlines,
      softWrap: true,
      textAlign: textAlign,
      style: TextStyle(
          color: color,
          fontSize: size,
          fontFamily: "LilitaOne",
          overflow: overflow,
          fontWeight: fontWeight),
    );
  }
}

class BaseImage extends StatefulWidget {
  final String url;
  final double width;
  final double height;
  final double radius;
  final BoxFit fit;

  const BaseImage({
    required this.url,
    this.width = 180,
    this.height = 170,
    this.radius = 18,
    this.fit = BoxFit.cover,
    super.key,
  });

  @override
  State<BaseImage> createState() => _BaseImageState();
}

class _BaseImageState extends State<BaseImage> {
  late final ImageProvider provider;

  @override
  void initState() {
    super.initState();

    if (widget.url != "No Url") {
      final trueUrl = "$serverUrl/image/${widget.url}";

      provider = NetworkImage(trueUrl);
      // WidgetsBinding.instance.addPostFrameCallback((_) async {
      //   try {
      //     await precacheImage(provider, context);
      //     log.i("PRECACHE SUCCESS");
      //   } catch (e, st) {
      //     log.e("PRECACHE FAILED: $e\n$st");
      //   }
      // });

      // preload once
      // precacheImage(provider, context);
    } else {
      provider = const AssetImage("assets/img/kde.png");
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: Image(
        image: provider,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
      ),
    );
  }
}

class BusinessLocationThumbnail extends StatefulWidget {
  const BusinessLocationThumbnail(
      {required this.locationId, super.key, this.scale = 1});
  final String locationId;
  final double scale;

  @override
  State<BusinessLocationThumbnail> createState() =>
      _BusinessLocationThumbnailState();
}

class _BusinessLocationThumbnailState extends State<BusinessLocationThumbnail>
    with AutomaticKeepAliveClientMixin {
  late Future<Map<String, MiniBusinessLoc>> _future;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _future = businessManager.getBusinessLocationMini([widget.locationId]);
  }

  Widget buildWidget(BuildContext context,
      AsyncSnapshot<Map<String, MiniBusinessLoc>> snapshot) {
    if (snapshot.hasData) {
      final minibusinessLocation = snapshot.data![widget.locationId]!;
      String ratings = "No Ratings";
      if (minibusinessLocation.numRatings != null) {
        ratings =
            "${minibusinessLocation.averageRating!.toStringAsFixed(2)}/10 (${minibusinessLocation.numRatings!})";
      }

      bool open = false;
      String? signTime;
      String openString = "";

      final openTimes = minibusinessLocation.openHours;

      if (openTimes != null) {
        final weekday = DateTime.now().weekday.toString();

        if (openTimes.containsKey(weekday)) {
          List<dynamic> times = openTimes[weekday];

          final openTime = DateFormat("HH:mm").parse(times[0]);
          final closeTime = DateFormat("HH:mm").parse(times[1]);
          final timeNow =
              DateTime(1970, 1, 1, DateTime.now().hour, DateTime.now().minute);

          if (isBetween(openTime, closeTime, timeNow) == true) {
            open = true;
            signTime = times[1];
          } else {
            signTime = times[0];
          }
        }

        if (signTime == null) {
          openString = "Closed Forever";
        } else {
          if (open) {
            openString = "Open - Closes $signTime";
          } else {
            openString = "Closed - Opens $signTime";
          }
        }
      }

      String iconPath = "assets/icons/svg_logo.png";
      if (minibusinessLocation.type == 0) {
        iconPath =
            "assets/icons/business_type_icons/food_and_dining_icon_alt.png";
      } else if (minibusinessLocation.type == 1) {
        iconPath =
            "assets/icons/business_type_icons/home_services_icon_alt.png";
      } else if (minibusinessLocation.type == 2) {
        iconPath =
            "assets/icons/business_type_icons/health_and_wellness_icon_alt.png";
      } else if (minibusinessLocation.type == 3) {
        iconPath =
            "assets/icons/business_type_icons/shopping_and_retail_icon_alt.png";
      } else if (minibusinessLocation.type == 4) {
        iconPath =
            "assets/icons/business_type_icons/proffesional_services_icon_alt.png";
      } else if (minibusinessLocation.type == 5) {
        iconPath = "assets/icons/business_type_icons/automotive_icon_alt.png";
      } else if (minibusinessLocation.type == 6) {
        iconPath =
            "assets/icons/business_type_icons/beauty_and_personal_care_icon_alt.png";
      } else if (minibusinessLocation.type == 7) {
        iconPath =
            "assets/icons/business_type_icons/entertainment_and_leisure_icon_alt.png";
      } else if (minibusinessLocation.type == 8) {
        iconPath = "assets/icons/business_type_icons/education_icon_alt.png";
      } else if (minibusinessLocation.type == 9) {
        iconPath =
            "assets/icons/business_type_icons/lodging_and_travel_icon_alt.png";
      }

      return SizedBox(
        width: 380,
        height: 260,
        child: Stack(
          children: [
            // SHADOW ONLY
            Positioned(
              left: 0,
              top: 0,
              child: IgnorePointer(
                child: Container(
                  width: 380,
                  height: 240,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromARGB(62, 101, 101, 101),
                        blurRadius: 10,
                        offset: Offset(-7, 10),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ACTUAL CARD (Material + InkWell)
            Positioned(
              left: 0,
              top: 0,
              child: Material(
                color: Colors.white,
                // surfaceTintColor: app,
                borderRadius: BorderRadius.circular(30),
                clipBehavior: Clip.hardEdge,
                child: InkWell(
                  splashColor: const Color.fromARGB(255, 229, 233, 234),
                  onTap: () {
                    goToBusinessPage(context, minibusinessLocation.locationId);
                  },
                  child: SizedBox(
                    width: 380,
                    height: 240,
                    child: Stack(
                      children: [
                        // RIGHT SIDE CONTENT
                        Positioned(
                          left: 210,
                          top: 10,
                          child: SizedBox(
                            width: 150,
                            child: Column(
                              spacing: 5,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                      minWidth: 150,
                                      maxWidth: 150,
                                      minHeight: 40),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      MyText(
                                        minibusinessLocation.name,
                                        color: AppColors.primary,
                                        size: 20,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      SizedBox(
                                          width: 200,
                                          height: 50,
                                          child: Stack(
                                              alignment:
                                                  AlignmentGeometry.center,
                                              children: [
                                                Positioned(
                                                    left: -2,
                                                    child: Image.asset(iconPath,
                                                        width: 30, height: 30)),
                                                Positioned(
                                                    left: 30,
                                                    child: MyText(
                                                      color: AppColors.primary,
                                                      businessTypeLookup[
                                                          minibusinessLocation
                                                              .type]!,
                                                      size: 14,
                                                    )),
                                              ])),
                                    ],
                                  ),
                                ),
                                Small(ratings),
                                MyText(
                                  parseAddress(minibusinessLocation.address,
                                      minibusinessLocation.buildingNumber),
                                  size: 13,
                                ),
                                Row(
                                  children: [
                                    Small(
                                      "${minibusinessLocation.distance.toStringAsFixed(2)} km",
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // LEFT SIDE IMAGE + STATUS
                        Positioned(
                          left: 13.15,
                          top: 13.15,
                          child: Column(
                            spacing: 10,
                            children: [
                              BaseImage(
                                url: minibusinessLocation.thumbnailPath ??
                                    "No Url",
                              ),
                              Small(openString),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else if (snapshot.hasError) {
      return Text('Error: ${snapshot.error}');
    } else {
      return const CircularProgressIndicator();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder(
        future: _future,
        builder: (BuildContext context,
            AsyncSnapshot<Map<String, MiniBusinessLoc>> snapshot) {
          return buildWidget(context, snapshot);
        });
  }
}

class MyMainToggle extends StatefulWidget {
  final Function(bool isleft) onChanged;
  final String left;
  final String right;
  const MyMainToggle({
    required this.onChanged,
    this.left = "",
    this.right = "",
    super.key,
  });

  @override
  State<MyMainToggle> createState() => MyMainToggleState();
}

class MyMainToggleState extends State<MyMainToggle> {
  bool isService = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => isService = true);
                widget.onChanged(true);
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isService ? Colors.blue : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    widget.left,
                    style: TextStyle(
                      color: isService ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => isService = false);
                widget.onChanged(false);
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !isService ? Colors.blue : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    widget.right,
                    style: TextStyle(
                      color: !isService ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MyMainSlider extends StatefulWidget {
  final Function(int) onChanged;
  final List<int> distances;
  final int startValue;

  const MyMainSlider({
    required this.onChanged,
    this.distances = const [1, 3, 5, 10, 15, 20, 30, 50],
    this.startValue = 0,
    super.key,
  });

  @override
  State<MyMainSlider> createState() => MyMainSliderState();
}

class MyMainSliderState extends State<MyMainSlider> {
  late int sliderValue;

  @override
  void initState() {
    super.initState();
    sliderValue = widget.startValue; // store initial value once
  }

  @override
  Widget build(BuildContext context) {
    final List<int> distances = widget.distances;

    final bool isOne = (distances[sliderValue.toInt()] == 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 5,
      children: [
        Body(
          (distances[sliderValue.toInt()] == 1)
              ? "Search within ${distances[sliderValue.toInt()]} mile"
              : "Search within ${distances[sliderValue.toInt()]} miles",
          color: AppColors.text,
        ),
        Slider(
          value: sliderValue.toDouble(),
          min: 0,
          max: (distances.length - 1).toDouble(),
          divisions: distances.length - 1,
          // label: "${distances[sliderValue.toInt()]} miles",
          onChanged: (value) {
            setState(() => sliderValue = value.toInt());
            widget.onChanged(distances[value.toInt()]);
          },
        ),
      ],
    );
  }
}

class MyMaincheckbox extends StatefulWidget {
  final bool initialValue;
  final ValueChanged<bool> onChanged;
  final double size;
  final Color activeColor;
  final Color borderColor;
  final double borderRadius;

  const MyMaincheckbox({
    super.key,
    required this.initialValue,
    required this.onChanged,
    this.size = 22,
    this.activeColor = Colors.blue,
    this.borderColor = Colors.blue,
    this.borderRadius = 6,
  });

  @override
  State<MyMaincheckbox> createState() => MyMaincheckboxState();
}

class MyMaincheckboxState extends State<MyMaincheckbox> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  void _toggle() {
    setState(() => _value = !_value);
    widget.onChanged(_value);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _toggle,
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(color: widget.borderColor, width: 2),
          color: _value ? widget.activeColor : Colors.transparent,
        ),
        child: _value
            ? Icon(Icons.check, size: widget.size * 0.65, color: Colors.white)
            : null,
      ),
    );
  }
}

class MyMultiToggle extends StatefulWidget {
  final int initial;
  final List options;
  final Function(int) onChanged;

  const MyMultiToggle({
    super.key,
    required this.initial,
    required this.options,
    required this.onChanged,
  });

  @override
  State<MyMultiToggle> createState() => MyMultiToggleState();
}

class MyMultiToggleState extends State<MyMultiToggle> {
  late int selected;

  @override
  void initState() {
    super.initState();
    selected = widget.initial;
  }

  Widget _buildOption(String label, int index) {
    final bool active = selected == index;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => selected = index);
          widget.onChanged(index);
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                  color: active ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w400,
                  fontSize: 17,
                  fontFamily: "LilitaOne"),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.leveled,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (int i = 0; i < widget.options.length; i++)
            _buildOption(widget.options[i], i),
        ],
      ),
    );
  }
}

class MyVertMultiToggle extends StatefulWidget {
  final int initial;
  final List options;
  final Function(int) onChanged;

  const MyVertMultiToggle({
    super.key,
    required this.initial,
    required this.options,
    required this.onChanged,
  });

  @override
  State<MyVertMultiToggle> createState() => MyVertMultiToggleState();
}

class MyVertMultiToggleState extends State<MyVertMultiToggle> {
  late int selected;

  @override
  void initState() {
    super.initState();
    selected = widget.initial;
  }

  Widget _buildOption(String label, int index) {
    final bool active = selected == index;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => selected = index);
          widget.onChanged(index);
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: MyText(
              label,
              color: active ? AppColors.background : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        // color: const Color.fromARGB(255, 195, 235, 255),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          for (int i = 0; i < widget.options.length; i++)
            _buildOption(widget.options[i], i),
        ],
      ),
    );
  }
}

class MainDropdown<T> extends StatefulWidget {
  final List<T> items;
  final T? initialValue;
  final String? label;
  final String Function(T) display;
  final ValueChanged<T> onChanged;

  const MainDropdown({
    super.key,
    required this.items,
    required this.display,
    required this.onChanged,
    this.initialValue,
    this.label,
  });

  @override
  State<MainDropdown<T>> createState() => _MainDropdownState<T>();
}

class _MainDropdownState<T> extends State<MainDropdown<T>> {
  T? selected;

  @override
  void initState() {
    super.initState();
    selected = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      isExpanded: true,
      initialValue: selected,
      decoration: InputDecoration(
        labelText: widget.label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 24, // increases height
          horizontal: 12,
        ),
      ),
      items: widget.items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: SizedBox(
            height: 40, // menu item height
            child:
                MyText(widget.display(item), color: AppColors.text, size: 20),
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value == null) return;
        setState(() => selected = value);
        widget.onChanged(value);
      },
    );
  }
}

class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    this.size = 26,
    this.color = Colors.black87,
    this.bgColor = Colors.white,
    this.onTap,
  });

  final IconData icon;
  final double size;
  final Color color;
  final VoidCallback? onTap;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bgColor,
      shape: const CircleBorder(),
      elevation: 6,
      child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(
              icon,
              size: size,
              color: color,
            ),
          )),
    );
    // return
  }
}

class RoundButton extends StatelessWidget {
  const RoundButton({
    super.key,
    this.size = 26,
    this.color = Colors.black87,
    this.bgColor = Colors.white,
    this.text = "",
    this.onTap,
  });

  final double size;
  final Color color;
  final VoidCallback? onTap;
  final Color bgColor;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 12,
      shadowColor: Colors.black87,
      borderRadius: BorderRadius.circular(12),
      color: bgColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 14,
            ),
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            )),
      ),
    );
    // return
  }
}

class CustomDropDown extends StatefulWidget {
  const CustomDropDown(
      {super.key,
      this.values = const [],
      this.widgetAppend = const [],
      this.startIndex = 0,
      this.numColumns = 3});

  final List values;
  final int startIndex;
  final int numColumns;
  final List<Widget> widgetAppend;

  @override
  State<CustomDropDown> createState() => _CustomDropDownState();
}

class _CustomDropDownState extends State<CustomDropDown> {
  late ValueNotifier<int> _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = ValueNotifier(widget.startIndex);
  }

  void showOptionPicker() {
    List<Widget> gridItems = [];

    for (int itemIndex = 0; itemIndex < widget.values.length; itemIndex++) {
      final itemValue = widget.values[itemIndex];

      Widget itemWidget = SizedBox();
      if (itemIndex < widget.widgetAppend.length) {
        itemWidget = widget.widgetAppend[itemIndex];
      }

      final bool isChosen = _currentIndex.value == itemIndex;

      final gridWidget = MyButton(
        width: 50,
        height: 50,
        // backgroundColor: isChosen ? AppColors.primary : AppColors.leveled,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Center(
            child: Row(
          children: [
            MyText(
              itemValue.toString(),
              color: isChosen ? AppColors.background : AppColors.text,
              textAlign: TextAlign.center,
              size: 20,
            ),
            itemWidget
          ],
        )),
      );

      gridItems.add(gridWidget);
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: EdgeInsets.all(20),
          child: SizedBox(
              height: 500, // limit height
              // width: ,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // how wide each item should be
                  const itemWidth = 140.0;

                  // calculate how many items fit
                  final columns = (constraints.maxWidth / itemWidth).floor();

                  return GridView.count(
                    padding: EdgeInsets.all(20),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    crossAxisCount: columns,
                    children: gridItems,
                  );
                },
              )),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: _currentIndex,
        builder: (_, index, __) {
          return MyButton(
            width: 300,
            height: 60,
            padding: const EdgeInsets.only(),
            child: Stack(clipBehavior: Clip.none, children: [
              Positioned(
                left: -10,
                top: -3,
                child: MyText(
                  widget.values[_currentIndex.value].toString(),
                  textAlign: TextAlign.center,
                  color: AppColors.background,
                ),
              ),
              const Positioned(
                right: -30,
                top: -8,
                child: Icon(
                  Icons.arrow_drop_down,
                  size: 40,
                  color: Colors.white,
                ),
              )
            ]),
            onPressed: () {
              showOptionPicker();
            },
          );
        });
  }
}

Widget newbottombar(BuildContext context, {int index = 2}) {
  void homePageButtonLogic(BuildContext context) {
    goToHomePage(context);
  }

  void searchButtonLogic(BuildContext context) {
    goToSearchPage(context);
  }

  Future<void> userButtonLogic(BuildContext context) async {
    goToUserPage(context);
  }

  final midColor = Color.lerp(AppColors.background, AppColors.primary, 0.5);

  Widget searchIcon = Icon(Icons.search, color: midColor, size: 35);
  Widget leaderboardIcon =
      Icon(Icons.leaderboard_outlined, color: midColor, size: 35);
  Widget homeIcon = Icon(Icons.home_outlined, color: midColor, size: 35);
  Widget favoriteIcon =
      Icon(Icons.favorite_border_rounded, color: midColor, size: 35);
  Widget userIcon = Icon(Icons.person_outline, color: midColor, size: 35);

  if (index == 0) {
    searchIcon = const Icon(Icons.search, color: Colors.white, size: 35);
  } else if (index == 1) {
    leaderboardIcon =
        const Icon(Icons.leaderboard_outlined, color: Colors.white, size: 35);
  } else if (index == 2) {
    homeIcon = const Icon(Icons.home_outlined, color: Colors.white, size: 35);
  } else if (index == 3) {
    favoriteIcon = const Icon(Icons.favorite_border_rounded,
        color: Colors.white, size: 35);
  } else if (index == 4) {
    userIcon = const Icon(Icons.person_outline, color: Colors.white, size: 35);
  }

  return Padding(
    padding: const EdgeInsets.all(0),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(0),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10), topRight: Radius.circular(10)),
          color: AppColors.primary,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: searchIcon,
              iconSize: 35,
              onPressed: () {
                log.d("User tapped bottom nav button : search");
                searchButtonLogic(context);
              },
            ),
            IconButton(
              icon: leaderboardIcon,
              iconSize: 35,
              onPressed: () {
                log.d("User tapped bottom nav button leader :board");
              },
            ),
            IconButton(
              icon: homeIcon,
              iconSize: 35,
              onPressed: () {
                log.d("User tapped bottom nav button : home");
                homePageButtonLogic(context);
              },
            ),
            IconButton(
              icon: favoriteIcon,
              iconSize: 35,
              onPressed: () {
                log.d("User tapped bottom nav button : favorite");
              },
            ),
            IconButton(
              icon: userIcon,
              iconSize: 35,
              onPressed: () async {
                log.d("User tapped bottom nav button : user");
                await userButtonLogic(context);
              },
            ),
          ],
        ),
      ),
    ),
  );
}

void goToSearchPage(BuildContext context) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => SearchPage()),
  );
}

void goToHomePage(BuildContext context) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => const MyHomePage(title: "HI")),
  );
}

void goToBusinessPage(BuildContext context, String locationId,
    {bool canGoBack = true}) {
  final router = PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (_, __, ___) => BusinessLocPage(locationId: locationId),
    transitionsBuilder: (_, animation, __, child) {
      final offsetAnimation = Tween(
        begin: const Offset(0, 1), // start below screen
        end: Offset.zero, // end at normal position
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      ));

      return SlideTransition(
        position: offsetAnimation,
        child: child,
      );
    },
  );

  if (canGoBack) {
    Navigator.push(
      context,
      router,
    );
  } else {
    Navigator.pushReplacement(
      context,
      router,
    );
  }
}

void goToUserPage(BuildContext context, {bool canGoBack = true}) {
  if (canGoBack) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UserPage()),
    );
  } else {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const UserPage()),
    );
  }
}

PreferredSize newsearchbar(BuildContext context) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(84),
    child: Column(
      children: [
        const SizedBox(height: 30),
        Padding(
          padding: const EdgeInsets.all(10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              color: AppColors.primary,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                // mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 10),
                  const Icon(Icons.search, color: Colors.white, size: 40),
                  Expanded(
                    child: HeaderInput(
                      hint: "find a businesses",
                      controller: searchBarTextController,
                      onSubmitted: (value) => goToSearchPage(context),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.tune, color: Colors.white, size: 40),
                    iconSize: 35,
                    onPressed: () => filterDropDown(context),
                  ),
                  const SizedBox(width: 10),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

// Widget categoryPicker(){
//   return
// }

void filterDropDown(BuildContext context) {
  Arbitfallbacks();
  final distances = [1, 3, 5, 10, 15, 20, 30, 50];
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          spacing: 0,
          mainAxisSize: MainAxisSize.min,
          children: [
            const MyText(
              "Search Settings",
              color: AppColors.text,
              size: 30,
            ),
            const SizedBox(height: 20),
            MyMainSlider(
              distances: distances,
              onChanged: (distance) {
                arbitStore.data["distance_index"] = distances.indexOf(distance);
                arbitStore.data["distance"] = milesToKm(
                  distance.toDouble(),
                ).toInt();
              },
              startValue: arbitStore.data["distance_index"],
            ),
            const SizedBox(height: 30),
            // MainDropdown(
            //   items: businessTypeLookup.keys.toList(),
            //   initialValue: arbitStore.data["categoryINDEX"],
            //   label: "Business Category",
            //   display: (value) => businessTypeLookup[value]!,
            //   onChanged: (value) {
            //     arbitStore.data["categoryINDEX"] = value;
            //   },
            // ),
            CustomDropDown(
              values: businessTypeLookup.values.toList(),
            ),
            const SizedBox(height: 25),
            MyMultiToggle(
              initial: arbitStore.data["sortingINDEX"],
              options: const [
                "Relevance",
                "Distance",
                "Rating",
              ],
              onChanged: (val) {
                arbitStore.data["sortingINDEX"] = val;
                if (val == 1) {
                  arbitStore.data["sorting"] = "DST";
                }

                if (val == 2) {
                  arbitStore.data["sorting"] = "RAT";
                }
                if (val == 0) {
                  arbitStore.data["sorting"] = "";
                }
              },
            ),
            const SizedBox(height: 20),
            MyButton(
              height: 60,
              width: 60,
              child: const Body("Search", color: AppColors.background),
              onPressed: () {
                goToSearchPage(context);
              },
            ),
          ],
        ),
      );
    },
  );
}
