import 'package:flutter/material.dart';
import 'services/generation_service.dart';

void main() => runApp(const KamnderAiApp());

class KamnderAiApp extends StatelessWidget {
  const KamnderAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KAMNDER AI',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF07070A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C4DFF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _open(BuildContext context, String mode, String title, IconData icon) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GenerationPage(mode: mode, title: title, icon: icon),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KAMNDER AI', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 20),
            const Text('Create with AI', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Text('Turn your ideas into images and videos.', textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 16)),
            const SizedBox(height: 32),
            _CreateCard(icon: Icons.image_outlined, title: 'Text → Image',
                subtitle: 'Create an image from your prompt',
                onTap: () => _open(context, 'text_to_image', 'Text → Image', Icons.image_outlined)),
            const SizedBox(height: 14),
            _CreateCard(icon: Icons.movie_creation_outlined, title: 'Text → Video',
                subtitle: 'Create a cinematic video from text',
                onTap: () => _open(context, 'text_to_video', 'Text → Video', Icons.movie_creation_outlined)),
            const SizedBox(height: 14),
            _CreateCard(icon: Icons.photo_camera_back_outlined, title: 'Image → Video',
                subtitle: 'Animate an image with AI',
                onTap: () => _open(context, 'image_to_video', 'Image → Video', Icons.photo_camera_back_outlined)),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white12)),
              child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Engine', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Open-source generation backend • Wan-ready'),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class GenerationPage extends StatefulWidget {
  final String mode;
  final String title;
  final IconData icon;
  const GenerationPage({super.key, required this.mode, required this.title, required this.icon});

  @override
  State<GenerationPage> createState() => _GenerationPageState();
}

class _GenerationPageState extends State<GenerationPage> {
  final _prompt = TextEditingController();
  final _imageUrl = TextEditingController();
  bool _loading = false;
  String? _result;
  String? _error;

  @override
  void dispose() {
    _prompt.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final prompt = _prompt.text.trim();
    if (prompt.isEmpty) {
      setState(() => _error = 'اكتب وصفًا أولًا.');
      return;
    }
    setState(() { _loading = true; _error = null; _result = null; });
    try {
      const baseUrl = String.fromEnvironment('GENERATION_API_URL', defaultValue: '');
      if (baseUrl.isEmpty) {
        throw Exception('لم يتم ربط خادم التوليد بعد.');
      }
      final result = await const GenerationService(baseUrl: baseUrl).submit(
        mode: widget.mode,
        prompt: prompt,
        imageUrl: widget.mode == 'image_to_video' ? _imageUrl.text.trim() : null,
      );
      setState(() => _result = result['output_url']?.toString() ?? result.toString());
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageMode = widget.mode == 'text_to_image';
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Icon(widget.icon, size: 64),
          const SizedBox(height: 20),
          TextField(
            controller: _prompt,
            maxLines: 6,
            decoration: InputDecoration(
              labelText: imageMode ? 'وصف الصورة' : 'وصف ما تريد توليده',
              hintText: 'مثال: مدينة مستقبلية ليلًا بأسلوب سينمائي...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          if (widget.mode == 'image_to_video') ...[
            const SizedBox(height: 14),
            TextField(
              controller: _imageUrl,
              decoration: InputDecoration(
                labelText: 'رابط الصورة المصدر',
                hintText: 'https://...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _loading ? null : _generate,
            icon: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.auto_awesome),
            label: Text(_loading ? 'جاري التوليد...' : 'توليد الآن'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 18),
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          ],
          if (_result != null) ...[
            const SizedBox(height: 18),
            SelectableText('النتيجة:\n$_result'),
          ],
          const SizedBox(height: 24),
          Text('الإخراج المستهدف للفيديو: 700p / 30 FPS عند دعم الخادم.',
              style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}

class _CreateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _CreateCard({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(children: [
            Icon(icon, size: 36),
            const SizedBox(width: 18),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 5),
              Text(subtitle, style: TextStyle(color: Colors.grey.shade400)),
            ])),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ]),
        ),
      ),
    );
  }
}
