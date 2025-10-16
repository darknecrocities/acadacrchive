// lib/screens/analytics_screen.dart
import "package:flutter/material.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "package:intl/intl.dart";
import "package:fl_chart/fl_chart.dart";

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _resources = [];

  double _totalSizeMB = 0;
  Map<String, int> _fileTypeCounts = {};
  Map<String, int> _uploadsPerMonth = {};

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  Future<void> _fetchAnalytics() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // 1️⃣ Fetch file metadata from Supabase Storage (latest syntax)
      final List<FileObject> files =
      await supabase.storage.from("files").list(path: "uploads/${user.id}");

      if (files.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      // 2️⃣ Map metadata safely (Supabase returns FileObject, not JSON)
      _resources = files.map((file) {
        return {
          "name": file.name,
          // Supabase Storage doesn’t directly provide file size,
          // but we can fetch the signed URL and use a HEAD request (optional).
          // For now, use file.metadata?["size"] or default to 0.
          "size": (file.metadata?["size"] ?? 0) as int,
          // createdAt is already a String in some versions, or null in others.
          // Use file.createdAt if available; if not, default to now().
          "created_at": file.createdAt ?? DateTime.now().toIso8601String(),
        };
      }).toList();

      _processData();
    } catch (e) {
      debugPrint("Error fetching analytics: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }


  void _processData() {
    double totalMB = 0;
    Map<String, int> fileTypeCounts = {};
    Map<String, int> uploadsPerMonth = {};

    for (var file in _resources) {
      final name = (file["name"] ?? "").toString();
      final type = name.split(".").last.toUpperCase();

      // 1️⃣ Count file types
      fileTypeCounts[type] = (fileTypeCounts[type] ?? 0) + 1;

      // 2️⃣ Compute total size
      final sizeBytes = (file["size"] ?? 0) as int;
      totalMB += sizeBytes / (1024 * 1024);

      // 3️⃣ Track upload date (month)
      final uploadedAt = DateTime.tryParse(file["created_at"] ?? "");
      if (uploadedAt != null) {
        final month = DateFormat("MMM yyyy").format(uploadedAt);
        uploadsPerMonth[month] = (uploadsPerMonth[month] ?? 0) + 1;
      }
    }

    setState(() {
      _totalSizeMB = totalMB;
      _fileTypeCounts = fileTypeCounts;
      _uploadsPerMonth = uploadsPerMonth;
    });
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.blueAccent),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 24),
        const Center(
          child: Text(
            "Analytics Dashboard",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            "Track your upload trends and file statistics",
            style: TextStyle(color: Colors.grey[700], fontSize: 14),
          ),
        ),
        const SizedBox(height: 24),

        // Summary Cards
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSummaryCard("Total Uploads", "${_resources.length} files", Icons.file_present),
            _buildSummaryCard("Storage Used", "${_totalSizeMB.toStringAsFixed(2)} MB", Icons.storage),
          ],
        ),
        const SizedBox(height: 32),

        // Bar Chart: File Type Distribution
        const Text(
          "File Type Distribution",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        SizedBox(height: 220, child: _buildFileTypeBarChart()),
        const SizedBox(height: 32),

        // Line Chart: Upload Trends
        const Text(
          "Upload Trend Over Time",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        SizedBox(height: 250, child: _buildUploadTrendLineChart()),
        const SizedBox(height: 32),
        // Pie Chart: Storage Usage by File Type
        const Text(
          "Storage Usage by File Type",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        SizedBox(height: 250, child: _buildStorageByTypePieChart()),
        const SizedBox(height: 32),

// Heatmap: Uploads by Day of Week
        const Text(
          "Uploads by Day of the Week",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        _buildUploadsByDayHeatmap(),
        const SizedBox(height: 32),

      ]),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: 160,
      decoration: BoxDecoration(
        color: Colors.white, // always white card
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black12)],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.blueAccent, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black, // ✅ force black text
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black, // ✅ force black text
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildFileTypeBarChart() {
    final barData = _fileTypeCounts.entries.toList();
    if (barData.isEmpty) return const Center(child: Text("No data available"));

    return BarChart(
      BarChartData(
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                final index = value.toInt();
                if (index < 0 || index >= barData.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(barData[index].key, style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
        ),
        barGroups: barData.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.value.toDouble(),
                width: 18,
                borderRadius: BorderRadius.circular(6),
                color: Colors.blueAccent,
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUploadTrendLineChart() {
    final sortedEntries = _uploadsPerMonth.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    if (sortedEntries.isEmpty) return const Center(child: Text("No upload trend data"));

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                int index = value.toInt();
                if (index < 0 || index >= sortedEntries.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    sortedEntries[index].key.split(" ").first,
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            spots: List.generate(
              sortedEntries.length,
                  (i) => FlSpot(i.toDouble(), sortedEntries[i].value.toDouble()),
            ),
            color: Colors.blueAccent,
            barWidth: 3,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }
  // 1️⃣ Pie Chart: Storage Usage by File Type
  Widget _buildStorageByTypePieChart() {
    if (_fileTypeCounts.isEmpty) return const Center(child: Text("No data available"));

    final total = _fileTypeCounts.values.fold<int>(0, (a, b) => a + b);
    final sections = _fileTypeCounts.entries.map((e) {
      final percentage = (e.value / total) * 100;
      return PieChartSectionData(
        value: e.value.toDouble(),
        color: Colors.primaries[e.key.hashCode % Colors.primaries.length],
        title: "${e.key}\n${percentage.toStringAsFixed(1)}%",
        radius: 60,
        titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return PieChart(PieChartData(
      sections: sections,
      centerSpaceRadius: 40,
      sectionsSpace: 2,
    ));
  }

// 2️⃣ Horizontal Bar Chart: Top 5 Largest Files
  Widget _buildTopFilesChart() {
    if (_resources.isEmpty) return const Center(child: Text("No data available"));

    final topFiles = List<Map<String, dynamic>>.from(_resources)
      ..sort((a, b) => (b["size"] ?? 0).compareTo(a["size"] ?? 0));
    final top5 = topFiles.take(5).toList();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 80,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= top5.length) return const SizedBox();
                return Text(
                  top5[index]["name"],
                  style: const TextStyle(fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                );
              },
            ),
          ),
          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups: List.generate(top5.length, (i) {
          final sizeMB = ((top5[i]["size"] ?? 0) / (1024 * 1024));
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: sizeMB,
                color: Colors.teal,
                width: 14,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          );
        }),
      ),
    );
  }

// 3️⃣ Grid Heatmap: Uploads by Day of Week
  Widget _buildUploadsByDayHeatmap() {
    if (_resources.isEmpty) return const Center(child: Text("No data available"));

    final Map<String, int> dayCounts = {
      "Mon": 0,
      "Tue": 0,
      "Wed": 0,
      "Thu": 0,
      "Fri": 0,
      "Sat": 0,
      "Sun": 0,
    };

    for (var file in _resources) {
      final uploadedAt = DateTime.tryParse(file["created_at"] ?? "");
      if (uploadedAt != null) {
        final day = DateFormat("E").format(uploadedAt);
        if (dayCounts.containsKey(day)) {
          dayCounts[day] = (dayCounts[day] ?? 0) + 1;
        }
      }
    }

    final maxCount = dayCounts.values.fold<int>(0, (a, b) => a > b ? a : b);

    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 7,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      physics: const NeverScrollableScrollPhysics(),
      children: dayCounts.entries.map((e) {
        final intensity = maxCount == 0 ? 0.0 : e.value / maxCount.toDouble();
        return Container(
          decoration: BoxDecoration(
            color: Color.lerp(Colors.grey[300], Colors.blueAccent, intensity),
            borderRadius: BorderRadius.circular(8),
          ),
        child: Center(
            child: Text(
              "${e.key}\n${e.value}",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }).toList(),
    );
  }

}
