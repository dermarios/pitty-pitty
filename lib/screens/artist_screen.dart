import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../services/audio_service.dart';
import 'liquid_player_screen.dart' show Glass, GlassMode, kPaletas;

/// Tela "Artista" — evolução da SideScreen: a foto sangra na tela inteira e os
/// blobs líquidos entram POR CIMA dela em blend soft-light / screen, então a
/// cor se funde à imagem em vez de ficar atrás.
class ArtistScreen extends StatefulWidget {
  final AudioService audioService;
  final VoidCallback? onBackPressed;
  final VoidCallback? onPlayPressed;

  const ArtistScreen({
    super.key,
    required this.audioService,
    this.onBackPressed,
    this.onPlayPressed,
  });

  @override
  State<ArtistScreen> createState() => _ArtistScreenState();
}

class _ArtistScreenState extends State<ArtistScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _blobs;
  final GlassMode _mode = GlassMode.fosco;
  bool _curtido = false;

  static const _foto = 'assets/775245305_18620508094026296_8409613848889249192_n.jpg';

  /// Agenda — substitua pelos shows reais.
  static const _shows = [
    (dia: '12', mes: 'SET', cidade: 'Salvador', casa: 'Concha Acústica', status: 'INGRESSOS'),
    (dia: '19', mes: 'SET', cidade: 'São Paulo', casa: 'Audio', status: 'ESGOTADO'),
    (dia: '04', mes: 'OUT', cidade: 'Belo Horizonte', casa: 'Mineirinho', status: 'INGRESSOS'),
    (dia: '18', mes: 'OUT', cidade: 'Porto Alegre', casa: 'Opinião', status: 'INGRESSOS'),
  ];

  @override
  void initState() {
    super.initState();
    _blobs = AnimationController(vsync: this, duration: const Duration(seconds: 24))..repeat();
    widget.audioService.loadTracks().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _blobs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.audioService.tracks.length;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1 · foto sangrada
          Positioned.fill(
            child: Image.asset(
              _foto,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: const Color(0xFF14121C)),
            ),
          ),
          // 2 · base escura (mantém a leitura da foto)
          Positioned.fill(child: Container(color: Colors.black.withOpacity(0.5))),
          // 3 · blobs mesclados COM a imagem
          _blobsMesclados(BlendMode.softLight, 0.95, 54),
          _blobsMesclados(BlendMode.screen, 0.34, 70),
          // 4 · degradê de contraste
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF08070C).withOpacity(0.72),
                    const Color(0xFF08070C).withOpacity(0.12),
                    const Color(0xFF08070C).withOpacity(0.60),
                    const Color(0xFF08070C).withOpacity(0.95),
                  ],
                  stops: const [0, 0.26, 0.62, 1],
                ),
              ),
            ),
          ),
          // 5 · conteúdo
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Glass(
                        mode: _mode,
                        radius: 16,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF4ADE80),
                                boxShadow: [BoxShadow(color: Color(0xFF4ADE80), blurRadius: 8)],
                              ),
                            ),
                            const SizedBox(width: 7),
                            Text('AO VIVO EM BREVE',
                                style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.4,
                                    color: Colors.white.withOpacity(0.9))),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: widget.onBackPressed ?? () => Navigator.of(context).pop(),
                        child: Glass(
                          mode: _mode,
                          radius: 19,
                          child: SizedBox(
                            width: 38,
                            height: 38,
                            child: Icon(Icons.chevron_right_rounded,
                                size: 22, color: Colors.white.withOpacity(0.9)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text('ARTISTA',
                      style: TextStyle(
                          fontSize: 9, letterSpacing: 3, color: Colors.white.withOpacity(0.7))),
                  const SizedBox(height: 10),
                  const Text(
                    'Pitty',
                    style: TextStyle(
                      fontSize: 62,
                      height: 0.92,
                      fontStyle: FontStyle.italic,
                      color: Colors.white,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 40, offset: Offset(0, 8))],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: 300,
                    child: Text(
                      'Rock brasileiro de Salvador. $n faixas na sua coleção, três álbuns e um EP ao vivo.',
                      style: TextStyle(
                          fontSize: 13.5, height: 1.55, color: Colors.white.withOpacity(0.78)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final t = widget.audioService.tracks.isNotEmpty
                                ? widget.audioService.tracks.first
                                : null;
                            if (t != null) await widget.audioService.play(t);
                            if (mounted) widget.onPlayPressed?.call();
                          },
                          child: Glass(
                            mode: _mode,
                            radius: 26,
                            child: SizedBox(
                              height: 52,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.play_arrow_rounded, size: 20, color: Colors.white),
                                  const SizedBox(width: 8),
                                  const Text('Tocar',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _botaoVidro(
                        Icons.share_rounded,
                        () {
                          // Compartilhar artista
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Compartilhe com seus amigos! 🎵')),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Próximos shows',
                          style: TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white)),
                      Text('${_shows.length} DATAS',
                          style: TextStyle(
                              fontSize: 10,
                              letterSpacing: 1.6,
                              color: Colors.white.withOpacity(0.62))),
                    ],
                  ),
                  const SizedBox(height: 11),
                  SizedBox(
                    height: 148,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _shows.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, i) {
                        final show = _shows[i];
                        final esgotado = show.status == 'ESGOTADO';
                        return GestureDetector(
                          onTap: () {},
                          child: Glass(
                            mode: _mode,
                            radius: 20,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                            child: SizedBox(
                              width: 162,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(show.dia,
                                          style: const TextStyle(
                                              fontSize: 26,
                                              height: 1,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: -1,
                                              color: Colors.white)),
                                      const SizedBox(width: 6),
                                      Text(show.mes,
                                          style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 1.4,
                                              color: Colors.white.withOpacity(0.72))),
                                    ],
                                  ),
                                  const SizedBox(height: 9),
                                  Text(show.cidade,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white)),
                                  Text(show.casa,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 11, color: Colors.white.withOpacity(0.68))),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.only(top: 10),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        top: BorderSide(color: Colors.white.withOpacity(0.12)),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(show.status,
                                            style: TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 1,
                                                color: Colors.white
                                                    .withOpacity(esgotado ? 0.6 : 1))),
                                        Icon(Icons.chevron_right_rounded,
                                            size: 15, color: Colors.white.withOpacity(0.65)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _botaoVidro(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Glass(
          mode: _mode,
          radius: 26,
          child: SizedBox(
            width: 52,
            height: 52,
            child: Icon(icon, size: 19, color: Colors.white),
          ),
        ),
      );

  /// Camada de blobs desfocados aplicada SOBRE a foto com blend mode.
  Widget _blobsMesclados(BlendMode blend, double opacity, double sigma) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity,
          child: BlendMask(
            blendMode: blend,
            child: AnimatedBuilder(
              animation: _blobs,
              builder: (context, _) {
                final t = _blobs.value * 2 * math.pi;
                final c = kPaletas[0];
                return ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                  child: Stack(
                    children: [
                      _blob(c[0], -0.7 + 0.12 * math.sin(t), -0.6 + 0.1 * math.cos(t),
                          1 + 0.12 * math.sin(t)),
                      _blob(c[1], 0.8 + 0.1 * math.cos(t * 0.8), 0.0 + 0.12 * math.sin(t * 0.8),
                          1.05 + 0.1 * math.cos(t)),
                      _blob(c[2], -0.6 + 0.1 * math.cos(t * 1.2), 0.8 + 0.1 * math.sin(t * 1.2),
                          1 + 0.14 * math.sin(t * 1.4)),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _blob(Color color, double x, double y, double scale) => Align(
        alignment: Alignment(x, y),
        child: Transform.scale(
          scale: scale,
          child: FractionallySizedBox(
            widthFactor: 0.85,
            heightFactor: 0.55,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [color, color.withOpacity(0)]),
              ),
            ),
          ),
        ),
      );
}

/// Aplica um BlendMode entre o filho e tudo que já foi pintado atrás dele.
class BlendMask extends SingleChildRenderObjectWidget {
  final BlendMode blendMode;
  const BlendMask({super.key, required this.blendMode, super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderBlendMask(blendMode);

  @override
  void updateRenderObject(BuildContext context, _RenderBlendMask renderObject) {
    renderObject.blendMode = blendMode;
  }
}

class _RenderBlendMask extends RenderProxyBox {
  BlendMode blendMode;
  _RenderBlendMask(this.blendMode) : super();

  @override
  void paint(PaintingContext context, Offset offset) {
    context.canvas.saveLayer(null, Paint()..blendMode = blendMode);
    if (child != null) {
      context.paintChild(child!, offset);
    }
    context.canvas.restore();
  }
}
