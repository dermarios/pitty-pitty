import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../models/track.dart';
import '../services/audio_service.dart';
import 'artist_screen.dart';

/// Tela "Tocando agora" — conceito Liquid Glass.
/// Drop-in: no main.dart use
///   LiquidPlayerScreen(audioService: audioService)
/// Sem dependências novas (flutter + just_audio, já no pubspec).

enum GlassMode { fosco, especular, lente }

class GlassSpec {
  final double blur;
  final double fill;
  final double border;
  final double sheen;
  final double sheetFill;
  const GlassSpec(this.blur, this.fill, this.border, this.sheen, this.sheetFill);

  static const map = <GlassMode, GlassSpec>{
    GlassMode.fosco: GlassSpec(30, 0.055, 0.13, 0.18, 0.58),
    GlassMode.especular: GlassSpec(22, 0.085, 0.30, 0.50, 0.50),
    GlassMode.lente: GlassSpec(9, 0.040, 0.40, 0.72, 0.40),
  };
}

/// Superfície de vidro reutilizável (use em qualquer tela do app).
class Glass extends StatelessWidget {
  final Widget child;
  final GlassMode mode;
  final double radius;
  final EdgeInsets padding;
  final BorderRadius? borderRadius;

  const Glass({
    super.key,
    required this.child,
    this.mode = GlassMode.fosco,
    this.radius = 22,
    this.padding = EdgeInsets.zero,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassSpec.map[mode]!;
    final br = borderRadius ?? BorderRadius.circular(radius);
    return ClipRRect(
      borderRadius: br,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: g.blur, sigmaY: g.blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: br,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(g.fill + g.sheen * 0.06),
                Colors.white.withOpacity(g.fill * 0.6),
              ],
            ),
            border: Border.all(color: Colors.white.withOpacity(g.border), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.28),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      Colors.white.withOpacity(0),
                      Colors.white.withOpacity(g.sheen),
                      Colors.white.withOpacity(0),
                    ]),
                  ),
                ),
              ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Paletas do fundo líquido — uma por faixa.
const kPaletas = <List<Color>>[
  [Color(0xFF8B5CF6), Color(0xFF22D3EE), Color(0xFFF472B6)],
  [Color(0xFFF97316), Color(0xFFA855F7), Color(0xFFFACC15)],
  [Color(0xFF22C55E), Color(0xFF0EA5E9), Color(0xFFE2E8F0)],
];

/// Fundo líquido animado (blobs desfocados). Reutilizável nas duas telas.
class FundoLiquido extends StatelessWidget {
  final Animation<double> animation;
  final List<Color> paleta;
  const FundoLiquido({super.key, required this.animation, required this.paleta});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final t = animation.value * 2 * math.pi;
          return ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 46, sigmaY: 46),
            child: Stack(
              children: [
                _blob(paleta[0], -0.6 + 0.12 * math.sin(t), -0.5 + 0.10 * math.cos(t),
                    1 + 0.12 * math.sin(t)),
                _blob(paleta[1], 0.7 + 0.10 * math.cos(t * 0.8), -0.1 + 0.12 * math.sin(t * 0.8),
                    1.05 + 0.10 * math.cos(t)),
                _blob(paleta[2], -0.5 + 0.10 * math.cos(t * 1.2), 0.7 + 0.10 * math.sin(t * 1.2),
                    0.95 + 0.14 * math.sin(t * 1.4)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _blob(Color color, double x, double y, double scale) => Align(
        alignment: Alignment(x, y),
        child: Transform.scale(
          scale: scale,
          child: FractionallySizedBox(
            widthFactor: 0.8,
            heightFactor: 0.5,
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

/// Véu escuro por cima do fundo, para garantir contraste do texto.
class VeuFundo extends StatelessWidget {
  const VeuFundo({super.key});
  @override
  Widget build(BuildContext context) => Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF08070C).withOpacity(0.62),
                const Color(0xFF08070C).withOpacity(0.18),
                const Color(0xFF08070C).withOpacity(0.55),
                const Color(0xFF08070C).withOpacity(0.88),
              ],
              stops: const [0, 0.34, 0.72, 1],
            ),
          ),
        ),
      );
}

class LiquidPlayerScreen extends StatefulWidget {
  final AudioService audioService;
  final VoidCallback? onNavigateToSide;
  final VoidCallback? onNavigateToArtist;

  const LiquidPlayerScreen({
    super.key,
    required this.audioService,
    this.onNavigateToSide,
    this.onNavigateToArtist,
  });

  @override
  State<LiquidPlayerScreen> createState() => _LiquidPlayerScreenState();
}

