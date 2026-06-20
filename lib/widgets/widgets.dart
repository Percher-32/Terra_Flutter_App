// import 'dart:js_interop';
import 'dart:math';

// import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nextfind/networking/apiconn.dart' as api;
import 'package:google_fonts/google_fonts.dart';
import 'package:nextfind/pages/homepage.dart';
import 'package:nextfind/pages/searchpage.dart';
import 'package:nextfind/pages/userpage.dart';
import 'package:nextfind/pages/signuppage.dart';
import 'package:nextfind/utils/businessManager.dart';
import 'package:nextfind/utils/arbitStore.dart';
import 'package:nextfind/pages/focusedviewed.dart';
import 'package:logger/logger.dart';
import "package:nextfind/widgets/newwidgets.dart";

final nameController = TextEditingController();

final log = Logger();

//TEXT INPUTS
class MainText extends StatelessWidget {
  final String text;
  final color;

  const MainText(this.text, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.boldonse(
        textStyle: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
          color: color ?? Colors.white,
        ),
      ),
    );
  }
}

class H2Text extends StatelessWidget {
  final String text;
  final color;

  const H2Text(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.boldonse(
        textStyle: TextStyle(
          fontSize: 25,
          letterSpacing: 1,
          fontWeight: FontWeight.w800,
          color: color ?? Colors.white,
        ),
      ),
    );
  }
}

class HText extends StatelessWidget {
  final String text;
  final color;
  final double? size;
  final bold;

  const HText(
    this.text, {
    super.key,
    this.color,
    this.size,
    this.bold = FontWeight.w800,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.boldonse(
        textStyle: TextStyle(
          fontSize: size ?? 20,
          letterSpacing: 1,
          fontWeight: bold,
          color: color ?? Colors.white,
        ),
      ),
    );
  }
}

class H3Text extends StatelessWidget {
  final String text;

  const H3Text(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.boldonse(
        textStyle: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          letterSpacing: 1,
          color: Colors.white,
        ),
      ),
    );
  }
}

class H4Text extends StatelessWidget {
  final String text;

  const H4Text(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.boldonse(
        textStyle: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          color: Colors.white,
        ),
      ),
    );
  }
}

//MAIN THINGS
class MainInput extends StatefulWidget {
  const MainInput({
    super.key,
    this.hint,
    this.color = AppColors.text,
    this.size = 30.0,
    this.controller,
  });

  final color;
  final double size;
  final hint;
  final TextEditingController? controller;

  @override
  State<MainInput> createState() => _MainInputState();
}

class _MainInputState extends State<MainInput> {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return TextField(
      controller: widget.controller,
      onSubmitted: (value) {
        changepage(context, () => SearchPage(title: "e"));
      },
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: AppColors.text,
        ),
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
      style: TextStyle(
        fontSize: widget.size,
        fontWeight: FontWeight.w900,
        color: widget.color ?? AppColors.text,
      ),
    );
  }
}

class MainInputBg extends StatelessWidget {
  const MainInputBg({
    super.key,
    this.hint,
    this.before,
    this.color,
    this.bgcolor,
    this.controller,
  });

  final hint;
  final before;
  final color;
  final bgcolor;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: bgcolor,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: 20),
          H2Text(before, color: color),
          SizedBox(width: 20),
          Expanded(
            child: MainInput(
              hint: hint,
              color: AppColors.text,
              size: 20.0,
              controller: controller,
            ),
          ),
        ],
      ),
    );
  }
}

class MainToggle extends StatefulWidget {
  final Function(bool isleft) onChanged;
  final String left;
  final String right;
  const MainToggle({
    required this.onChanged,
    this.left = "",
    this.right = "",
    super.key,
  });

  @override
  State<MainToggle> createState() => MainToggleState();
}

class MainToggleState extends State<MainToggle> {
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

class MainSlider extends StatefulWidget {
  final Function(int) onChanged;
  final List<int> distances;
  final int startValue;

  const MainSlider({
    required this.onChanged,
    this.distances = const [1, 3, 5, 10, 15, 20, 30, 50],
    this.startValue = 0,
    super.key,
  });

  @override
  State<MainSlider> createState() => MainSliderState();
}

class MainSliderState extends State<MainSlider> {
  late int sliderValue;

  @override
  void initState() {
    super.initState();
    sliderValue = widget.startValue; // store initial value once
  }

