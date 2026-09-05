import 'package:flutter/material.dart';

import '../services/audio_service.dart';
import 'liquid_player_screen.dart';

/// Galeria de fotos do artista — mesma linguagem Liquid Glass.
/// Toque em um quadro para ampliar (ocupa a largura toda); toque de novo para voltar.
///
/// As fotos vêm de `assets/`; troque a lista `_fotos` pelos arquivos reais e
/// declare-os no pubspec.yaml.
class GalleryScreen extends StatefulWidget {
  final AudioService audioService;
  const GalleryScreen({super.key, required this.audioService});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _Foto {
  final String asset;
  final String legenda;
  final String sub;
  final String tag;
  final int cols;
  final int rows;
  const _Foto(this.asset, this.legenda, this.sub, this.tag, this.cols, this.rows);
}

class _GalleryScreenState extends State<GalleryScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _blobs;
  final GlassMode _mode = GlassMode.fosco;
  String _tab = 'Todas';
  int? _aberta;

  static const _tabs = ['Todas', 'Palco', 'Bastidores', 'Estúdio'];

  static const _fotos = <_Foto>[
    _Foto('assets/775416812_18620508076026296_1192558196502584496_n.jpg', 'Concha Acústica',
        'Salvador · 2024', 'Palco', 2, 2),
    _Foto('assets/Jorge-Daux-@jorgedaux.webp', 'Antes da passagem', 'Bastidores', 'Bastidores', 1, 1),
    _Foto('assets/IMAGEM_NOTICIA_original.jpg', 'Pedal board', 'Estúdio · 2023', 'Estúdio', 1, 1),
    _Foto('assets/Jorge-Daux-@jorgedaux.webp', 'Segunda voz', 'Palco · 2024', 'Palco', 1, 2),
    _Foto('assets/IMAGEM_NOTICIA_original.jpg', 'Take 14', 'Estúdio', 'Estúdio', 1, 1),
    _Foto('assets/775416812_18620508076026296_1192558196502584496_n.jpg', 'Camarim',
        'Bastidores · 2025', 'Bastidores', 1, 1),
    _Foto('assets/IMAGEM_NOTICIA_original.jpg', 'Encerramento', 'São Paulo · 2025', 'Palco', 2, 2),
    _Foto('assets/Jorge-Daux-@jorgedaux.webp', 'Mesa de corte', 'Estúdio', 'Estúdio', 1, 1),
    _Foto('assets/775416812_18620508076026296_1192558196502584496_n.jpg', 'Soundcheck',
        'Bastidores', 'Bastidores', 1, 1),
  ];

  List<_Foto> get _lista =>
      _tab == 'Todas' ? _fotos : _fotos.where((f) => f.tag == _tab).toList();

  @override
  void initState() {
    super.initState();
    _blobs = AnimationController(vsync: this, duration: const Duration(seconds: 24))..repeat();
  }

  @override
  void dispose() {
    _blobs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lista = _lista;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0910),
      body: Stack(
        children: [
          FundoLiquido(animation: _blobs, paleta: kPaletas[0]),
          const VeuFundo(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('PITTY',
                                style: TextStyle(
                                    fontSize: 9,
                                    letterSpacing: 2,
                                    color: Colors.white.withOpacity(0.5))),
                            const SizedBox(height: 4),
                            const Text('Galeria',
                                style: TextStyle(
                                    fontSize: 27,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.8,
                                    color: Colors.white)),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('${lista.length} FOTOS',
                            style: TextStyle(
                                fontSize: 10,
                                letterSpacing: 1.6,
                                color: Colors.white.withOpacity(0.62))),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 32,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: _tabs.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final c = _tabs[i];
                      final ativo = c == _tab;
                      return GestureDetector(
                        onTap: () => setState(() {
                          _tab = c;
                          _aberta = null;
                        }),
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: Colors.white.withOpacity(ativo ? 0.16 : 0.045),
                            border: Border.all(color: Colors.white.withOpacity(ativo ? 0.4 : 0.1)),
                          ),
                          child: Text(c,
                              style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withOpacity(ativo ? 1 : 0.65))),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 2, 20, 12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      mainAxisExtent: 104,
                    ),
                    itemCount: lista.length,
                    itemBuilder: (_, i) => _quadro(lista[i], i),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
                  child: Glass(
                    mode: _mode,
                    radius: 25,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      height: 50,
                      child: Row(
                        children: [
                          Icon(Icons.photo_library_outlined,
                              size: 17, color: Colors.white.withOpacity(0.8)),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Text('Toque em uma foto para ampliar',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.white.withOpacity(0.72))),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_aberta != null) _visor(lista[_aberta!]),
        ],
      ),
    );
  }

  Widget _quadro(_Foto f, int i) {
    return GestureDetector(
      onTap: () => setState(() => _aberta = i),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.14)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 30, offset: const Offset(0, 12)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(f.asset,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: Colors.white10)),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, const Color(0xFF08070C).withOpacity(0.82)],
                    stops: const [0.42, 1],
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(f.legenda,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            shadows: [Shadow(color: Colors.black54, blurRadius: 12)])),
                    Text(f.sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 10.5, color: Colors.white.withOpacity(0.82))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Visor em tela cheia com fundo de vidro.
  Widget _visor(_Foto f) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () => setState(() => _aberta = null),
        child: Container(
          color: Colors.black.withOpacity(0.55),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Glass(
                mode: _mode,
                radius: 26,
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.asset(f.asset,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(height: 240, color: Colors.white10)),
                    ),
                    const SizedBox(height: 11),
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(f.legenda,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                          const SizedBox(height: 2),
                          Text(f.sub,
                              style: TextStyle(
                                  fontSize: 11.5, color: Colors.white.withOpacity(0.65))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
