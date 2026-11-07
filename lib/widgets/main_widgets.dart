import 'package:flutter/material.dart';
import 'package:nextfind/helpers/conversions.dart';
import 'package:nextfind/helpers/debug_options.dart';
import 'package:nextfind/helpers/networking.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:nextfind/services/search_services.dart';
import 'package:nextfind/widgets/text_widgets.dart';

export 'package:nextfind/widgets/text_widgets.dart';

class AppColors {
  static const background = Color.fromARGB(255, 1, 29, 0);
  static const leveled = Color.fromARGB(255, 25, 44, 0);
  static const secondaryLeveled = Color.fromARGB(255, 37, 65, 0);
  // fromARGB(255, 255, 255, 255);

  static const text = Color.fromARGB(255, 255, 255, 255);
  static const secondaryText = Color.fromARGB(255, 163, 222, 0);
  static const highlightText = Color.fromARGB(255, 187, 255, 0);

  static const primary = Color.fromARGB(255, 55, 98, 0);
  static const secondary = Color.fromARGB(255, 101, 44, 145);
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
      width: width,
      height: height,
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
      this.color = AppColors.text,
      this.size = 18.0,
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
      cursorColor: AppColors.secondaryLeveled,
      controller: widget.controller,
      onSubmitted: (value) {
        if (widget.onSubmitted != null) {
          widget.onSubmitted!(value);
        }
      },
      decoration: InputDecoration(
        alignLabelWithHint: true,
        hintText: widget.hint,
        hintStyle: TextStyle(
          fontSize: widget.size,
          fontWeight: FontWeight.w800,
          fontFamily: "Montserrat",
          color: const Color.fromARGB(103, 187, 255, 0),
        ),
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
      style: TextStyle(
        fontSize: widget.size,
        fontWeight: FontWeight.w800,
        fontFamily: "Montserrat",
        color: widget.color,
      ),
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

    if (widget.url == "No Url" ||
        NextfindDebugOptions.keepAllNetworkImagesAsDefault) {
      provider = const AssetImage("assets/img/kde.png");
    } else {
      final trueUrl = Networking.getFullImageUrl(widget.url);
      provider = CachedNetworkImageProvider(trueUrl);
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

    // final bool isOne = (distances[sliderValue.toInt()] == 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 5,
      children: [
        ValueListenableBuilder(
            valueListenable: SearchServices.isMetric,
            builder: (_, isMetric, ___) {
              return LabelText(
                isMetric
                    ? "Search within ${milesToKm(distances[sliderValue.toInt()].toDouble()).round()} Kilometers"
                    : (distances[sliderValue.toInt()] == 1)
                        ? "Search within ${distances[sliderValue.toInt()]} mile"
                        : "Search within ${distances[sliderValue.toInt()]} miles",
                color: AppColors.text,
              );
            }),
        Slider(
          activeColor: AppColors.highlightText,
          value: sliderValue.toDouble(),
          min: 0,
          max: (distances.length - 1).toDouble(),
          divisions: distances.length - 1,
          // label: "${distances[sliderValue.toInt()]} miles",
          onChanged: (value) {
            setState(() => sliderValue = value.toInt());
            widget.onChanged(value.toInt());
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
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: MyText(
              label,
              size: 15,
              fontWeight: active ? FontWeight.w700 : FontWeight.w600,
              color: active ? AppColors.text : AppColors.secondaryText,
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
        color: AppColors.secondaryLeveled,
        borderRadius: BorderRadius.circular(10),
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
