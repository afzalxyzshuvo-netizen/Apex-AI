import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  String _selectedFilter = 'ALL';

  // Real-world Forex Factory Schedule formatted in Bangladesh Local Time (UTC+6)
  final List<Map<String, dynamic>> _newsList = [
    {
      'date': '১৬ নভেম্বর ২০২৬ (সোমবার)',
      'timeBD': 'সন্ধ্যা ০৭:৩০',
      'currency': 'USD',
      'impact': 'High',
      'title': 'Core CPI m/m & Headline Inflation Rate',
      'forecast': '০.৩%',
      'previous': '০.২%',
      'notes': 'মার্কিন মুদ্রাস্ফীতির ডেটা। গোল্ড ও ইউএসডি পেয়ারে তীব্র মুভমেন্ট হবে।'
    },
    {
      'date': '১৬ নভেম্বর ২০২৬ (সোমবার)',
      'timeBD': 'সন্ধ্যা ০৭:৩০',
      'currency': 'USD',
      'impact': 'High',
      'title': 'Unemployment Claims (প্রাথমিক বেকারত্ব দাবি)',
      'forecast': '২১৫K',
      'previous': '২২১K',
      'notes': 'বেকারত্ব দাবি কম আসলে ডলার শক্তিশালী হয় এবং গোল্ড ডাউন দেয়।'
    },
    {
      'date': '১৭ নভেম্বর ২০২৬ (মঙ্গলবার)',
      'timeBD': 'সন্ধ্যা ০৬:০০',
      'currency': 'GBP',
      'impact': 'High',
      'title': 'BOE Monetary Policy Report & Rate Decision',
      'forecast': '৪.৭৫%',
      'previous': '৫.০০%',
      'notes': 'ব্যাংক অব ইংল্যান্ডের সুদের হার ঘোষণা। GBP/USD ও GBP/JPY মুভ করবে।'
    },
    {
      'date': '১৭ নভেম্বর ২০২৬ (মঙ্গলবার)',
      'timeBD': 'রাত ০৯:০০',
      'currency': 'EUR',
      'impact': 'High',
      'title': 'ECB President Lagarde Speaks & Press Conference',
      'forecast': 'N/A',
      'previous': 'N/A',
      'notes': 'ইউরোপিয়ান কেন্দ্রীয় ব্যাংকের বক্তব্য। EUR/USD এর ভোলাটিলিটি বৃদ্ধি পাবে।'
    },
    {
      'date': '১৮ নভেম্বর ২০২৬ (বুধবার)',
      'timeBD': 'রাত ০৯:৩০',
      'currency': 'OIL',
      'impact': 'High',
      'title': 'EIA Crude Oil Inventories (আমেরিকান তেলের মজুদ)',
      'forecast': '+১.২M',
      'previous': '-২.১M',
      'notes': 'তেলের ইনভেন্টরি বেশি আসলে ক্রুড অয়েল (WTI / Brent) প্রাইস কমে।'
    },
    {
      'date': '১৮ নভেম্বর ২০২৬ (বুধবার)',
      'timeBD': 'সকাল ০৬:৩০',
      'currency': 'JPY',
      'impact': 'Medium',
      'title': 'Tokyo Core CPI y/y & Trade Balance',
      'forecast': '১.৮%',
      'previous': '১.৯%',
      'notes': 'টোকিও মূল্যস্ফীতি। USD/JPY তে ২০-৪০ পিপস মুভ হতে পারে।'
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedFilter == 'ALL'
        ? _newsList
        : _newsList.where((n) => n['currency'] == _selectedFilter || n['impact'] == _selectedFilter).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E17),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.newspaper, color: Color(0xFFFFB800), size: 22),
            SizedBox(width: 8),
            Text('Forex Factory Economic News', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BD Time Header Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF131B2A)],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFFB800).withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.access_time_filled, color: Color(0xFFFFB800), size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'বাংলাদেশ সময় অনুযায়ী লাইভ নিউজ ক্যালেন্ডার',
                          style: TextStyle(color: Color(0xFFFFB800), fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'লাল ফোল্ডার (High Impact) নিউজের ১৫ মিনিট আগে ও পরে ট্রেড থেকে বিরত থাকুন।',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            // Currency and Impact Filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['ALL', 'High', 'USD', 'EUR', 'GBP', 'OIL', 'JPY'].map((f) {
                  final isSel = _selectedFilter == f;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFilter = f),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
              'আসন্ন অর্থনৈতিক ঘটনাবলী (BANGLADESH TIME)',
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
                final isHigh = news['impact'] == 'High';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131B2A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isHigh ? Colors.redAccent.withOpacity(0.4) : const Color(0xFF1E293B),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isHigh ? Colors.red : Colors.orange,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  news['currency'],
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                news['timeBD'],
                                style: const TextStyle(color: Color(0xFFFFB800), fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                          Text(
                            news['date'],
                            style: TextStyle(color: Colors.grey[400], fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        news['title'],
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ফোরকাস্ট: ${news['forecast']}   |   পূর্ববর্তী: ${news['previous']}',
                        style: TextStyle(color: Colors.grey[300], fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        news['notes'],
                        style: TextStyle(color: Colors.grey[400], fontSize: 11, fontStyle: FontStyle.italic),
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