  @override
  Widget build(BuildContext context) {
    final List<int> distances = widget.distances;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 30,
      children: [
        HText(
          "Search Distance: ${distances[sliderValue.toInt()]} miles",
          size: 16,
          bold: FontWeight.w600,
          color: AppColors.text,
        ),
        Slider(
          value: sliderValue.toDouble(),
          min: 0,
          max: (distances.length - 1).toDouble(),
          divisions: distances.length - 1,
          label: "${distances[sliderValue.toInt()]} miles",
          onChanged: (value) {
            setState(() => sliderValue = value.toInt());
            widget.onChanged(distances[value.toInt()]);
          },
        ),
      ],
    );
  }
}

class Maincheckbox extends StatefulWidget {
  final bool initialValue;
  final ValueChanged<bool> onChanged;
  final double size;
  final Color activeColor;
  final Color borderColor;
  final double borderRadius;

  const Maincheckbox({
    super.key,
    required this.initialValue,
    required this.onChanged,
    this.size = 22,
    this.activeColor = Colors.blue,
    this.borderColor = Colors.blue,
    this.borderRadius = 6,
  });

  @override
  State<Maincheckbox> createState() => MaincheckboxState();
}

class MaincheckboxState extends State<Maincheckbox> {
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

class MultiToggle extends StatefulWidget {
  final int initial;
  final List options;
  final Function(int) onChanged;

  const MultiToggle({
    super.key,
    required this.initial,
    required this.options,
    required this.onChanged,
  });

  @override
  State<MultiToggle> createState() => MultiToggleState();
}

class MultiToggleState extends State<MultiToggle> {
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
            color: active ? Colors.blue : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
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
        color: Colors.grey.shade200,
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

class VertMultiToggle extends StatefulWidget {
  final int initial;
  final List options;
  final Function(int) onChanged;

  const VertMultiToggle({
    super.key,
    required this.initial,
    required this.options,
    required this.onChanged,
  });

