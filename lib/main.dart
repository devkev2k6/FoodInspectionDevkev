import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shimmer/shimmer.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kitchen Quality Inspector',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00796B),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Kitchen AI Inspector'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  // ---------------------------------------------------------------------------
  // API key — loaded from --dart-define at build/run time.
  // Usage:  flutter run --dart-define=GEMINI_KEY=YOUR_KEY_HERE
  // The defaultValue is a dev-only fallback; remove it before releasing.
  // ---------------------------------------------------------------------------
  static const _apiKey = String.fromEnvironment(
    'GEMINI_KEY',
    defaultValue: 'AIzaSyA_aBbyfZztST2bqkDQdzE7Sr7dki4UMoQ',
  );

  final _model = GenerativeModel(
    model: 'gemini-2.0-flash',
    apiKey: _apiKey,
  );

  bool _isLoading = false;

  final List<Map<String, dynamic>> _scanHistory = [];

  late final AnimationController _fabPulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _fabPulse.dispose();
    super.dispose();
  }

  // ── Core logic ──────────────────────────────────────────────────────────────

  Future<void> _analyzeFoodQuality() async {
    final picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (photo == null) return;

    setState(() => _isLoading = true);

    try {
      final imageBytes = await photo.readAsBytes();

      const prompt = '''
You are a professional kitchen hygiene and food-quality inspector with 20 years of experience.
Analyse this image of a food plate or kitchen item and respond ONLY with valid JSON — no markdown, no extra text.

Format:
{
  "pass": true or false,
  "score": 0-100,
  "summary": "One concise sentence verdict.",
  "issues": ["Issue 1", "Issue 2"],
  "recommendations": ["Rec 1", "Rec 2"]
}

Criteria: freshness, colour, contamination, plating hygiene, portion presentation.
Be strict — safety first.
''';

      final response = await _model.generateContent([
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ]),
      ]);

      final rawText = response.text ?? '{}';
      final parsed  = _parseGeminiJson(rawText);

      final isPass  = (parsed['pass']    as bool?)   ?? false;
      final score   = (parsed['score']   as int?)    ?? 0;
      final summary = (parsed['summary'] as String?) ?? 'No summary available.';
      final issues  = List<String>.from(parsed['issues']          as List? ?? []);
      final recs    = List<String>.from(parsed['recommendations'] as List? ?? []);

      final now     = TimeOfDay.now();
      final timeStr =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      setState(() {
        _scanHistory.insert(0, {
          'image':           imageBytes,
          'result':          summary,
          'isPass':          isPass,
          'score':           score,
          'issues':          issues,
          'recommendations': recs,
          'time':            timeStr,
        });
      });
    } catch (e) {
      _showErrorSnackBar('Analysis failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Strips optional ```json fences then decodes the JSON object.
  Map<String, dynamic> _parseGeminiJson(String raw) {
    try {
      final cleaned = raw
          .replaceAll(RegExp(r'```json\s*'), '')
          .replaceAll(RegExp(r'```\s*'), '')
          .trim();
      return jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  void _showErrorSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.restaurant_menu, size: 22),
            const SizedBox(width: 8),
            Text(
              widget.title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
          ],
        ),
        actions: [
          if (_scanHistory.isNotEmpty)
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_scanHistory.length} scan${_scanHistory.length > 1 ? 's' : ''}',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_scanHistory.isNotEmpty) _buildStatsBanner(),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: _isLoading
                ? Padding(
                    key: const ValueKey('shimmer'),
                    padding: const EdgeInsets.all(16),
                    child: _buildShimmerLoading(),
                  )
                : _scanHistory.isEmpty
                    ? _buildEmptyState()
                    : Padding(
                        key: ValueKey(_scanHistory.first['time']),
                        padding: const EdgeInsets.all(16),
                        child: _buildCurrentResultCard(_scanHistory.first),
                      ),
          ),
          if (_scanHistory.length > 1) ...[
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.history, size: 18, color: cs.primary),
                  const SizedBox(width: 6),
                  Text(
                    "Today's History",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _scanHistory.length - 1,
                itemBuilder: (ctx, index) =>
                    _buildHistoryTile(_scanHistory[index + 1]),
              ),
            ),
          ] else
            const Spacer(),
        ],
      ),
      floatingActionButton: _buildFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // ── UI helpers ──────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Padding(
      key: const ValueKey('empty'),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.camera_alt_outlined,
                size: 64, color: Colors.teal.shade400),
          ),
          const SizedBox(height: 24),
          const Text(
            'Ready to Inspect',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Scan Plate" to analyse a dish or kitchen item with AI.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBanner() {
    final passes   = _scanHistory.where((e) => e['isPass'] == true).length;
    final fails    = _scanHistory.length - passes;
    final avgScore = _scanHistory
            .map((e) => (e['score'] as int? ?? 0))
            .fold(0, (a, b) => a + b) ~/
        _scanHistory.length;

    return Container(
      color: Colors.teal.shade700,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statChip(Icons.check_circle_outline, '$passes', 'Passed',     Colors.greenAccent),
          _statChip(Icons.cancel_outlined,       '$fails',  'Failed',     Colors.redAccent),
          _statChip(Icons.speed,                 '$avgScore','Avg Score',  Colors.amberAccent),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String value, String label, Color accent) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: accent, size: 16),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                  color: accent, fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor:      Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildCurrentResultCard(Map<String, dynamic> item) {
    final isPass = item['isPass'] as bool;
    final score  = item['score']  as int?          ?? 0;
    final issues = item['issues'] as List<String>? ?? [];
    final recs   = item['recommendations'] as List<String>? ?? [];

    return Card(
      elevation: 6,
      shadowColor:
          isPass ? Colors.green.shade200 : Colors.red.shade200,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header band
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isPass ? Colors.green.shade600 : Colors.red.shade600,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(isPass ? Icons.check_circle : Icons.cancel,
                    color: Colors.white, size: 26),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isPass ? 'INSPECTION PASSED' : 'INSPECTION FAILED',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$score/100',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                ),
              ],
            ),
          ),

          // Scanned image
          ClipRRect(
            child: Image.memory(
              item['image'] as Uint8List,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          // Result body
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['result'] as String,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500)),
                if (issues.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _sectionLabel('Issues Found', Colors.red.shade700),
                  ...issues.map((i) => _bulletRow(i, Colors.red.shade400)),
                ],
                if (recs.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _sectionLabel('Recommendations', Colors.teal.shade700),
                  ...recs.map((r) => _bulletRow(r, Colors.teal.shade400)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text, Color color) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text(
          text,
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700, color: color),
        ),
      );

  Widget _bulletRow(String text, Color dotColor) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 5, right: 6),
              child: CircleAvatar(radius: 3, backgroundColor: dotColor),
            ),
            Expanded(
                child: Text(text, style: const TextStyle(fontSize: 13))),
          ],
        ),
      );

  Widget _buildHistoryTile(Map<String, dynamic> item) {
    final isPass = item['isPass'] as bool;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                item['image'] as Uint8List,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: CircleAvatar(
                radius: 8,
                backgroundColor: isPass ? Colors.green : Colors.red,
                child: Icon(isPass ? Icons.check : Icons.close,
                    size: 10, color: Colors.white),
              ),
            ),
          ],
        ),
        title: Text(
          isPass
              ? '✅ PASS — ${item['score']}/100'
              : '❌ FAIL — ${item['score']}/100',
          style: TextStyle(
            color:
                isPass ? Colors.green.shade700 : Colors.red.shade700,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        subtitle: Text(
          item['result'] as String,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Text(
          item['time'] as String,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        onTap: () => _showDetailSheet(item),
      ),
    );
  }

  void _showDetailSheet(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: .6,
        minChildSize: .4,
        maxChildSize: .9,
        expand: false,
        builder: (_, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(20),
          child: _buildCurrentResultCard(item),
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return AnimatedBuilder(
      animation: _fabPulse,
      builder: (_, child) => Transform.scale(
        scale: _isLoading ? 1.0 + _fabPulse.value * 0.06 : 1.0,
        child: child,
      ),
      child: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _analyzeFoodQuality,
        backgroundColor:
            _isLoading ? Colors.grey : Colors.teal.shade700,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5))
            : const Icon(Icons.camera_alt, color: Colors.white),
        label: Text(
          _isLoading ? 'Analysing…' : 'Scan Plate',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}