class _LiquidPlayerScreenState extends State<LiquidPlayerScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blobs;
  final GlassMode _mode = GlassMode.fosco; // troque para especular / lente
  double _dragX = 0;
  double? _scrubValue;

  late Future<void> _loadFuture;

  @override
  void initState() {
    super.initState();
    _blobs = AnimationController(vsync: this, duration: const Duration(seconds: 24))..repeat();
    _loadFuture = widget.audioService.loadTracks();
  }

  @override
  void dispose() {
    _blobs.dispose();
    super.dispose();
  }

  AudioPlayer get _player => widget.audioService.player;

  List<Color> get _paleta {
    final t = widget.audioService.currentTrack;
    final i = t == null ? 0 : widget.audioService.tracks.indexOf(t);
    return kPaletas[(i < 0 ? 0 : i) % kPaletas.length];
  }

  String _fmt(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final track = widget.audioService.currentTrack;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0910),
      body: Stack(
        children: [
          FundoLiquido(animation: _blobs, paleta: _paleta),
          const VeuFundo(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
              child: Column(
                children: [
                  _barraTopo(),
                  const SizedBox(height: 18),
                  _capa(track),
                  const SizedBox(height: 18),
                  _titulo(track),
                  const SizedBox(height: 14),
                  _progresso(),
                  const SizedBox(height: 6),
                  _controles(),
                  const SizedBox(height: 16),
                  Expanded(
                    child: FutureBuilder(
                      future: _loadFuture,
                      builder: (_, __) => _listaFaixas(),
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

  // ─── topo ───────────────────────────────────────────────────────────
  Widget _barraTopo() {
    return Row(
      children: [
        _iconeVidro(Icons.chevron_left_rounded, widget.onNavigateToArtist ?? () {}),
        Expanded(
          child: Column(
            children: [
              Text('TOCANDO DO ÁLBUM',
                  style: TextStyle(
                      fontSize: 9, letterSpacing: 2, color: Colors.white.withOpacity(0.55))),
              const SizedBox(height: 3),
              const Text('Forven · Pitty',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.white)),
            ],
          ),
        ),
        _iconeVidro(Icons.chevron_right_rounded, widget.onNavigateToSide ?? () {}),
      ],
    );
  }

  Widget _iconeVidro(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Glass(
          mode: _mode,
          radius: 19,
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(icon, size: 18, color: Colors.white.withOpacity(0.85)),
          ),
        ),
      );

  // ─── capa com swipe ─────────────────────────────────────────────────
  Widget _capa(Track? track) {
    final size = math.min(MediaQuery.of(context).size.width - 80, 268.0);
    return GestureDetector(
      onHorizontalDragUpdate: (d) => setState(() => _dragX += d.delta.dx),
      onHorizontalDragEnd: (_) async {
        if (_dragX < -62) {
          await widget.audioService.previous();
        } else if (_dragX > 62) {
          await widget.audioService.next();
        }
        if (mounted) setState(() => _dragX = 0);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        transform: Matrix4.translationValues(_dragX, 0, 0)..rotateZ(_dragX / 1600),
        transformAlignment: Alignment.center,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.55), blurRadius: 70, offset: const Offset(0, 30)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  track?.imageAsset ?? 'assets/Jorge-Daux-@jorgedaux.webp',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: Colors.white10),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(GlassSpec.map[_mode]!.sheen * 0.35),
                        Colors.white.withOpacity(0),
                      ],
                      stops: const [0, 0.42],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── título + curtir ────────────────────────────────────────────────
  Widget _titulo(Track? track) {
    final liked = track != null && widget.audioService.isLiked(track);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                track?.title ?? 'Selecione uma faixa',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 25, fontWeight: FontWeight.w600, letterSpacing: -0.5, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text('Pitty', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.62))),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            if (track == null) return;
            widget.audioService.toggleLike(track);
            setState(() {});
          },
          child: AnimatedScale(
            scale: liked ? 1.12 : 1,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutBack,
            child: Glass(
              mode: _mode,
              radius: 21,
              child: SizedBox(
                width: 42,
                height: 42,
                child: Icon(liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    size: 19, color: Colors.white.withOpacity(liked ? 1 : 0.8)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── progresso ──────────────────────────────────────────────────────
  Widget _progresso() {
    return StreamBuilder<Duration>(
      stream: _player.positionStream,
      builder: (context, snap) {
        final total = _player.duration ?? Duration.zero;
        final pos = snap.data ?? Duration.zero;
        final maxMs = total.inMilliseconds.toDouble();
        final value =
            _scrubValue ?? (maxMs == 0 ? 0.0 : pos.inMilliseconds.toDouble().clamp(0, maxMs));
        return Column(
          children: [
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 6,
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white.withOpacity(0.14),
                thumbColor: Colors.white,
                overlayColor: Colors.white.withOpacity(0.12),
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: _scrubValue == null ? 7 : 10),
              ),
              child: Slider(
                min: 0,
                max: maxMs == 0 ? 1 : maxMs,
                value: value.toDouble(),
                onChanged: (v) => setState(() => _scrubValue = v),
                onChangeEnd: (v) async {
                  await widget.audioService.seekTo(Duration(milliseconds: v.round()));
                  if (mounted) setState(() => _scrubValue = null);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_fmt(Duration(milliseconds: value.round())),
                      style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6))),
                  Text('-${_fmt(total - Duration(milliseconds: value.round()))}',
                      style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6))),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ─── controles ──────────────────────────────────────────────────────
  Widget _controles() {
    return StreamBuilder<bool>(
      stream: _player.playingStream,
      builder: (context, snap) {
        final playing = snap.data ?? false;
        final shuffle = widget.audioService.shuffleMode;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => setState(() => widget.audioService.toggleShuffle()),
              child: Icon(Icons.shuffle_rounded,
                  color: Colors.white.withOpacity(shuffle ? 1 : 0.42), size: 20),
            ),
            IconButton(
              iconSize: 30,
              color: Colors.white,
              onPressed: () async {
                await widget.audioService.previous();
                setState(() {});
              },
              icon: const Icon(Icons.skip_previous_rounded),
            ),
            GestureDetector(
              onTap: () async {
                playing ? await widget.audioService.pause() : await widget.audioService.resume();
              },
              child: Glass(
                mode: _mode,
                radius: 40,
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      size: 34, color: Colors.white),
                ),
              ),
            ),
            IconButton(
              iconSize: 30,
              color: Colors.white,
              onPressed: () async {
                await widget.audioService.next();
                setState(() {});
              },
              icon: const Icon(Icons.skip_next_rounded),
            ),
            GestureDetector(
              onTap: () => setState(() => widget.audioService.toggleRepeatMode()),
              child: Icon(
                widget.audioService.repeatMode == 0
                    ? Icons.repeat_rounded
                    : widget.audioService.repeatMode == 1
                        ? Icons.repeat_one_rounded
                        : Icons.repeat_rounded,
                color: widget.audioService.repeatMode == 0
                    ? Colors.white.withOpacity(0.6)
                    : Colors.white.withOpacity(0.9),
                size: 20,
              ),
            ),
          ],
        );
      },
    );
  }

  // ─── lista de faixas numerada (no lugar da letra/fila) ──────────────
  Widget _listaFaixas() {
    final tracks = widget.audioService.tracks;
    return Glass(
      mode: _mode,
      radius: 24,
      child: tracks.isEmpty
          ? Center(
              child: Text('Nenhuma faixa em assets/musicas/',
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)))
          : ShaderMask(
              shaderCallback: (rect) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black, Colors.black, Colors.transparent],
                stops: [0, 0.86, 1],
              ).createShader(rect),
              blendMode: BlendMode.dstIn,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                itemCount: tracks.length,
                itemBuilder: (_, i) {
                  final t = tracks[i];
                  final atual = t == widget.audioService.currentTrack;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () async {
                      await widget.audioService.play(t);
                      if (mounted) setState(() {});
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 1),
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: atual ? Colors.white.withOpacity(0.12) : Colors.transparent,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 19,
                            child: Text(
                              (i + 1).toString().padLeft(2, '0'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withOpacity(atual ? 1 : 0.5)),
                            ),
                          ),
                          const SizedBox(width: 11),
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: kPaletas[i % kPaletas.length].take(2).toList(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white.withOpacity(atual ? 1 : 0.88))),
                                Text('Pitty',
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.white.withOpacity(0.6))),
                              ],
                            ),
                          ),
                          Text(
                            t.duration == Duration.zero ? '' : _fmt(t.duration),
                            style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withOpacity(0.55)),
                          ),
                          if (atual && widget.audioService.repeatMode > 0)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Icon(
                                widget.audioService.repeatMode == 1
                                    ? Icons.repeat_one_rounded
                                    : Icons.repeat_rounded,
                                size: 16,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          if (widget.audioService.isLiked(t))
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Icon(
                                Icons.favorite_rounded,
                                size: 16,
                                color: Colors.red.withOpacity(0.8),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
