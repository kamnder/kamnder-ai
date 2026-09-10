import 'package:flutter/material.dart';

void main() {
  runApp(const KamnderAiApp());
}

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'KAMNDER AI',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 20),
            const Text(
              'Create with AI',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              'Generate images and videos from your ideas.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
            ),
            const SizedBox(height: 32),
            _CreateCard(
              icon: Icons.image_outlined,
              title: 'Text → Image',
              subtitle: 'Create images from a prompt',
              onTap: () {},
            ),
            const SizedBox(height: 14),
            _CreateCard(
              icon: Icons.movie_creation_outlined,
              title: 'Text → Video',
              subtitle: 'Create cinematic videos from text',
              onTap: () {},
            ),
            const SizedBox(height: 14),
            _CreateCard(
              icon: Icons.photo_camera_back_outlined,
              title: 'Image → Video',
              subtitle: 'Animate an image with AI',
              onTap: () {},
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Generation engine', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('Open-source AI models • Wan integration planned'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _CreateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, size: 36),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 5),
                    Text(subtitle, style: TextStyle(color: Colors.grey.shade400)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
