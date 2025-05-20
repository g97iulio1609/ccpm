import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:flutter/services.dart';

class MiniTimer extends StatefulWidget {
  final int remainingSeconds;
  final bool isEmomMode;
  final VoidCallback onExpand;
  final VoidCallback onCancel;
  final VoidCallback onNext;

  const MiniTimer({
    super.key,
    required this.remainingSeconds,
    required this.isEmomMode,
    required this.onExpand,
    required this.onCancel,
    required this.onNext,
  });

  @override
  State<MiniTimer> createState() => _MiniTimerState();
}

class _MiniTimerState extends State<MiniTimer>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Offset _position = const Offset(20, 100);
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.remainingSeconds <= 5) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(MiniTimer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.remainingSeconds <= 5 && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (widget.remainingSeconds > 5 && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    // Determina il colore in base al tempo rimanente
    Color timerColor = AppTheme.primaryGold;
    if (widget.remainingSeconds <= 5) {
      timerColor =
          widget.remainingSeconds <= 3 ? AppTheme.error : AppTheme.success;
    }

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanStart: (_) {
          setState(() {
            _isDragging = true;
          });
        },
        onPanUpdate: (details) {
          setState(() {
            _position = Offset(
              _position.dx + details.delta.dx,
              _position.dy + details.delta.dy,
            );
          });
        },
        onPanEnd: (_) {
          setState(() {
            _isDragging = false;
          });
          HapticFeedback.lightImpact();
        },
        onTap: widget.onExpand,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: widget.remainingSeconds <= 5 ? _pulseAnimation.value : 1.0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: timerColor,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: timerColor.withAlpha(_isDragging ? 100 : 50),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Timer display
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.isEmomMode)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGold.withAlpha(50),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'EMOM',
                                style: TextStyle(
                                  color: AppTheme.primaryGold,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            _formatTime(widget.remainingSeconds),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Pulsanti
                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          widget.onCancel();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.error.withAlpha(180),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          widget.onNext();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGold.withAlpha(180),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_forward,
                            color: Colors.black,
                            size: 14,
                          ),
                        ),
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
