import 'package:flutter/material.dart';
import '../models/app_models.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  String _selectedFilter = 'ALL';

  final List<ForexNewsItem> _newsList = [
    ForexNewsItem(
      time: '19:30',
      currency: 'USD',
      impact: 'High',
      title: 'Core CPI m/m & Headline Inflation Rate',
      forecast: '0.3%',
      previous: '0.2%',
    ),
    ForexNewsItem(
      time: '19:30',
      currency: 'USD',
      impact: 'High',
      title: 'Unemployment Claims & Jobless Filings',
      forecast: '215K',
      previous: '221K',
    ),
    ForexNewsItem(
      time: '15:00',
      currency: 'GBP',
      impact: 'High',
      title: 'BOE Monetary Policy Report & Rate Decision',
      forecast: '4.75%',
      previous: '5.00%',
    ),
    ForexNewsItem(
      time: '16:45',
      currency: 'EUR',
      impact: 'High',
      title: 'ECB Main Refinancing Rate & Press Conference',
      forecast: '3.40%',
      previous: '3.65%',
    ),
    ForexNewsItem(
      time: '21:00',
      currency: 'USD',
      impact: 'Medium',
      title: 'FOMC Member Speaks & Treasury Speech',
      forecast: 'N/A',
      previous: 'N/A',
    ),
    ForexNewsItem(
      time: '06:30',
      currency: 'JPY',
      impact: 'Medium',
      title: 'Tokyo Core CPI y/y & Trade Balance',
      forecast: '1.8%',
      previous: '1.9%',
    ),
    ForexNewsItem(
      time: '21:30',
      currency: 'OIL',
      impact: 'High',
      title: 'EIA Crude Oil Inventories',
      forecast: '+1.2M',
      previous: '-2.1M',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedFilter == 'ALL'
        ? _newsList
        : _newsList.where((n) => n.currency == _selectedFilter || n.impact == _selectedFilter).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E17),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.newspaper, color: Color(0xFFFFB800), size: 22),
            SizedBox(width: 8),
            Text('Forex Factory Economic News', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Warning
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF3B1219),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Red Folder (High Impact) News creates sharp slippage.\nZavro AI automatically pauses signals 15 mins before major releases.',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            // Filter Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['ALL', 'High', 'USD', 'EUR', 'GBP', 'JPY'].map((f) {
                  final isSel = _selectedFilter == f;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFilter = f),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSel ? const Color(0xFFFFB800) : const Color(0xFF131B2A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isSel ? const Color(0xFFFFB800) : const Color(0xFF1E293B)),
                      ),
                      child: Text(
                        f == 'High' ? '🔴 High Impact' : f,
                        style: TextStyle(
                          color: isSel ? Colors.black : Colors.grey[400],
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),
            const Text(
              'LIVE ECONOMIC CALENDAR (TODAY)',
              style: TextStyle(
                color: Color(0xFFFFB800),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final news = filtered[index];
                final isHigh = news.impact == 'High';

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
                  child: Row(
                    children: [
                      // Time & Impact Folder
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(news.time, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isHigh ? Colors.red : Colors.orange,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              news.impact.toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      // Currency Badge
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          news.currency,
                          style: const TextStyle(color: Color(0xFFFFB800), fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Title & Forecast
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              news.title,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Forecast: ${news.forecast}  •  Previous: ${news.previous}',
                              style: TextStyle(color: Colors.grey[400], fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
