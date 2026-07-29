import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/xp_badge.dart';
import '../data/quest_model.dart';

class QuestCard extends StatefulWidget {
  const QuestCard({
    super.key,
    required this.quest,
    required this.onComplete,
    this.isSubmitting = false,
    this.animationDelay = Duration.zero,
  });

  final Quest quest;
  final VoidCallback onComplete;
  final bool isSubmitting;
  final Duration animationDelay;

  @override
  State<QuestCard> createState() => _QuestCardState();
}

class _QuestCardState extends State<QuestCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    // A gentle fade-in only — no scale/bounce, so the list settles in calmly
    // rather than popping.
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    Future.delayed(widget.animationDelay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quest = widget.quest;
    final completed = quest.isCompleted;
    final borderColor = completed ? AppColors.success : AppColors.yellowSoft;

    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: completed ? Colors.grey : AppColors.greyDark,
          decoration: completed ? TextDecoration.lineThrough : null,
          fontSize: 16,
        );

    return FadeTransition(
      opacity: _fade,
      child: Container(
        decoration: BoxDecoration(
          color: completed ? AppColors.greyLight : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border(left: BorderSide(color: borderColor, width: 4)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 3))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Text(completed ? '✅' : '🌱', style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 2),
                  Text(
                    completed ? 'ทำแล้ว' : 'รอทำ',
                    style: TextStyle(fontSize: 10, color: completed ? AppColors.success : AppColors.pinkDark),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(quest.title, style: titleStyle),
                    if (quest.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        quest.description!,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        XpBadge(xp: quest.xpReward),
                        if (quest.coinReward > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.yellowSoft,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '+${quest.coinReward} เหรียญ',
                              style: const TextStyle(color: AppColors.greyDark, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (!completed)
                SizedBox(
                  height: 34,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                    onPressed: widget.isSubmitting ? null : widget.onComplete,
                    child: widget.isSubmitting
                        ? const SizedBox(
                            height: 14,
                            width: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('ไปทำกัน'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