  @override
  State<VertMultiToggle> createState() => VertMultiToggleState();
}

class VertMultiToggleState extends State<VertMultiToggle> {
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
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: active ? Colors.blue : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
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
        color: Colors.grey.shade200,
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
      value: selected,
      decoration: InputDecoration(
        fillColor: AppColors.primary,
        focusColor: AppColors.secondary,
        labelText: widget.label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      items: widget.items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: HText(widget.display(item), color: AppColors.text),
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

//SPECIALISED WIDGETS
class BusinessBlock extends StatefulWidget {
  const BusinessBlock(
      {super.key, required this.businessLoc, this.scaleDown = 1});
  final BusinessLoc businessLoc;
  final double scaleDown;

  State<BusinessBlock> createState() => _BusinessBlockState();
}

class _BusinessBlockState extends State<BusinessBlock> {
  Widget bannerImage = Image.asset(
    "assets/img/kde.png",
    fit: BoxFit.cover,
  );

  @override
  void initState() {
    super.initState();
    // _load();
  }

  // Future<void> _load() async {
  //   final allImages =
  //       await businessManager.getLocationImages(widget.businessLoc.locId);
  //   if (allImages != null) {
  //     bannerImage = allImages[0];
  //   }

  //   if (!mounted) return;
  //   setState(() {});
  // }

  @override
  Widget build(BuildContext context) {
    log.i({
      "LOCID": widget.businessLoc.locId,
      "NAME": widget.businessLoc.name,
      "LOC": widget.businessLoc.location
    }.toString());
    // _load();
    return Material(
      color: AppColors.text,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () {
          changepage(
              context, () => BusinessLocPage(businessLoc: widget.businessLoc));
        },
        splashColor: Colors.black.withOpacity(0.05),
        highlightColor: Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 400 * 2 / widget.scaleDown,
          height: 200 * 2 / widget.scaleDown,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 30 / widget.scaleDown,
            children: [
              Row(
                spacing: 10 / widget.scaleDown,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(width: 20 / widget.scaleDown),
                  HText(
                    widget.businessLoc.name,
                    size: max(MediaQuery.of(context).size.width * 0.03, 17),
                  ),
                ],
              ),
              Row(
                spacing: 10 / widget.scaleDown,
                children: [
                  SizedBox(width: 20 / widget.scaleDown),
                  Expanded(child: bannerImage),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: 30 / widget.scaleDown),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: max(
                              MediaQuery.of(context).size.width * 0.03,
                              10,
                            ) /
                            2,
                        children: [
                          HText(
                            widget.businessLoc.desc ?? "123",
                            bold: FontWeight.w500,
                            size: max(
                              MediaQuery.of(context).size.width * 0.01,
                              8,
                            ),
                          ),
                          HText(
                            "${base_types[widget.businessLoc.primaryType]}",
                            bold: FontWeight.w500,
                            size: max(
                              MediaQuery.of(context).size.width * 0.01,
                              8,
                            ),
                          ),
                          HText(
                            "Rating: ${widget.businessLoc.meanRating ?? "No Ratings"}",
                            bold: FontWeight.w500,
                            size: max(
                              MediaQuery.of(context).size.width * 0.01,
                              8,
                            ),
                          ),
                          HText(
                            "Distance: ${KmTomiles((widget.businessLoc.distance * 1000)).toStringAsPrecision(4)} miles",
                            bold: FontWeight.w500,
                            size: max(
                              MediaQuery.of(context).size.width * 0.01,
                              8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//GLOBAL WIDGET FUNCTIONS
Widget bottombar(BuildContext context) {
  void homePageButtonLogic(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => MyHomePage(title: "Hi"),
        transitionsBuilder: (_, animation, __, child) {
          final slide = Tween(
            begin: Offset(0, 0.1),
            end: Offset.zero,
          ).animate(animation);

          final fade = Tween(begin: 0.0, end: 1.0).animate(animation);

          return SlideTransition(
            position: slide,
            child: FadeTransition(opacity: fade, child: child),
          );
        },
        transitionDuration: Duration(milliseconds: 250),
      ),
    );
  }

  void SearchButtonLogic(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => SearchPage(title: "Hi"),
        transitionsBuilder: (_, animation, __, child) {
          final slide = Tween(
            begin: Offset(0, 0.1),
            end: Offset.zero,
          ).animate(animation);

          final fade = Tween(begin: 0.0, end: 1.0).animate(animation);

          return SlideTransition(
            position: slide,
            child: FadeTransition(opacity: fade, child: child),
          );
        },
        transitionDuration: Duration(milliseconds: 250),
      ),
    );
  }

  Future<void> userButtonLogic(BuildContext context) async {
    if (await api.serverconnect.loggedIn()) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => UserPage(title: "Hi"),
          transitionsBuilder: (_, animation, __, child) {
            final slide = Tween(
              begin: Offset(0, 0.1),
              end: Offset.zero,
            ).animate(animation);

            final fade = Tween(begin: 0.0, end: 1.0).animate(animation);

            return SlideTransition(
              position: slide,
              child: FadeTransition(opacity: fade, child: child),
            );
          },
          transitionDuration: Duration(milliseconds: 250),
        ),
      );
    } else {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => LoginOrSignupPage(),
          transitionsBuilder: (_, animation, __, child) {
            final slide = Tween(
              begin: Offset(0, 0.1),
              end: Offset.zero,
            ).animate(animation);

            final fade = Tween(begin: 0.0, end: 1.0).animate(animation);

            return SlideTransition(
              position: slide,
              child: FadeTransition(opacity: fade, child: child),
            );
          },
          transitionDuration: Duration(milliseconds: 250),
        ),
      );
    }
  }

  return Padding(
    padding: const EdgeInsets.all(0),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(0),
      child: Container(
        height: 50,
        color: AppColors.text,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(Icons.search, color: Colors.white, size: 35),
              iconSize: 35,
              onPressed: () {
                SearchButtonLogic(context);
              },
            ),
            IconButton(
              icon: Icon(Icons.leaderboard, color: Colors.white, size: 35),
              iconSize: 35,
              onPressed: () {
                print("hu");
              },
            ),
            IconButton(
              icon: Icon(Icons.home, color: Colors.white, size: 35),
              iconSize: 35,
              onPressed: () {
                homePageButtonLogic(context);
              },
            ),
            IconButton(
              icon: Icon(Icons.star, color: Colors.white, size: 35),
              iconSize: 35,
              onPressed: () {
                print("hu");
              },
            ),
            IconButton(
              icon: Icon(Icons.person, color: Colors.white, size: 35),
              iconSize: 35,
              onPressed: () async {
                await userButtonLogic(context);
              },
            ),
          ],
        ),
      ),
    ),
  );
}

