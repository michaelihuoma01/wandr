// lib/screens/visit_timeline_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timeline_tile/timeline_tile.dart';
import '../models/visit_models.dart';
import '../services/visit_service.dart';
import '../widgets/visit_card.dart';

class VisitTimelineScreen extends StatelessWidget {
  final VisitFilter filter;
  final VisitService _visitService = VisitService();

  VisitTimelineScreen({
    super.key,
    required this.filter,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PlaceVisit>>(
      stream: _visitService.getVisitHistory(filter: filter),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final visits = snapshot.data ?? [];

        if (visits.isEmpty) {
          return _buildEmptyState();
        }

        // Group visits by month
        final Map<String, List<PlaceVisit>> groupedVisits = {};
        for (final visit in visits) {
          final monthKey = DateFormat('MMMM yyyy').format(visit.visitTime);
          groupedVisits[monthKey] ??= [];
          groupedVisits[monthKey]!.add(visit);
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 20),
          itemCount: groupedVisits.length,
          itemBuilder: (context, monthIndex) {
            final monthKey = groupedVisits.keys.elementAt(monthIndex);
            final monthVisits = groupedVisits[monthKey]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMonthHeader(monthKey, monthVisits.length),
                ...monthVisits.asMap().entries.map((entry) {
                  final index = entry.key;
                  final visit = entry.value;
                  final isFirst = monthIndex == 0 && index == 0;
                  final isLast = monthIndex == groupedVisits.length - 1 && 
                                 index == monthVisits.length - 1;

                  return TimelineTile(
                    alignment: TimelineAlign.manual,
                    lineXY: 0.2,
                    isFirst: isFirst,
                    isLast: isLast,
                    indicatorStyle: IndicatorStyle(
                      width: 40,
                      height: 40,
                      indicator: _buildIndicator(visit, context),
                      drawGap: true,
                    ),
                    beforeLineStyle: LineStyle(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                      thickness: 2,
                    ),
                    startChild: _buildDateSection(visit),
                    endChild: _buildVisitContent(visit, context),
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMonthHeader(String month, int count) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            month,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count visits',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(PlaceVisit visit, BuildContext context) {
    final category = PlaceCategory.fromString(visit.placeCategory);
    
    return Container(
      decoration: BoxDecoration(
        color: visit.isManualCheckIn 
            ? Theme.of(context).primaryColor 
            : Colors.blue,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (visit.isManualCheckIn 
                ? Theme.of(context).primaryColor 
                : Colors.blue).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          category.emoji,
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }

  Widget _buildDateSection(PlaceVisit visit) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            DateFormat('d').format(visit.visitTime),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            DateFormat('EEE').format(visit.visitTime),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('h:mm a').format(visit.visitTime),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitContent(PlaceVisit visit, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 16, bottom: 20),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to visit details
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      visit.placeName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (!visit.isManualCheckIn)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Auto',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                visit.placeType,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              if (visit.vibes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: visit.vibes.take(3).map((vibeId) {
                    final vibe = VibeConstants.getVibeById(vibeId);
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${vibe?.icon ?? ''} ${vibe?.name ?? vibeId}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              if (visit.userNote != null && visit.userNote!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.format_quote,
                        size: 16,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          visit.userNote!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (visit.rating != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < visit.rating! ? Icons.star : Icons.star_border,
                      size: 16,
                      color: Colors.amber,
                    );
                  }),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timeline,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 20),
          Text(
            'No visits to show',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your journey timeline will appear here',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}