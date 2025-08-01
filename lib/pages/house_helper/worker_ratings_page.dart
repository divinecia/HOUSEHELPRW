import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/worker_service.dart';
import '../../services/supabase_auth_service.dart';

class WorkerRatingsPage extends StatefulWidget {
  const WorkerRatingsPage({super.key});

  @override
  State<WorkerRatingsPage> createState() => _WorkerRatingsPageState();
}

class _WorkerRatingsPageState extends State<WorkerRatingsPage> {
  Map<String, dynamic> _ratingsStats = {};
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;
  int _currentPage = 0;
  final int _pageSize = 10;
  bool _hasMoreReviews = true;

  @override
  void initState() {
    super.initState();
    _loadRatingsData();
  }

  Future<void> _loadRatingsData() async {
    try {
      final user = SupabaseAuthService.getCurrentUser();
      if (user == null) return;

      final [stats, reviews] = await Future.wait([
        WorkerService.getWorkerRatingsStats(user.id),
        WorkerService.getWorkerReviews(
          workerId: user.id,
          limit: _pageSize,
          offset: _currentPage * _pageSize,
        ),
      ]);

      if (mounted) {
        setState(() {
          _ratingsStats = stats;
          if (_currentPage == 0) {
            _reviews = reviews;
          } else {
            _reviews.addAll(reviews);
          }
          _hasMoreReviews = reviews.length == _pageSize;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading ratings: $e')),
        );
      }
    }
  }

  Future<void> _loadMoreReviews() async {
    if (!_hasMoreReviews) return;

    setState(() {
      _currentPage++;
    });

    await _loadRatingsData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _currentPage == 0) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ratings & Reviews'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _currentPage = 0;
                _isLoading = true;
              });
              _loadRatingsData();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _currentPage = 0;
            _isLoading = true;
          });
          await _loadRatingsData();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsOverview(),
              const SizedBox(height: 24),
              _buildRatingDistribution(),
              const SizedBox(height: 24),
              _buildReviewsList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsOverview() {
    final averageRating = _ratingsStats['average_rating']?.toDouble() ?? 0.0;
    final totalRatings = _ratingsStats['total_ratings'] ?? 0;
    final totalJobs = _ratingsStats['total_jobs_completed'] ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rating Overview',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        averageRating.toStringAsFixed(1),
                        style:
                            Theme.of(context).textTheme.headlineLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _getRatingColor(averageRating),
                                ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return Icon(
                            index < averageRating.floor()
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 20,
                          );
                        }),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Average Rating',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        totalRatings.toString(),
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'Total Reviews',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        totalJobs.toString(),
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'Jobs Completed',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingDistribution() {
    final distribution =
        _ratingsStats['rating_distribution'] as Map<String, dynamic>? ?? {};

    if (distribution.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rating Distribution',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (distribution.values.fold<num>(
                      0, (prev, curr) => prev > curr ? prev : curr)).toDouble(),
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final stars = '${value.toInt()}★';
                          return Text(stars);
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    for (int i = 1; i <= 5; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: (distribution[i.toString()] ?? 0).toDouble(),
                            color: _getRatingColor(i.toDouble()),
                            width: 20,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Reviews',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            if (_reviews.isEmpty)
              const Center(
                child: Text('No reviews yet'),
              )
            else
              Column(
                children: [
                  ..._reviews.map((review) => _buildReviewCard(review)),
                  if (_hasMoreReviews)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Center(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _loadMoreReviews,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Load More Reviews'),
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final rating = review['rating'] ?? 0;
    final createdAt = DateTime.tryParse(review['created_at'] ?? '');
    final jobDate = DateTime.tryParse(review['job_date'] ?? '');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: review['household_picture'] != null
                      ? NetworkImage(review['household_picture'])
                      : null,
                  child: review['household_picture'] == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review['household_name'] ?? 'Anonymous',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          ...List.generate(5, (index) {
                            return Icon(
                              index < rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 16,
                            );
                          }),
                          const SizedBox(width: 8),
                          Text(
                            '$rating/5',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (createdAt != null)
                  Text(
                    '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (review['review_text'] != null) Text(review['review_text']),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.work_outline,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'Service: ${review['service_type'] ?? 'Unknown'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (jobDate != null) ...[
                  const SizedBox(width: 16),
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Job: ${jobDate.day}/${jobDate.month}/${jobDate.year}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.5) return Colors.green;
    if (rating >= 3.5) return Colors.orange;
    if (rating >= 2.5) return Colors.yellow[700]!;
    return Colors.red;
  }
}
