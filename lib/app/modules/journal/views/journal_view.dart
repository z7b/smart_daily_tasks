import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/journal_model.dart';
import '../controllers/journal_controller.dart';
import '../../../core/helpers/number_extension.dart';

class JournalView extends GetView<JournalController> {
  const JournalView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: theme.scaffoldBackgroundColor,
              expandedHeight: 120.0,
              floating: false,
              pinned: true,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(CupertinoIcons.back, color: AppTheme.primary, size: 28),
                onPressed: () => Get.back(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                title: Text(
                  'journal'.tr,
                  style: TextStyle(
                    color: theme.textTheme.titleLarge?.color,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(CupertinoIcons.add_circled_solid, color: AppTheme.primary, size: 28),
                  onPressed: () => _showAddJournalSheet(context),
                ),
                const SizedBox(width: 8),
              ],
            ),

            // Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: CupertinoSearchTextField(
                  placeholder: 'search_journal'.tr,
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                  onChanged: (val) => controller.searchQuery.value = val,
                ),
              ),
            ),

            // Mood Trends (Life OS Spirit)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: _buildMoodTrendCard(context),
              ),
            ),

            // Streak Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: _buildStreakCard(context),
              ),
            ),

            // Journal Entries
            Obx(() {
              final journals = controller.filteredJournals;
              if (journals.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.book, size: 60, color: theme.dividerColor),
                        const SizedBox(height: 16),
                        Text(
                          'no_results_found'.tr,
                          style: TextStyle(fontSize: 18, color: theme.textTheme.bodyMedium?.color),
                        ),
                      ],
                    ).animate().fadeIn(),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final journal = journals[index];
                      return _buildJournalCard(context, journal, index);
                    },
                    childCount: journals.length,
                  ),
                ),
              );
            }),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      // ... same content but slightly smaller
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF34C759), Color(0xFF30B0C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF34C759).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Row(
        children: [
          const Icon(CupertinoIcons.flame_fill, color: Colors.white, size: 40),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Obx(() => Text(
                '${NumberFormat.decimalPattern(Get.locale?.languageCode).format(controller.calculateStreak()).f} ${'days_streak'.tr}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              )),
              Text(
                'keep_writing'.tr,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 400)).slideY(begin: 0.1, end: 0);
  }

  Widget _buildJournalCard(BuildContext context, Journal journal, int index) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final moodEmojis = ['🤩', '😊', '😐', '😢', '😤'];
    final moodColors = [
      const Color(0xFFFF9500), // Amazing
      const Color(0xFF34C759), // Good
      const Color(0xFF8E8E93), // Neutral
      const Color(0xFF007AFF), // Bad
      const Color(0xFFFF3B30), // Terrible
    ];
    final moodIndex = journal.mood.index.clamp(0, 4);

    return Dismissible(
      key: Key(journal.id.toString()),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => controller.deleteEntry(journal),
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: const Color(0xFFFF3B30),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(CupertinoIcons.trash, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: () => _showAddJournalSheet(context, existing: journal),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        DateFormat('EEEE, MMMM d', Get.locale?.languageCode).format(journal.date).f,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodyMedium?.color,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: moodColors[moodIndex].withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(moodEmojis[moodIndex], style: const TextStyle(fontSize: 18)),
                    ),
                  ],
                ),
                if (journal.note?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 12),
                  Text(
                    journal.note!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      color: theme.textTheme.bodyLarge?.color,
                      height: 1.6,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ).animate(delay: Duration(milliseconds: 50 * index)).fadeIn().slideX(begin: 0.1),
      ),
    );
  }

  void _showAddJournalSheet(BuildContext context, {Journal? existing}) {
    controller.noteController.text = existing?.note ?? '';
    final selectedMood = (existing?.mood.index ?? 2).obs;
    final theme = Theme.of(context);
    final moodEmojis = ['🤩', '😊', '😐', '😢', '😤'];
    final moodLabels = ['amazing', 'good', 'neutral', 'bad', 'terrible'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 24,
          right: 24,
          top: 24,
        ),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 5,
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                existing != null ? 'edit_entry'.tr : 'new_entry'.tr,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 20),

              // Mood Selector
              Text('how_feeling'.tr, style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
              const SizedBox(height: 12),
              Obx(() => Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(moodEmojis.length, (i) {
                  final isSelected = selectedMood.value == i;
                  return GestureDetector(
                    onTap: () => selectedMood.value = i,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primary.withValues(alpha: 0.15) : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        border: isSelected ? Border.all(color: AppTheme.primary, width: 1.5) : null,
                      ),
                      child: Column(
                        children: [
                          Text(moodEmojis[i], style: const TextStyle(fontSize: 26)),
                          const SizedBox(height: 4),
                          Text(
                            moodLabels[i].tr,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? AppTheme.primary : theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              )),
              const SizedBox(height: 20),

              // Note Field
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
                ),
                child: TextField(
                  controller: controller.noteController,
                  focusNode: controller.noteFocusNode,
                  maxLines: null,
                  expands: true,
                  decoration: InputDecoration(
                    hintText: 'thoughts_hint'.tr,
                    hintStyle: TextStyle(color: theme.dividerColor),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: Obx(() {
                  final isLoading = controller.isLoading.value;
                  return CupertinoButton(
                    color: AppTheme.primary,
                    disabledColor: AppTheme.primary.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                    onPressed: isLoading
                        ? null
                        : () {
                            if (existing != null) {
                              controller.deleteEntry(existing);
                            }
                            controller.addEntry(
                              selectedMood.value,
                              controller.noteController.text,
                              existing?.date ?? DateTime.now(),
                            );
                          },
                    child: isLoading
                        ? const CupertinoActivityIndicator(color: Colors.white)
                        : Text(
                            'save'.tr,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoodTrendCard(BuildContext context) {
    final theme = Theme.of(context);
    final moodEmojis = ['🤩', '😊', '😐', '😢', '😤'];
    
    return Obx(() {
      final insights = controller.moodInsights;
      if (insights.isEmpty) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.dividerColor.withAlpha(10)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('mood_tracker'.tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(5, (index) {
                final count = insights[index] ?? 0;
                final total = controller.journals.length;
                final percent = total > 0 ? count / total : 0.0;
                
                return Column(
                  children: [
                    Text(moodEmojis[index], style: const TextStyle(fontSize: 20)),
                    const SizedBox(height: 8),
                    Container(
                      width: 4,
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.dividerColor.withAlpha(10),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      alignment: Alignment.bottomCenter,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        width: 4,
                        height: 40 * percent,
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      );
    });
  }
}
