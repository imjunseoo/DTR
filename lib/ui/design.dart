import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

abstract final class DtrDesign {
  static const background = Color(0xFFFFF8ED),
      card = Color(0xFFFFFDF8),
      peach = Color(0xFFFFDBAD),
      soft = Color(0xFFF8EBDD),
      growthSoft = Color(0xFFF6EBDE),
      ink = Color(0xFF37251C),
      muted = Color(0xFF685044),
      accent = Color(0xFF983C17),
      border = Color(0xFF93745E);
  static TextStyle text(
    double size, {
    Color color = ink,
    FontWeight weight = FontWeight.w400,
    double? height,
  }) => TextStyle(
    fontSize: size,
    color: color,
    fontWeight: weight,
    height: height ?? 1.45,
  );
  static Widget asset(String name, double size) =>
      SvgPicture.asset('assets/figma/$name.svg', width: size, height: size);
  static BoxDecoration panel({
    Color color = card,
    double radius = 16,
    bool outlined = false,
  }) => BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(radius),
    border: outlined ? Border.all(color: border) : null,
  );
}

class DtrNavigation extends StatelessWidget {
  const DtrNavigation({
    super.key,
    required this.index,
    required this.onChanged,
  });
  final int index;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(5),
    decoration: DtrDesign.panel(
      color: index == 2 ? DtrDesign.growthSoft : DtrDesign.soft,
      radius: 23,
    ),
    child: Row(
      children: List.generate(
        4,
        (i) => Expanded(
          child: Semantics(
            selected: index == i,
            child: Material(
              color: index == i ? DtrDesign.peach : Colors.transparent,
              borderRadius: BorderRadius.circular(19),
              child: InkWell(
                borderRadius: BorderRadius.circular(19),
                onTap: () => onChanged(i),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (i == 0 &&
                          index == 0 &&
                          MediaQuery.sizeOf(context).width >= 390 &&
                          MediaQuery.textScalerOf(context).scale(14) <= 17) ...[
                        DtrDesign.asset('favorite', 17),
                        const SizedBox(width: 7),
                      ],
                      Flexible(
                        child: Text(
                          ['오늘', '내역', '성장', '대화'][i],
                          textAlign: TextAlign.center,
                          style: DtrDesign.text(
                            index == 2 ? 15 : 14,
                            color: index == i
                                ? DtrDesign.accent
                                : DtrDesign.muted,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class DtrHeader extends StatelessWidget {
  const DtrHeader(
    this.title, {
    super.key,
    this.back = false,
    this.trailing,
    this.onTitleLongPress,
  });
  final String title;
  final bool back;
  final Widget? trailing;
  final VoidCallback? onTitleLongPress;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: back ? 54 : 42,
    child: Row(
      children: [
        if (back)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Semantics(
              button: true,
              label: '뒤로',
              child: InkWell(
                onTap: () => Navigator.maybePop(context),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Text(
                    '‹',
                    style: DtrDesign.text(
                      26,
                      color: DtrDesign.accent,
                      weight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onLongPress: onTitleLongPress,
            child: Text(
              title,
              style: DtrDesign.text(22, weight: FontWeight.w700),
            ),
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

Widget dtrField(Widget child) => Container(
  decoration: DtrDesign.panel(radius: 9, outlined: true),
  constraints: const BoxConstraints(minHeight: 62),
  child: child,
);
