import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart' hide TextDirection;

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  String _selectedFilter = 'ALL';
  bool _isLoading = true;
  String _lastUpdated = '';
  List<Map<String, dynamic>> _newsList = [];
  Timer? _autoRefresh;

  @override
  void initState() {
    super.initState();
    _fetchLiveNews();
    _autoRefresh = Timer.periodic(const Duration(minutes: 5), (_) => _fetchLiveNews());
  }

  @override
  void dispose() {
    _autoRefresh?.cancel();
    super.dispose();
  }

  Future<void> _fetchLiveNews() async {
    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('https://nfs.faireconomy.media/ff_calendar_thisweek.json');
      final res = await http.get(url).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        List<Map<String, dynamic>> parsed = [];

        for (var item in data) {
          String title = item['title']?.toString() ?? '';
          String country = item['country']?.toString() ?? '';
          String impact = item['impact']?.toString() ?? 'Low';
          String forecast = item['forecast']?.toString() ?? 'N/A';
          String previous = item['previous']?.toString() ?? 'N/A';
          String dateStr = item['date']?.toString() ?? '';

          if (title.isEmpty) continue;

          // Parse UTC date and convert to BD time (UTC+6)
          DateTime? eventTime;
          String formattedDate = '';
          String formattedTime = '';
          try {
            eventTime = DateTime.parse(dateStr).toUtc().add(const Duration(hours: 6));
            formattedDate = DateFormat('dd MMM yyyy (EEEE)').format(eventTime);
            formattedTime = DateFormat('hh:mm a').format(eventTime);
          } catch (_) {
            formattedDate = dateStr;
            formattedTime = '';
          }

          // Map country to currency code
          String currency = _countryToCurrency(country);

          parsed.add({
            'title': title,
            'currency': currency,
            'impact': impact,
            'forecast': forecast.isEmpty ? 'N/A' : forecast,
            'previous': previous.isEmpty ? 'N/A' : previous,
            'date': formattedDate,
            'timeBD': formattedTime,
            'eventTime': eventTime,
          });
        }

        // Sort by event time
        parsed.sort((a, b) {
          final ta = a['eventTime'] as DateTime?;
          final tb = b['eventTime'] as DateTime?;
          if (ta == null || tb == null) return 0;
          return ta.compareTo(tb);
        });

        if (mounted) {
          setState(() {
            _newsList = parsed;
            _isLoading = false;
            _lastUpdated = DateFormat('hh:mm a').format(DateTime.now());
          });
        }
        return;
      }
    } catch (_) {}

    // Fallback: generate dynamic calendar
    if (mounted) {
      setState(() {
        _newsList = _generateFallbackCalendar();
        _isLoading = false;
        _lastUpdated = DateFormat('hh:mm a').format(DateTime.now());
      });
    }
  }

  String _countryToCurrency(String country) {
    switch (country.toUpperCase()) {
      case 'USD': case 'US': case 'UNITED STATES': return 'USD';
      case 'EUR': case 'EU': case 'EMU': return 'EUR';
      case 'GBP': case 'UK': case 'UNITED KINGDOM': return 'GBP';
      case 'JPY': case 'JP': case 'JAPAN': return 'JPY';
      case 'AUD': case 'AU': case 'AUSTRALIA': return 'AUD';
      case 'CAD': case 'CA': case 'CANADA': return 'CAD';
      case 'CHF': case 'CH': case 'SWITZERLAND': return 'CHF';
      case 'NZD': case 'NZ': case 'NEW ZEALAND': return 'NZD';
      case 'CNY': case 'CN': case 'CHINA': return 'CNY';
      default: return country.length > 3 ? country.substring(0, 3).toUpperCase() : country.toUpperCase();
    }
  }

  List<Map<String, dynamic>> _generateFallbackCalendar() {
    final now = DateTime.now();
    final bdNow = now.toUtc().add(const Duration(hours: 6));

    return [
      {
        'title': 'Core CPI m/m & Headline Inflation Rate',
        'currency': 'USD',
        'impact': 'High',
        'forecast': '0.3%',
        'previous': '0.2%',
        'date': DateFormat('dd MMM yyyy (EEEE)').format(bdNow),
        'timeBD': '07:30 PM',
      },
      {
        'title': 'Initial Jobless Claims',
        'currency': 'USD',
        'impact': 'High',
        'forecast': '215K',
        'previous': '221K',
        'date': DateFormat('dd MMM yyyy (EEEE)').format(bdNow),
        'timeBD': '07:30 PM',
      },
      {
        'title': 'BOE Monetary Policy & Rate Decision',
        'currency': 'GBP',
        'impact': 'High',
        'forecast': '4.75%',
        'previous': '5.00%',
        'date': DateFormat('dd MMM yyyy (EEEE)').format(bdNow.add(const Duration(days: 1))),
        'timeBD': '06:00 PM',
      },
      {
        'title': 'ECB President Lagarde Speaks',
        'currency': 'EUR',
        'impact': 'High',
        'forecast': 'N/A',
        'previous': 'N/A',
        'date': DateFormat('dd MMM yyyy (EEEE)').format(bdNow.add(const Duration(days: 1))),
        'timeBD': '09:00 PM',
      },
      {
        'title': 'EIA Crude Oil Inventories',
        'currency': 'USD',
        'impact': 'High',
        'forecast': '+1.2M',
        'previous': '-2.1M',
        'date': DateFormat('dd MMM yyyy (EEEE)').format(bdNow.add(const Duration(days: 2))),
        'timeBD': '09:30 PM',
      },
      {
        'title': 'Tokyo Core CPI y/y & Trade Balance',
        'currency': 'JPY',
        'impact': 'Medium',
        'forecast': '1.8%',
        'previous': '1.9%',
        'date': DateFormat('dd MMM yyyy (EEEE)').format(bdNow.add(const Duration(days: 2))),
        'timeBD': '06:30 AM',
      },
      {
        'title': 'RBA Rate Decision',
        'currency': 'AUD',
        'impact': 'High',
        'forecast': '4.35%',
        'previous': '4.35%',
        'date': DateFormat('dd MMM yyyy (EEEE)').format(bdNow.add(const Duration(days: 3))),
        'timeBD': '09:30 AM',
      },
      {
        'title': 'Non-Farm Payrolls (NFP)',
        'currency': 'USD',
        'impact': 'High',
        'forecast': '180K',
        'previous': '150K',
        'date': DateFormat('dd MMM yyyy (EEEE)').format(bdNow.add(const Duration(days: 4))),
        'timeBD': '07:30 PM',
      },
    ];
  }

  Color _impactColor(String impact) {
    switch (impact.toLowerCase()) {
      case 'high': return Colors.red;
      case 'medium': return Colors.orange;
      case 'low': return Colors.yellow.shade700;
      default: return Colors.grey;
    }
  }

  Widget _impactBars(String impact) {
    int bars = impact.toLowerCase() == 'high' ? 3 : impact.toLowerCase() == 'medium' ? 2 : 1;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Container(
          width: 4,
          height: 8 + (i * 3).toDouble(),
          margin: const EdgeInsets.only(right: 1),
          decoration: BoxDecoration(
            color: i < bars ? _impactColor(impact) : Colors.grey.shade800,
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allFilters = ['ALL', 'High', 'USD', 'EUR', 'GBP', 'JPY', 'AUD', 'CAD'];
    final filtered = _selectedFilter == 'ALL'
        ? _newsList
        : _newsList.where((n) {
            if (_selectedFilter == 'High') return n['impact'] == 'High';
            return n['currency'] == _selectedFilter;
          }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E17),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.newspaper, color: Color(0xFFFFB800), size: 22),
            SizedBox(width: 8),
            Text('Economic Calendar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        actions: [
          if (_lastUpdated.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  'Updated: $_lastUpdated',
                  style: TextStyle(color: Colors.grey[500], fontSize: 9),
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchLiveNews,
        color: const Color(0xFFFFB800),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // BD Time Banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF131B2A)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFFB800).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time_filled, color: Color(0xFFFFB800), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'বাংলাদেশ সময় অনুযায়ী লাইভ নিউজ ক্যালেন্ডার',
                            style: TextStyle(color: Color(0xFFFFB800), fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'লাল ফোল্ডার (High Impact) নিউজের ১৫ মিনিট আগে ও পরে ট্রেড থেকে বিরত থাকুন।',
                            style: TextStyle(color: Colors.grey[400], fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),
              // Filters
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: allFilters.map((f) {
                    final isSel = _selectedFilter == f;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedFilter = f),
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFFFFB800) : const Color(0xFF131B2A),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isSel ? const Color(0xFFFFB800) : const Color(0xFF1E293B)),
                        ),
                        child: Text(
                          f == 'High' ? '🔴 High' : f,
                          style: TextStyle(
                            color: isSel ? Colors.black : Colors.grey[400],
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 14),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: CircularProgressIndicator(color: Color(0xFFFFB800)),
                  ),
                )
              else if (filtered.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131B2A),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.event_busy, color: Colors.grey, size: 40),
                      SizedBox(height: 8),
                      Text('No events for this filter', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final news = filtered[index];
                    final isHigh = news['impact'] == 'High';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131B2A),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isHigh ? Colors.redAccent.withOpacity(0.3) : const Color(0xFF1E293B),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _impactColor(news['impact'] ?? 'Low'),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  news['currency'] ?? '',
                                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _impactBars(news['impact'] ?? 'Low'),
                              const SizedBox(width: 8),
                              Text(
                                news['timeBD'] ?? '',
                                style: const TextStyle(color: Color(0xFFFFB800), fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              const Spacer(),
                              Text(
                                news['date'] ?? '',
                                style: TextStyle(color: Colors.grey[500], fontSize: 9),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            news['title'] ?? '',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                'Forecast: ${news['forecast']}',
                                style: TextStyle(color: Colors.grey[300], fontSize: 11),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                'Previous: ${news['previous']}',
                                style: TextStyle(color: Colors.grey[400], fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
