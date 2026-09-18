import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:zad_mobile/app/constants.dart';

/// الشاشة/النافذة المخصصة لعرض شروط الاستخدام وسياسة الخصوصية بتصميم أنيق
class LegalViewerSheet extends StatefulWidget {
  final int initialTabIndex; // 0 for Terms, 1 for Privacy

  const LegalViewerSheet({
    super.key,
    this.initialTabIndex = 0,
  });

  /// عرض النافذة كـ Modal BottomSheet
  static Future<void> show(BuildContext context, {int initialTabIndex = 0}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LegalViewerSheet(initialTabIndex: initialTabIndex),
    );
  }

  @override
  State<LegalViewerSheet> createState() => _LegalViewerSheetState();
}

class _LegalViewerSheetState extends State<LegalViewerSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openExternalPrivacyPolicy() async {
    try {
      await InAppBrowser.openWithSystemBrowser(
        url: WebUri(AppConstants.privacyPolicyUrl),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر فتح الرابط الخارجي'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _copyLegalText(String text, String title) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم نسخ نص $title'),
        backgroundColor: AppConstants.primaryDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.88;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: height,
        decoration: const BoxDecoration(
          color: AppConstants.bgLight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppConstants.dividerColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 12),

            // Header Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppConstants.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.policy_rounded,
                      color: AppConstants.primaryColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'المعلومات القانونية والسياسات',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.textDark,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'تطبيق رفيق زاد • الإصدار ${AppConstants.fullVersion}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppConstants.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppConstants.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Tab Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppConstants.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppConstants.cardLight,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  labelColor: AppConstants.primaryColor,
                  unselectedLabelColor: AppConstants.textMuted,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  unselectedLabelStyle: const TextStyle(fontSize: 13),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.gavel_rounded, size: 16),
                          SizedBox(width: 6),
                          Text('شروط الاستخدام'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.privacy_tip_rounded, size: 16),
                          SizedBox(width: 6),
                          Text('سياسة الخصوصية'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTermsTab(),
                  _buildPrivacyTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Tab 1: شروط الاستخدام ───
  Widget _buildTermsTab() {
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + MediaQuery.paddingOf(context).bottom),
      children: [
        _buildNoticeBanner(
          icon: Icons.info_outline_rounded,
          title: 'ملخص اتفاقية الاستخدام',
          message:
              'باستخدامك لتطبيق "رفيق زاد"، فإنك توافق على البنود والشروط الموضحة أدناه، والتي تهدف لحفظ حقوق الأكاديمية وتوفير بيئة تعليمية آمنة.',
        ),
        const SizedBox(height: 14),

        _buildSectionCard(
          icon: Icons.verified_user_outlined,
          title: '1. طبيعة التطبيق (أداة غير رسمية)',
          content:
              'تطبيق "رفيق زاد" هو أداة تنظيمية مساعدة ومستقلة، تم تطويرها بمبادرة فردية غير ربحية لتسهيل تنزيل ومتابعة المحاضرات والمقررات الدراسية لطلاب برنامج "أكاديمية زاد العلمية".\n'
              'التطبيق لا يمثل "أكاديمية زاد العلمية" أو "قناة زاد الفضائية" ولا يتبع لهما بشكل مباشر، بل يعمل كواجهة مساعدة للمنصة الرسمية.',
        ),
        const SizedBox(height: 12),

        _buildSectionCard(
          icon: Icons.copyright_rounded,
          title: '2. حقوق الملكية الفكرية والمحتوى',
          content:
              'جميع الحقوق الفكرية والمناهج والمقررات والكتب الإلكترونية (PDF) والتسجيلات الصوتية (MP3) والمرئيات مملوكة حصرياً لأصحابها في "أكاديمية زاد العلمية".\n'
              'التطبيق لا يبيع أو يتاجر بأي مادة علمية، ويقتصر دوره على التنسيق والتنظيم داخل جهاز المستخدم.',
        ),
        const SizedBox(height: 12),

        _buildSectionCard(
          icon: Icons.lock_outline_rounded,
          title: '3. أمان بيانات الدخول والحسابات',
          content:
              '• تسجيل الدخول يتم عبر الموقع الإلكتروني الرسمي لبرنامج زاد مباشرة من خلال المتصفح المدمج.\n'
              '• التطبيق لا يقوم بحفظ أو نقل أو تخزين كلمات المرور الخاصة بالطلاب على أي خوادم خارجية إطلاقاً.\n'
              '• جلسة التصفح وملفات الارتباط (Cookies) تُدار بشكل آمن ومحلي داخل بيئة التطبيق الرسمية.',
        ),
        const SizedBox(height: 12),

        _buildSectionCard(
          icon: Icons.school_outlined,
          title: '4. الاستخدام العادل والمسموح',
          content:
              '• يُسمح باستخدام ميزات التنزيل أوفلاين للأغراض الدراسية والتحصيل الشخصي للطلاب المقيدين في الأكاديمية فقط.\n'
              '• يُحظر استخدام التطبيق بأي طريقة قد تسبب عبئاً غير طبيعي على خوادم الأكاديمية أو إساءة استخدام محتوياتها.',
        ),
        const SizedBox(height: 12),

        _buildSectionCard(
          icon: Icons.warning_amber_rounded,
          title: '5. إخلاء المسؤولية وحدودها',
          content:
              'يتم توفير التطبيق "كما هو" (As Is) دون أي ضمانات صريحة أو ضمنية. المطور غير مسؤول عن أي انقطاع في الخدمة ناتج عن تحديثات خوادم الأكاديمية أو الامتحانات الدورية، أو فقدان في الملفات المحملة نتيجة نفاد ذاكرة الجهاز.',
        ),
        const SizedBox(height: 16),

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('نسخ الشروط'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppConstants.primaryColor,
                  side: const BorderSide(color: AppConstants.primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _copyLegalText(_allTermsText, 'شروط الاستخدام'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Tab 2: سياسة الخصوصية ───
  Widget _buildPrivacyTab() {
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + MediaQuery.paddingOf(context).bottom),
      children: [
        _buildNoticeBanner(
          icon: Icons.security_rounded,
          title: 'خصوصيتك محمية 100%',
          message:
              'نحن نؤمن بأعلى معايير الخصوصية. التطبيق لا يجمع أي بيانات تعريف شخصية ولا يشارك أي ملفات مع أطراف ثالثة.',
        ),
        const SizedBox(height: 14),

        _buildSectionCard(
          icon: Icons.phone_android_rounded,
          title: '1. البيانات المخزنة محلياً',
          content:
              '• كافة الملفات المحملة (كتب PDF، تسجيلات صوتية، فيديوهات) تُحفظ حصرياً في الذاكرة المخصصة للتطبيق على جهازك.\n'
              '• إعدادات التطبيق مثل (الحد الأقصى للذاكرة، تفضيل مشغل PDF، اللغة) يتم حفظها محلياً عبر قاعدة بيانات محلية (Hive).\n'
              '• يمكنك في أي وقت مسح كافة البيانات والتنزيلات بضغطة زر واحدة من قسم "التخزين" في الإعدادات.',
        ),
        const SizedBox(height: 12),

        _buildSectionCard(
          icon: Icons.wifi_off_rounded,
          title: '2. الاتصال بالخوادم والطرف الثالث',
          content:
              '• التطبيق لا يحتوي على أي خادم خلفي خاص (No Backend Server) ولا يقوم برفع أي تقارير أو تتبعات.\n'
              '• الاتصال الوحيد للإنترنت يتم مع خوادم منصة أكاديمية زاد الرسمية (lms-ar121.zad-academy.com) لعرض المقررات وتحميل الملفات.',
        ),
        const SizedBox(height: 12),

        _buildSectionCard(
          icon: Icons.tune_rounded,
          title: '3. الأذونات المطلوبة وسببها',
          content:
              '• مساحة التخزين (Storage): لحفظ ملفات الدروس والكتب والصوتيات في ذاكرة الهاتف لتشغيلها أوفلاين.\n'
              '• الصوت في الخلفية (Background Audio): لتمكينك من متابعة الاستماع للمحاضرات الصوتية عند إغلاق الشاشة أو استخدام تطبيق آخر.\n'
              '• الإشعارات (Notifications): لعرض شريط تقدم التنزيلات وأدوات مشغل الصوت.',
        ),
        const SizedBox(height: 12),

        _buildSectionCard(
          icon: Icons.link_rounded,
          title: '4. سياسة الخصوصية للمنصة الرسمية',
          content:
              'بما أن التطبيق يتصل بالموقع الرسمي لأكاديمية زاد، فإن استخدامك للبيانات الدراسية يخضع أيضاً لسياسة الخصوصية الرسمية الصادرة عن إدارة الأكاديمية.',
        ),
        const SizedBox(height: 16),

        // Action Buttons
        Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('عرض سياسة خصوصية أكاديمية زاد الرسمية'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _openExternalPrivacyPolicy,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('نسخ سياسة الخصوصية'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppConstants.primaryColor,
                  side: const BorderSide(color: AppConstants.primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _copyLegalText(_allPrivacyText, 'سياسة الخصوصية'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Helpers ───

  Widget _buildNoticeBanner({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppConstants.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.secondaryLight.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppConstants.primaryColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppConstants.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppConstants.textMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppConstants.cardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppConstants.primaryColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppConstants.textDark,
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: AppConstants.dividerColor, height: 18),
          Text(
            content,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppConstants.textDark,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  static const String _allTermsText = '''
شروط وأحكام استخدام تطبيق "رفيق زاد"

1. طبيعة التطبيق (أداة غير رسمية):
تطبيق "رفيق زاد" هو أداة مساعدة تنظيمية ومستقلة، تم تطويرها بمبادرة فردية لخدمة طلاب أكاديمية زاد العلمية لتسهيل تنظيم وتنزيل المقررات أوفلاين. التطبيق لا يتبع لأكاديمية زاد العلمية أو قناة زاد الفضائية بأي شكل رسمي.

2. حقوق الملكية الفكرية:
جميع الحقوق الفكرية والمناهج والكتب (PDF) والصوتيات والمرئيات ملك حصري لأكاديمية زاد العلمية. التطبيق لا يبيع ولا يدعي ملكية أي مادة دراسية.

3. بيانات الدخول والحسابات:
التطبيق لا يخزن أو ينقل كلمات مرور الطلاب لأي خادم خارجي؛ عملية تسجيل الدخول تتم مباشرة عبر الموقع الرسمي للأكاديمية.

4. الاستخدام العادل:
المواد المنزلة مخصصة للدراسة الشخصية والتحصيل العلمي الفردي للطلاب المقيدين في الأكاديمية فقط.

5. إخلاء المسؤولية:
يُقدّم التطبيق "كما هو"، والمطور غير مسؤول عن أي انقطاع ناجم عن تحديثات خوادم الأكاديمية أو فقدان الملفات نتيجة امتلاء ذاكرة الهاتف.
''';

  static const String _allPrivacyText = '''
سياسة خصوصية تطبيق "رفيق زاد"

1. البيانات المحفوظة محلياً:
كافة التنزيلات من كتب ومحاضرات وإعدادات التطبيق تُحفظ محلياً على جهاز المستخدم فقط، ولا يتم إرسالها إلى أي خوادم خارجية إطلاقاً.

2. الخصوصية والأطراف الثالثة:
التطبيق لا يقوم بتتبع المستخدمين، ولا يحتوي على إعلانات، ولا يشارك أي بيانات مع أي جهة خارجية.

3. الأذونات:
- التخزين: لحفظ المحاضرات والكتب لمتابعتها بدون إنترنت.
- الصوت في الخلفية: لمواصلة الاستماع للدروس عند إغلاق الشاشة.
- الإشعارات: لإظهار تقدم التنزيلات وأدوات مشغل الصوت.

4. سياسة المنصة الرسمية:
يخضع تصفح المحتوى الدراسي في المنصة لسياسة الخصوصية الرسمية الخاصة بأكاديمية زاد العلمية.
''';
}
