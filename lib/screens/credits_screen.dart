import 'package:flutter/material.dart';

import '../services/audio_service.dart';
import 'liquid_player_screen.dart';

/// Créditos da obra — produção, composição, banda, fotografia e arte.
/// Substitua a constante `kCreditos` pelos créditos reais.
class CreditsScreen extends StatefulWidget {
  final AudioService audioService;
  const CreditsScreen({super.key, required this.audioService});

  @override
  State<CreditsScreen> createState() => _CreditsScreenState();
}

class _Secao {
  final String titulo;
  final List<(String nome, String funcao)> pessoas;
  const _Secao(this.titulo, this.pessoas);
}

const kCreditos = <_Secao>[
  _Secao('Composição', [
    ('Ana Ferraz', 'Letra e melodia'),
    ('Rui Almeida', 'Melodia · arranjo de cordas'),
  ]),
  _Secao('Produção', [
    ('Marcelo Tavares', 'Produção musical'),
    ('Bia Nogueira', 'Produção executiva'),
  ]),
  _Secao('Estúdio', [
    ('Caio Ribeiro', 'Engenharia de gravação'),
    ('Helena Prado', 'Mixagem'),
    ('Sérgio Lund', 'Masterização'),
  ]),
  _Secao('Banda', [
    ('Pitty', 'Voz e guitarra base'),
    ('Duda Machado', 'Guitarra solo'),
    ('Joana Alves', 'Baixo'),
    ('Téo Barreto', 'Bateria'),
  ]),
  _Secao('Fotografia', [
    ('Jorge Daux', 'Fotografia de capa e turnê'),
    ('Lia Sampaio', 'Bastidores'),
  ]),
  _Secao('Arte e design', [
    ('Estúdio Vidro', 'Direção de arte'),
    ('Nuno Peixoto', 'Design da identidade'),
  ]),
];

class _CreditsScreenState extends State<CreditsScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _blobs;
  final GlassMode _mode = GlassMode.fosco;

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

  String _iniciais(String nome) {
    final partes = nome.trim().split(RegExp(r'\s+'));
    return partes.take(2).map((p) => p[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final faixa = widget.audioService.currentTrack;

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('FORVEN · PITTY',
                          style: TextStyle(
                              fontSize: 9, letterSpacing: 2, color: Colors.white.withOpacity(0.5))),
                      const SizedBox(height: 4),
                      const Text('Créditos',
                          style: TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.8,
                              color: Colors.white)),
                      const SizedBox(height: 7),
                      SizedBox(
                        width: 290,
                        child: Text(
                          'Quem escreveu, tocou, gravou e fotografou ${faixa?.title ?? 'este álbum'}.',
                          style: TextStyle(
                              fontSize: 12.5, height: 1.5, color: Colors.white.withOpacity(0.68)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 2, 20, 20),
                    itemCount: kCreditos.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      if (i == kCreditos.length) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(6, 4, 6, 0),
                          child: Text(
                            '℗ 2026 Forven · Gravado no Estúdio Casa Amarela, Salvador. '
                            'Nomes de exemplo — substitua pelos créditos reais.',
                            style: TextStyle(
                                fontSize: 10.5, height: 1.6, color: Colors.white.withOpacity(0.55)),
                          ),
                        );
                      }
                      return _cardSecao(kCreditos[i], i);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardSecao(_Secao sec, int si) {
    return Glass(
      mode: _mode,
      radius: 22,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(sec.titulo.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.8,
                      color: Colors.white)),
              Text(sec.pessoas.length > 1 ? '${sec.pessoas.length} pessoas' : '1 pessoa',
                  style: TextStyle(fontSize: 10.5, color: Colors.white.withOpacity(0.58))),
            ],
          ),
          const SizedBox(height: 10),
          ...List.generate(sec.pessoas.length, (pi) {
            final (nome, funcao) = sec.pessoas[pi];
            final cores = kPaletas[(si + pi) % kPaletas.length];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: cores.take(2).toList(),
                      ),
                    ),
                    child: Text(_iniciais(nome),
                        style: const TextStyle(
                            fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(nome,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
                        Text(funcao,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 11.5, color: Colors.white.withOpacity(0.65))),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
