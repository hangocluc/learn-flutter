import 'package:learn_flutter/common/theme/app_color.dart';
import 'package:flutter/material.dart';
import '../../theme/app_typography.dart';

class ChartPainter extends CustomPainter {
  final List<double> data;
  final int numPoints;

  ChartPainter({super.repaint, required this.data, required this.numPoints})
      : assert(numPoints < data.length); // Ensure numPoints < data.length

  @override
  void paint(Canvas canvas, Size size) {
    const double padding = 40.0; // Space for axes and labels
    final double chartWidth = size.width - padding;
    final double chartHeight = size.height - padding;

    // Calculate max value of data and round it up to the nearest 10 or 100
    double maxDataValue = data.reduce((a, b) => a > b ? a : b);
    double yMax =
        roundToNearestSignificant(maxDataValue); // Round to nearest ten

    // If max value is large, round to the nearest hundred
    int step;
    if (yMax <= 15) {
      step = 1;
    } else if (yMax < 110) {
      step = 10;
    } else if (yMax < 1100) {
      step = 100;
    } else {
      step = 1000;
    }
    // Scaling factor for Y-axis
    final double yScale = chartHeight / yMax;

    // X-axis step size
    final double xStep = chartWidth / (data.length - 1);

    // Draw grid lines
    final Paint gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1.0;

    for (double y = 0; y <= yMax; y += step) {
      final double yPos = chartHeight - y * yScale + padding / 2;
      canvas.drawLine(
        Offset(padding / 2, yPos),
        Offset(size.width - padding / 2, yPos),
        gridPaint,
      );
    }

    // Draw axes
    final Paint axisPaint = Paint()
      ..color = AppColors.theBlack.theBlack400
      ..strokeWidth = 1.0;

    // X-axis
    canvas.drawLine(
      Offset(padding / 2, size.height - padding / 2),
      Offset(size.width - padding / 2, size.height - padding / 2),
      axisPaint,
    );

    // Draw curve (line chart)
    final Paint curvePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final Path curvePath = Path();

    for (int i = 0; i < data.length - 1; i++) {
      final double x1 = i * xStep + padding / 2;
      final double y1 = chartHeight - data[i] * yScale + padding / 2;
      final double x2 = (i + 1) * xStep + padding / 2;
      final double y2 = chartHeight - data[i + 1] * yScale + padding / 2;

      if (i == 0) {
        curvePath.moveTo(x1, y1);
      }

      // Using cubic Bézier curves to create a smooth line
      final double controlPoint1X = x1 + (x2 - x1) / 2;
      final double controlPoint1Y = y1;
      final double controlPoint2X = x1 + (x2 - x1) / 2;
      final double controlPoint2Y = y2;

      curvePath.cubicTo(controlPoint1X, controlPoint1Y, controlPoint2X,
          controlPoint2Y, x2, y2);
    }

    canvas.drawPath(curvePath, curvePaint);

    // Highlight specific data points (evenly spaced with space around them)
    // final Paint markerPaint = Paint()
    //   ..color = Colors.black
    //   ..style = PaintingStyle.fill;

    // List<int> selectedIndices = _getSpaceAroundIndices(numPoints);

    // for (int i in selectedIndices) {
    //   final double x = i * xStep + padding / 2;
    //   final double y = chartHeight - data[i] * yScale + padding / 2;
    //   canvas.drawCircle(Offset(x, y), 5.0, markerPaint); // Inner circle
    //   canvas.drawCircle(Offset(x, y), 10.0, curvePaint); // Outer circle
    // }

    // Create a gradient for each line drawn from data point to the X-axis
    // const Gradient gradient = LinearGradient(
    //   colors: [Colors.blue, Colors.transparent],
    //   begin: Alignment.topCenter,
    //   end: Alignment.bottomCenter,
    // );

    // final Paint gradientPaint = Paint()
    //   ..shader = gradient.createShader(Rect.fromPoints(
    //     const Offset(0, 0),
    //     Offset(0, chartHeight),
    //   ))
    //   ..strokeWidth = 3.0;

    // Draw gradient lines from specific points down to the X-axis
    // for (int i in selectedIndices) {
    //   final double x = i * xStep + padding / 2;
    //   final double y = chartHeight - data[i] * yScale + padding / 2;

    //   // Draw gradient line from data point to X-axis
    //   canvas.drawLine(
    //     Offset(x, y),
    //     Offset(x, size.height - padding / 2), // To the X-axis
    //     gradientPaint,
    //   );
    // }

    // Add labels at the bottom corresponding to the highlighted points
    final TextPainter textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    // for (int i = 0; i < selectedIndices.length; i++) {
    //   final int index = selectedIndices[i];
    //   final double x = index * xStep + padding / 2;
    //   final double y = size.height - padding / 3;

    //   // Show actual value from the data at the selected index
    //   textPainter.text = TextSpan(
    //     text: data[index].toStringAsFixed(
    //         0), // Display the data value rounded to nearest integer
    //     style: const TextStyle(color: Colors.black, fontSize: 12),
    //   );
    //   textPainter.layout();
    //   textPainter.paint(
    //     canvas,
    //     Offset(x - textPainter.width / 2, y),
    //   );
    // }

    // Draw Y-axis labels
    for (double y = 0; y <= yMax; y += step) {
      final double yPos = chartHeight - y * yScale + padding / 2;
      textPainter.text = TextSpan(
        text: y == 0 ? '0' : '${y.toInt()} ${'Text'}',
        style: AppTypography().bodyXSmallRegular.copyWith(
              color: AppColors.theBlack.theBlack600,
            ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
            padding / 4 - textPainter.width / 2, yPos - textPainter.height / 2),
      );
    }
  }

  // Get indices of points spaced evenly with space before and after
  // List<int> _getSpaceAroundIndices(int numPoints) {
  //   List<int> indices = [];
  //   double step =
  //       (data.length - 1) / (numPoints + 1); // Space around the points
  //   for (int i = 0; i < numPoints; i++) {
  //     indices.add(((i + 1) * step).round()); // Space around using (i + 1)
  //   }
  //   return indices;
  // }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

double roundToNearestSignificant(double number) {
  return (number / stepForRound(number)).ceil() *
      stepForRound(number).toDouble();
}

int stepForRound(double value) {
  int step;
  if (value <= 15) {
    step = 1;
  } else if (value < 110) {
    step = 10;
  } else if (value < 1100) {
    step = 100;
  } else {
    step = 1000;
  }
  return step;
}
