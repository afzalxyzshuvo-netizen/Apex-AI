import 'package:flutter/material.dart';

class LearnTradingBookScreen extends StatefulWidget {
  const LearnTradingBookScreen({super.key});

  @override
  State<LearnTradingBookScreen> createState() => _LearnTradingBookScreenState();
}

class _LearnTradingBookScreenState extends State<LearnTradingBookScreen> {
  int _selectedChapterIndex = 0;

  final List<Map<String, dynamic>> _chapters = [
    {
      'num': '০১',
      'title': 'মার্কেট স্ট্রাকচার ও ট্রেন্ড (BOS vs CHoCH)',
      'subtitle': 'স্মার্ট মানি কীভাবে মার্কেট নিয়ন্ত্রণ করে',
      'icon': Icons.trending_up,
      'pages': [
        {
          'heading': 'মার্কেট স্ট্রাকচার কী?',
          'content': 'ফরেক্স এবং গোল্ড মার্কেটে দাম কখনো এলোমেলোভাবে চলে না। বড় বড় প্রাতিষ্ঠানিক ব্যাংক ও আর্থিক প্রতিষ্ঠান (Smart Money) নির্দিষ্ট স্ট্রাকচার তৈরি করে চলে। মার্কেটের প্রধান ৩টি অবস্থা থাকে:\n\n'
              '১. বুলিশ ট্রেন্ড (Uptrend): প্রতিবার নতুন হায়ার হাই (Higher High - HH) এবং হায়ার লো (Higher Low - HL) তৈরি হয়।\n'
              '২. বিয়ারিশ ট্রেন্ড (Downtrend): লোয়ার লো (Lower Low - LL) এবং লোয়ার হাই (Lower High - LH) তৈরি হয়।\n'
              '৩. কনসলিডেশন (Sideways): দাম একটি নির্দিষ্ট রেঞ্জের মধ্যে ঘুরপাক খায়।',
          'diagram': 'BULLISH: [HL] ──> [HH] ──> [HL] ──> [HH] (BOS Breakout)\nBEARISH: [LH] ──> [LL] ──> [LH] ──> [LL] (BOS Breakdown)',
          'rules': 'রুল: যখন ট্রেন্ড উপরের দিকে থাকে, কখনোই সেল এন্ট্রি খুঁজবেন না। সর্বদা হায়ার লো (HL) তে বাই খুঁজুন।',
        },
        {
          'heading': 'BOS (Break of Structure) বনাম CHoCH',
          'content': '• BOS (Break of Structure): যখন মার্কেট আগের সুইং হাই বা সুইং লো ভেঙে ট্রেন্ড চালু রাখে, তাকে BOS বলে। এটি প্রমাণ করে স্মার্ট মানি ট্রেন্ড ধরে রাখতে চায়।\n\n'
              '• CHoCH (Change of Character): যখন মার্কেট আপট্রেন্ড থেকে হঠাৎ আগের লো ভেঙে নিচে ক্লোজ দেয়, তখন ট্রেন্ড রিভার্সাল ঘটে। একে CHoCH বলা হয়। এটাই বড় ট্রেডারদের ট্রেন্ড পরিবর্তনের প্রথম সংকেত।',
          'diagram': 'UPTREND ... [HH] ──> মার্কেট আগের [HL] ভেঙে নিচে নামলো ──> [CHoCH Confirmed!]',
          'rules': 'সতর্কতা: শুধু উইক (Wick) দিয়ে সুইপ করলে CHoCH হবে না, বডি দিয়ে ক্যান্ডেল ক্লোজ হতে হবে।',
        },
      ],
    },
    {
      'num': '০২',
      'title': 'অর্ডার ব্লক (Order Block - OB)',
      'subtitle': 'ব্যাংকগুলোর মিলিয়ন ডলার বাই/সেল জোন',
      'icon': Icons.account_balance,
      'pages': [
        {
          'heading': 'অর্ডার ব্লক কী এবং কীভাবে কাজ করে?',
          'content': 'অর্ডার ব্লক (OB) হলো এমন একটি বিশেষ ক্যান্ডেলস্টিক জোন, যেখানে কেন্দ্রীয় ব্যাংক এবং হেজ ফান্ডগুলো তাদের বিপুল পরিমাণের অর্ডার পেন্ডিং রাখে।\n\n'
              '• বুলিশ অর্ডার ব্লক: কোনো তীব্র আপওয়ার্ড মুভমেন্ট (ইম্পালসিভ ক্যান্ডেল) শুরু হওয়ার ঠিক আগের শেষ রেড/বিয়ারিশ ক্যান্ডেল।\n'
              '• বিয়ারিশ অর্ডার ব্লক: বড় ধরনের মার্কেট ক্র্যাশ শুরু হওয়ার ঠিক আগের শেষ গ্রিন/বুলিশ ক্যান্ডেল।',
          'diagram': '[Red Candle (OB)] ──> [Big Green Candle Explodes Up!]\nভবিষ্যতে দাম যখন আবার এই রেড ক্যান্ডেলের জোনে ফিরে আসে, সেখান থেকেই তীব্র বাউন্স করে।',
          'rules': 'ট্রেডিং কৌশল: দাম যখন অর্ডার ব্লকে রিটেস্ট করবে, তখন কনফার্মেশন ক্যান্ডেল দেখে লিমিট অর্ডার বা মার্কেট এক্সিকিউট করুন।',
        },
      ],
    },
    {
      'num': '০৩',
      'title': 'ফেয়ার ভ্যালু গ্যাপ (Fair Value Gap - FVG)',
      'subtitle': 'মার্কেট ইমব্যালেন্স ও লিকুইডিটি ফিলিং',
      'icon': Icons.space_dashboard,
      'pages': [
        {
          'heading': 'Fair Value Gap (FVG) রহস্য',
          'content': 'মার্কেটে যখন একতরফা তীব্র কেনাবেচা হয়, তখন সাধারণ খুচরা ট্রেডাররা অর্ডার বসানোর সুযোগ পায় না। ফলে মূল্যের মধ্যে একটি শূন্যস্থান বা ইমব্যালেন্স তৈরি হয়। এটিকে ৩টি ক্যান্ডেলের মাধ্যমে মাপা হয়:\n\n'
              '১ম ক্যান্ডেলের হাই এবং ৩য় ক্যান্ডেলের লো-এর মধ্যকার যে ফাঁকা জায়গা থাকে, যেখানে ২য় ক্যান্ডেলের বডি ছাড়া অন্য কোনো উইক থাকে না, তাকে বুলিশ FVG বলে।\n\n'
              'মার্কেটের নিয়ম হলো: দাম যেকোনো সময় এই ফাঁকা গ্যাপটি পূরণ করতে ফিরে আসবেই (Rebalance)।',
          'diagram': 'Candle 1 [High: 2680] ──────┐\nCandle 2 [Big Green Move]   │ <── UNMITIGATED FVG (Gap)\nCandle 3 [Low: 2690]  ──────┘',
          'rules': 'স্মার্ট কৌশল: Zavro AI যখন দেখে দাম কোনো আনমিটিগেটেড FVG-তে প্রবেশ করেছে, তখনই হাই-প্রোবাবিলিটি এন্ট্রি সিগন্যাল তৈরি করে।',
        },
      ],
    },
    {
      'num': '০৪',
      'title': 'লিকুইডিটি সুইপ ও ট্র্যাপ (Liquidity Sweeps)',
      'subtitle': 'খুচরা ট্রেডারদের স্টপ লস হান্টিং',
      'icon': Icons.waves,
      'pages': [
        {
          'heading': 'লিকুইডিটি কী? কেন রিটেইলাররা লস করে?',
          'content': 'ফরেক্স ও গোল্ড মার্কেটের আসল চালিকাশক্তি হলো Liquidity (টাকা/স্টপ লস)। সাধারণ ট্রেডাররা যেখানে সাপোর্ট এবং রেজিস্ট্যান্সের ঠিক পেছনে স্টপ লস বসায়, ব্যাংকগুলো ঠিক সেখানেই আক্রমণ করে।\n\n'
              '• BSL (Buy-Side Liquidity): ইকুয়াল হাই (Equal Highs) এর উপরে থাকে প্রচুর বাই স্টপ এবং স্টপ লস।\n'
              '• SSL (Sell-Side Liquidity): ইকুয়াল লো (Equal Lows) এর নিচে থাকে সেল স্টপ লস।',
          'diagram': '[Equal Highs / Resistance] ─── (Retailers Sell here, SL on top)\n           ↑\n[Bank Spike sweeps SL!] ──> দাম সব SL খেয়ে তীব্র গতিতে নিচে নেমে যায়।',
          'rules': 'সোনালী নিয়ম: সাপোর্ট-রেজিস্ট্যান্সে সরাসরি ট্রেড করবেন না। ব্যাংকগুলো কখন সাপোর্ট ভেঙে ফলস ব্রেকআউট (Fakeout) দেয় তা দেখে রিভার্সাল ট্রেড নিন।',
        },
      ],
    },
    {
      'num': '০৫',
      'title': 'অগ্নিবাণ এন্ট্রি: অপটিমাল ট্রেড এন্ট্রি (OTE)',
      'subtitle': '০.৬১৮ থেকে ০.৭৮৬ গোল্ডেন ফিবোনাচ্চি ডিসকাউন্ট',
      'icon': Icons.gps_fixed,
      'pages': [
        {
          'heading': 'সঠিক এন্ট্রি নেওয়া ও রিস্ক কন্ট্রোল',
          'content': 'প্রফেশনাল ট্রেডাররা কখনোই প্রিমিয়াম (দামি) প্রাইসে বাই করেন না। তারা সর্বদা ডিসকাউন্ট (কম মূল্যে) কেনার জন্য অপেক্ষা করেন।\n\n'
              'ফিবোনাচ্চি রিট্রেসমেন্ট টুল দিয়ে সুইং লো থেকে সুইং হাই টানলে:\n'
              '• 0.50 লেভেল = ইকুইলিব্রিয়াম (Equilibrium)\n'
              '• 0.618 থেকে 0.786 লেভেল = Optimal Trade Entry (OTE) জোন।\n\n'
              'যখন এই OTE জোনের সাথে একটি Order Block বা FVG মিলে যায়, তখন সেই ট্রেডের উইন রেট ৯০% এর বেশি হয়!',
          'diagram': '[Swing High 100%] ──────────\n      | Premium Zone (Only Sell)\n[Equilibrium 50%] ──────────\n      | Discount Zone (Only Buy: 0.618 - 0.786 OTE)\n[Swing Low 0%]    ──────────',
          'rules': 'মানি ম্যানেজমেন্ট: যেকোনো ট্রেডে ১-২% এর বেশি ঝুঁকি নিবেন না। ১:২ বা ১:৩ রিস্ক-রিওয়ার্ড রেশিও মেনে চলুন।',
        },
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final currentChapter = _chapters[_selectedChapterIndex];
    final pages = currentChapter['pages'] as List<dynamic>;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF131B2A),
        elevation: 1,
        title: const Row(
          children: [
            Icon(Icons.menu_book, color: Color(0xFFFFB800), size: 22),
            SizedBox(width: 8),
            Text('ICT & SMC Masterclass Book', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
      body: Row(
        children: [
          // Left Sidebar Chapters Navigator (Book Index)
          Container(
            width: 110,
            color: const Color(0xFF131B2A),
            child: ListView.builder(
              itemCount: _chapters.length,
              itemBuilder: (context, idx) {
                final ch = _chapters[idx];
                final isSel = _selectedChapterIndex == idx;
                return GestureDetector(
                  onTap: () => setState(() => _selectedChapterIndex = idx),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isSel ? const Color(0xFFFFB800).withOpacity(0.15) : Colors.transparent,
                      border: Border(
                        left: BorderSide(
                          color: isSel ? const Color(0xFFFFB800) : Colors.transparent,
                          width: 4,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(ch['icon'] as IconData, size: 22, color: isSel ? const Color(0xFFFFB800) : Colors.grey),
                        const SizedBox(height: 6),
                        Text(
                          'অধ্যায় ${ch['num']}',
                          style: TextStyle(
                            color: isSel ? const Color(0xFFFFB800) : Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Right Content Reader Area (Book Page View)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Chapter Header Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB800).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'অধ্যায় ${currentChapter['num']} • প্রাতিষ্ঠানিক কোর্স',
                      style: const TextStyle(color: Color(0xFFFFB800), fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    currentChapter['title'],
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentChapter['subtitle'],
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFF1E293B)),

                  // Chapter Content Cards
                  ...pages.map((p) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131B2A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF1E293B)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p['heading'],
                            style: const TextStyle(color: Color(0xFFFFB800), fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            p['content'],
                            style: TextStyle(color: Colors.grey[200], fontSize: 13, height: 1.5),
                          ),
                          const SizedBox(height: 14),

                          // Visual SMC Diagram Box
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0A0E17),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF2E384D)),
                            ),
                            child: Text(
                              p['diagram'],
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontFamily: 'monospace',
                                fontSize: 11,
                                height: 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Rules Box
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B).withOpacity(0.5),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFFB800).withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.verified, color: Color(0xFFFFB800), size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    p['rules'],
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