PreferredSize searchbar(BuildContext context) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(84),
    child: Column(
      children: [
        SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.all(10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              color: AppColors.text,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(width: 20),
                  Icon(Icons.search, color: Colors.white, size: 35),
                  Expanded(
                    child: MainInput(
                      hint: "business name or description",
                      controller: nameController,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.filter_alt, color: Colors.white, size: 35),
                    iconSize: 35,
                    onPressed: () => filterDropDown(context),
                  ),
                  SizedBox(width: 20),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

// PERSONAL FUNCTIONS
void filterDropDown(BuildContext context) {
  Arbitfallbacks();
  final distances = [1, 3, 5, 10, 15, 20, 30, 50];
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          spacing: 0,
          mainAxisSize: MainAxisSize.min,
          children: [
            HText("Filters", color: AppColors.text),
            SizedBox(height: 20 / 2),
            MultiToggle(
              onChanged: (isleft) {},
              initial: 0,
              options: ["Places", "Services"],
            ),
            SizedBox(height: 40 / 2),
            MainSlider(
              distances: distances,
              onChanged: (distance) {
                arbitStore.data["distance_index"] = distances.indexOf(distance);
                arbitStore.data["distance"] = milesToKm(
                  distance.toDouble(),
                ).toInt();
              },
              startValue: arbitStore.data["distance_index"],
            ),
            SizedBox(height: 20 / 2),
            Row(
              spacing: 20,
              children: [
                HText("Gas Safe Only", color: AppColors.text),
                Maincheckbox(
                  initialValue: arbitStore.data["gasSafeOnly"],
                  onChanged: (state) {
                    arbitStore.data["gasSafeOnly"] = state;
                  },
                ),
              ],
            ),
            SizedBox(height: 20 / 2),
            Row(
              spacing: 20,
              children: [
                HText("Electricity Safe Only", color: AppColors.text),
                Maincheckbox(
                  initialValue: arbitStore.data["electricitySafeOnly"],
                  onChanged: (state) {
                    arbitStore.data["electricitySafeOnly"] = state;
                  },
                ),
              ],
            ),
            SizedBox(height: 20 / 2),
            MultiToggle(
              initial: arbitStore.data["allowedBtypesINDEX"],
              options: ["Both", "Businesses", "Sole Traders"],
              onChanged: (val) {
                arbitStore.data["allowedBtypesINDEX"] = val;
                if (val == 0) {
                  arbitStore.data["allowedBtypes"] = "Both";
                }

                if (val == 1) {
                  arbitStore.data["allowedBtypes"] = "Businesses";
                }
                if (val == 2) {
                  arbitStore.data["allowedBtypes"] = "Sole Traders";
                }
              },
            ),
            SizedBox(height: 20 / 2),
            MainDropdown(
              items: base_types.keys.toList(),
              initialValue: arbitStore.data["categoryINDEX"],
              label: "Business Category",
              display: (value) => base_types[value]!,
              onChanged: (value) {
                arbitStore.data["category"] = base_types[value]!;
                arbitStore.data["categoryINDEX"] = value;
              },
            ),
            SizedBox(height: 20 / 2),
            SizedBox(
              width: 300,
              height: 80,
              child: ElevatedButton(
                onPressed: () {
                  changepage(context, () => SearchPage(title: "Hi"));
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 18, horizontal: 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: AppColors.primary,
                ),
                child: Text(
                  "Search",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20 / 2),
            MultiToggle(
              initial: arbitStore.data["sortingINDEX"],
              options: ["Distance", "Rating", "Query"],
              onChanged: (val) {
                arbitStore.data["sortingINDEX"] = val;
                if (val == 0) {
                  arbitStore.data["sorting"] = "DST";
                }

                if (val == 1) {
                  arbitStore.data["sorting"] = "RAT";
                }
                if (val == 2) {
                  arbitStore.data["sorting"] = " ";
                }
              },
            ),
          ],
        ),
      );
    },
  );
}

//GLOABL NORMAL FUNCTIONS
void changepage(BuildContext context, Widget Function() pageBuilder) {
  Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (_, __, ___) => pageBuilder(),
      transitionsBuilder: (_, animation, __, child) {
        final slide = Tween(
          begin: Offset(0, 0.1),
          end: Offset.zero,
        ).animate(animation);

        final fade = Tween(begin: 0.0, end: 1.0).animate(animation);

        return SlideTransition(
          position: slide,
          child: FadeTransition(opacity: fade, child: child),
        );
      },
      transitionDuration: Duration(milliseconds: 250),
    ),
  );
}
