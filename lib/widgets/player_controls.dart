import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:ui';

class PlayerControls extends StatelessWidget {
  final AudioPlayer player;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const PlayerControls({
    super.key,
    required this.player,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _GlassButton(
          iconSize: 40,
          icon: Icons.skip_previous,
          onPressed: onPrevious,
        ),
        StreamBuilder<PlayerState>(
          stream: player.playerStateStream,
          builder: (context, snapshot) {
            final playerState = snapshot.data;
            final isPlaying = playerState?.playing ?? false;

            return _GlassButton(
              iconSize: 64,
              icon: isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
              onPressed: () {
                if (isPlaying) {
                  player.pause();
                } else {
                  player.play();
                }
              },
              isPrimary: true,
            );
          },
        ),
        _GlassButton(
          iconSize: 40,
          icon: Icons.skip_next,
          onPressed: onNext,
        ),
      ],
    );
  }
}

class _GlassButton extends StatefulWidget {
  final double iconSize;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isPrimary;

  const _GlassButton({
    required this.iconSize,
    required this.icon,
    required this.onPressed,
    this.isPrimary = false,
  });

  @override
  State<_GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<_GlassButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: widget.iconSize + 16,
            height: widget.iconSize + 16,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: widget.isPrimary
                    ? [
                        Colors.cyan.withOpacity(_isPressed ? 0.25 : 0.2),
                        Colors.blue.withOpacity(_isPressed ? 0.15 : 0.08),
                      ]
                    : [
                        Colors.white.withOpacity(_isPressed ? 0.2 : 0.12),
                        Colors.white.withOpacity(_isPressed ? 0.1 : 0.04),
                      ],
              ),
              border: Border.all(
                color: widget.isPrimary
                    ? Colors.cyan.withOpacity(0.3)
                    : Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Icon(
              widget.icon,
              size: widget.iconSize,
              color: widget.isPrimary ? Colors.cyan : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
