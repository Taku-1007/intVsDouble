import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'int VS double',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSwatch().copyWith(primary: Colors.blue),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade300),
          ),
        ),
      ),
      home: const PerformanceTestPage(),
    );
  }
}

class PerformanceTestPage extends StatefulWidget {
  const PerformanceTestPage({super.key});

  @override
  State<PerformanceTestPage> createState() => _PerformanceTestPageState();
}

class _PerformanceTestPageState extends State<PerformanceTestPage>
    with SingleTickerProviderStateMixin {
  List<FlSpot> doubleTimes = [];
  List<FlSpot> intTimes = [];
  List<double> differences = [];
  int runCount = 0;

  late AnimationController _controller;
  bool isRunning = false;

  /// 平均速度差（double - int）の平均を取得
  double get averageDifference {
    if (differences.isEmpty) return 0;
    return differences.reduce((a, b) => a + b) / differences.length;
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  /// 実際のパフォーマンステストを1回だけ実行し、結果をデータに反映
  Future<void> _singlePerformanceTest() async {
    final int count = 1000000;
    final stopwatch = Stopwatch();

    // ウォームアップ
    for (int i = 0; i < 1000; i++) {
      List<double> warmup = List.generate(1000, (index) => index.toDouble());
      for (int j = 0; j < warmup.length; j++) {
        warmup[j] = warmup[j] * 2;
      }
    }

    // double型テスト
    stopwatch.start();
    List<double> doubleNumbers = List.generate(
      count,
      (index) => index.toDouble(),
    );
    for (int i = 0; i < count; i++) {
      doubleNumbers[i] = doubleNumbers[i] * 2;
    }
    stopwatch.stop();
    final doubleTime = stopwatch.elapsedMilliseconds.toDouble();

    // int型テスト
    stopwatch.reset();
    stopwatch.start();
    List<int> intNumbers = List.generate(count, (index) => index);
    for (int i = 0; i < count; i++) {
      intNumbers[i] = intNumbers[i] * 2;
    }
    stopwatch.stop();
    final intTime = stopwatch.elapsedMilliseconds.toDouble();

    // 計測結果をグラフ描画用に追加
    setState(() {
      runCount++;
      doubleTimes.add(FlSpot(runCount.toDouble(), doubleTime));
      intTimes.add(FlSpot(runCount.toDouble(), intTime));
      differences.add(doubleTime - intTime);
      _controller.forward(from: 0);
    });
  }

  /// ボタン押下時に複数回のテストをまとめて実行する
  Future<void> _runMultipleTests(int times) async {
    if (isRunning) return;
    setState(() {
      isRunning = true;
    });
    for (int i = 0; i < times; i++) {
      await _singlePerformanceTest();
    }
    setState(() {
      isRunning = false;
    });
  }

  /// 初期化関数 - テスト結果とカウントをクリアする
  void _resetTest() {
    setState(() {
      doubleTimes.clear();
      intTimes.clear();
      differences.clear();
      runCount = 0;
      _controller.reset();
    });
  }

  /// グラフの描画データ設定
  LineChartData _buildChartData() {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 50,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
            dashArray: [5, 5],
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 50,
            reservedSize: 42,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toInt().toString(),
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: runCount > 50 ? 10.0 : (runCount > 20 ? 5.0 : 1.0),
            reservedSize: 22,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toInt().toString(),
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.grey.shade300),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: doubleTimes,
          isCurved: true,
          color: Colors.red,
          barWidth: 2,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: Colors.red,
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.red.withOpacity(0.05),
          ),
        ),
        LineChartBarData(
          spots: intTimes,
          isCurved: true,
          color: Colors.green,
          barWidth: 2,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: Colors.green,
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.green.withOpacity(0.05),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('数値型パフォーマンス分析'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            /// 上段カード: 実行回数 & 平均速度差
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            '実行回数',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          runCount >= 50
                              ? SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Text(
                                  runCount.toString().replaceAllMapped(
                                    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                    (Match m) => '${m[1]},',
                                  ),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                              : FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  runCount.toString().replaceAllMapped(
                                    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                    (Match m) => '${m[1]},',
                                  ),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            '平均速度差',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${averageDifference.toStringAsFixed(1)}ms',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            /// パフォーマンス分析・実行ボタン
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'パフォーマンス分析',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'int型とdouble型の処理速度を比較',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildExperimentButton(
                          label: '1回実行',
                          icon: Icons.science,
                          onPressed: () => _runMultipleTests(1),
                        ),
                        _buildExperimentButton(
                          label: '10回実行',
                          icon: Icons.science_outlined,
                          onPressed: () => _runMultipleTests(10),
                        ),
                        _buildExperimentButton(
                          label: '20回実行',
                          icon: Icons.biotech,
                          onPressed: () => _runMultipleTests(20),
                        ),
                        _buildExperimentButton(
                          label: '初期化',
                          icon: Icons.refresh,
                          onPressed: _resetTest,
                        ),
                      ],
                    ),
                    if (differences.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildMetricItem(
                            'Last Run Diff',
                            '${differences.last.toStringAsFixed(1)}ms',
                            icon: Icons.timer_outlined,
                          ),
                          _buildMetricItem(
                            'Min Diff',
                            '${differences.reduce(math.min).toStringAsFixed(1)}ms',
                            icon: Icons.arrow_downward,
                          ),
                          _buildMetricItem(
                            'Max Diff',
                            '${differences.reduce(math.max).toStringAsFixed(1)}ms',
                            icon: Icons.arrow_upward,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            /// グラフ表示
            Expanded(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return runCount > 30
                      ? SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: math.max(
                            MediaQuery.of(context).size.width - 32,
                            runCount * 15.0,
                          ),
                          child: Transform.scale(
                            scale: 1.0 + (_controller.value * 0.02),
                            child: LineChart(_buildChartData()),
                          ),
                        ),
                      )
                      : Transform.scale(
                        scale: 1.0 + (_controller.value * 0.02),
                        child: LineChart(_buildChartData()),
                      );
                },
              ),
            ),
            const SizedBox(height: 16),

            /// 凡例表示
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem('double', Colors.red),
                    const SizedBox(width: 24),
                    _buildLegendItem('int', Colors.green),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 計測結果のラベルなどを表示する小パーツ
  Widget _buildMetricItem(String label, String value, {IconData? icon}) {
    return Column(
      children: [
        if (icon != null) Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  /// 実験用ボタンウィジェット
  Widget _buildExperimentButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: isRunning ? null : onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.blue.shade700,
        backgroundColor: Colors.blue.shade50,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }

  /// グラフの凡例表示用
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}
