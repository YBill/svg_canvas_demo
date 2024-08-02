import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:xml/xml.dart';

import 'my_painter.dart';

class SvgPage extends StatefulWidget {
  const SvgPage({super.key});

  @override
  State<SvgPage> createState() => _SvgPageState();
}

class _SvgPageState extends State<SvgPage> {
  List<Path> draws = [];
  List<Color> colors = [];
  List<Color> actualColors = [];

  double svgWidth = 0; // SVG的宽度
  double svgHeight = 0; // SVG的高度

  @override
  void initState() {
    super.initState();
    load().then((value) => setState(() {}));
  }

  Future<void> load() async {
    draws.clear();
    colors.clear();
    actualColors.clear();
    String assetName = 'assets/paintbynumbers.svg';
    String svg = await rootBundle.loadString(assetName);
    final document = XmlDocument.parse(svg);
    final svgRoot = document.rootElement;

    // 获取 SVG 宽度和高度
    String? width = svgRoot.getAttribute('width');
    String? height = svgRoot.getAttribute('height');
    svgWidth = width != null ? double.parse(width) : 0;
    svgHeight = height != null ? double.parse(height) : 0;

    Iterable<XmlElement> pathNodes = svgRoot.findAllElements('path');
    List<XmlElement> pathNodesList = pathNodes.toList();
    RegExp colorRegex = RegExp(r"#\w{6}");
    for (int i = 0; i < pathNodesList.length; i++) {
      XmlElement element = pathNodesList[i];
      String? d = element.getAttribute('d');
      final Path path = parseSvgPathData(d ?? '');
      draws.add(path);
      String? style = element.getAttribute('style');
      Color color = extractColor(colorRegex, style);
      actualColors.add(color);
      colors.add(getLighterColor(color));
    }
  }

  Color extractColor(RegExp colorRegex, String? style) {
    if (style != null) {
      // 使用正则表达式查找 fill 颜色
      final fillMatch = RegExp(r'fill:\s*rgb\((\d+),\s*(\d+),\s*(\d+)\);').firstMatch(style);
      if (fillMatch != null) {
        int r = int.parse(fillMatch.group(1)!);
        int g = int.parse(fillMatch.group(2)!);
        int b = int.parse(fillMatch.group(3)!);
        return Color.fromARGB(255, r, g, b); // 创建 Color 对象
      }

      // 如果没有找到 fill，检查 hex 颜色（如果存在）
      final match = colorRegex.firstMatch(style);
      if (match != null) {
        final colorStr = match.group(0);
        if (colorStr != null) {
          return Color(int.parse(colorStr.substring(1), radix: 16) + 0xFF000000);
        }
      }
    }
    return Colors.transparent;
  }

  Color getLighterColor(Color color) {
    final hslColor = HSLColor.fromColor(color);
    final lighterHslColor = hslColor.withLightness((hslColor.lightness + 1.0) / 2);
    return lighterHslColor.toColor();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    double scaleFactor = 1;
    double scaledWidth = 300;
    double scaledHeight = 300;
    if (!(svgWidth == 0 || svgHeight == 0)) {
      scaleFactor = min(screenSize.width / svgWidth, screenSize.height / svgHeight);
      scaledWidth = svgWidth * scaleFactor;
      scaledHeight = svgHeight * scaleFactor;
    }

    print('screenWidth = ${screenSize.width}, screenHeight = ${screenSize.height}, svgWidth = $svgWidth, svgHeight = $svgHeight, '
        'scaledWidth = $scaledWidth, scaledHeight = $scaledHeight, scaleFactor = $scaleFactor');

    return Scaffold(
      appBar: AppBar(
        title: const Text('SVG Page'),
      ),
      body: InteractiveViewer(
        child: GestureDetector(
          onTapUp: (TapUpDetails details) {
            Offset scaledPosition = Offset(
              details.localPosition.dx / scaleFactor,
              details.localPosition.dy / scaleFactor,
            );
            onTap(scaledPosition);
          },
          child: Center(
            child: RepaintBoundary(
              child: CustomPaint(
                size: Size(svgWidth, svgHeight),
                painter: MyPainter(draws, colors, scaleFactor),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> onTap(Offset offset) async {
    for (int i = 0; i < draws.length; i++) {
      Path path = draws[i];
      if (path.contains(offset)) {
        setState(() {
          colors[i] = actualColors[i];
        });
        return;
      }
    }
  }
}
