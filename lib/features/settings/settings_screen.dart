import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zad_mobile/app/constants.dart';
import 'package:zad_mobile/shared/services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _maxStorageGb = AppConstants.defaultMaxStorageGb;
  double _usedStorageMb = 0;
  String _language = 'ar';
  String _pdfViewerPref = 'system';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final storage = StorageService.instance;
    final used = await storage.getTotalStorageUsedMb();
    setState(() {
      _maxStorageGb = storage.getMaxStorageGb();
      _language = storage.getLanguage();
      _pdfViewerPref = storage.getPdfViewerPreference();
      _usedStorageMb = used;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppConstants.bgLight,
        appBar: AppBar(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
          title: const Text(
            'الإعدادات',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ─── Storage Section ───
            _buildSectionHeader('التخزين', Icons.storage_rounded),
            const SizedBox(height: 8),
            _buildCard(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.pie_chart_rounded,
                    color: AppConstants.primaryColor,
                  ),
                  title: const Text(
                    'المساحة المستخدمة',
                    style: TextStyle(color: AppConstants.textDark),
                  ),
                  subtitle: Text(
                    StorageService.instance.formatStorageUsed(_usedStorageMb),
                    style: const TextStyle(color: AppConstants.textMuted),
                  ),
                ),
                const Divider(color: AppConstants.dividerColor),
                ListTile(
                  leading: const Icon(
                    Icons.sd_storage_rounded,
                    color: AppConstants.secondaryColor,
                  ),
                  title: const Text(
                    'الحد الأقصى للتخزين',
                    style: TextStyle(color: AppConstants.textDark),
                  ),
                  subtitle: Text(
                    '${_maxStorageGb.toStringAsFixed(0)} ج.ب',
                    style: const TextStyle(color: AppConstants.textMuted),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppConstants.primaryColor,
                      inactiveTrackColor: AppConstants.dividerColor,
                      thumbColor: AppConstants.secondaryColor,
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: _maxStorageGb,
                      min: 1,
                      max: 16,
                      divisions: 15,
                      label: '${_maxStorageGb.toStringAsFixed(0)} GB',
                      onChanged: (val) async {
                        setState(() => _maxStorageGb = val);
                        await StorageService.instance.setMaxStorageGb(val);
                      },
                    ),
                  ),
                ),
                const Divider(color: AppConstants.dividerColor),
                ListTile(
                  leading: Icon(
                    Icons.delete_forever_rounded,
                    color: Colors.red.shade600,
                  ),
                  title: Text(
                    'حذف جميع التنزيلات',
                    style: TextStyle(color: Colors.red.shade600),
                  ),
                  onTap: _confirmDeleteAll,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ─── Language Section ───
            _buildSectionHeader('اللغة', Icons.language_rounded),
            const SizedBox(height: 8),
            _buildCard(
              children: [
                RadioGroup<String>(
                  groupValue: _language,
                  onChanged: (val) {
                    if (val != null) _setLanguage(val);
                  },
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        value: 'ar',
                        activeColor: AppConstants.primaryColor,
                        title: const Text(
                          'العربية',
                          style: TextStyle(color: AppConstants.textDark),
                        ),
                      ),
                      RadioListTile<String>(
                        value: 'en',
                        activeColor: AppConstants.primaryColor,
                        title: const Text(
                          'English',
                          style: TextStyle(color: AppConstants.textDark),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ─── PDF Viewer Section ───
            _buildSectionHeader('مشغل ملفات PDF', Icons.picture_as_pdf_rounded),
            const SizedBox(height: 8),
            _buildCard(
              children: [
                RadioGroup<String>(
                  groupValue: _pdfViewerPref,
                  onChanged: (val) {
                    if (val != null) _setPdfViewerPref(val);
                  },
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        value: 'system',
                        activeColor: AppConstants.primaryColor,
                        title: const Text(
                          'مشغل النظام الافتراضي (مستحسن)',
                          style: TextStyle(
                            color: AppConstants.textDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: const Text(
                          'فتح الملفات باستخدام قارئ PDF الافتراضي في جهازك (مثل Google Drive أو Adobe)',
                          style: TextStyle(
                            color: AppConstants.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Divider(color: AppConstants.dividerColor),
                      RadioListTile<String>(
                        value: 'ask',
                        activeColor: AppConstants.primaryColor,
                        title: const Text(
                          'السؤال في كل مرة',
                          style: TextStyle(
                            color: AppConstants.textDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: const Text(
                          'سؤالك عن المشغل المفضل في كل مرة تنقر فيها على ملف PDF',
                          style: TextStyle(
                            color: AppConstants.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Divider(color: AppConstants.dividerColor),
                      RadioListTile<String>(
                        value: 'internal',
                        activeColor: AppConstants.primaryColor,
                        title: const Text(
                          'المشغل المدمج في التطبيق',
                          style: TextStyle(
                            color: AppConstants.textDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: const Text(
                          'عرض ملفات PDF مباشرة داخل شاشة القارئ في تطبيق زاد',
                          style: TextStyle(
                            color: AppConstants.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ─── About Section ───
            _buildSectionHeader('عن التطبيق', Icons.info_outline_rounded),
            const SizedBox(height: 8),
            _buildCard(
              children: [
                const ListTile(
                  leading: Icon(
                    Icons.school_rounded,
                    color: AppConstants.primaryColor,
                  ),
                  title: Text(
                    AppConstants.appShortName,
                    style: TextStyle(
                      color: AppConstants.textDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'منظم المقررات والتنزيلات • الإصدار 1.0.6',
                    style: TextStyle(color: AppConstants.textMuted),
                  ),
                ),
                const Divider(color: AppConstants.dividerColor),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    AppConstants.appShortDescription,
                    style: TextStyle(
                      color: AppConstants.textDark,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
                const Divider(color: AppConstants.dividerColor),
                const ListTile(
                  leading: Icon(
                    Icons.verified_user_outlined,
                    color: AppConstants.secondaryColor,
                  ),
                  title: Text(
                    'إخلاء مسؤولية (Disclaimer)',
                    style: TextStyle(
                      color: AppConstants.textDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text(
                      'هذا التطبيق هو أداة مساعدة مستقلة تم تطويرها بجهد فردي لخدمة طلاب أكاديمية زاد، وهو تطبيق غير رسمي ولا يمثل أو يتبع لأكاديمية زاد العلمية أو قناة زاد الفضائية بأي شكل من الأشكال. جميع حقوق المحتوى والمناهج محفوظة لأصحابها الأصليين في "أكاديمية زاد العلمية".',
                      style: TextStyle(
                        color: AppConstants.textMuted,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
                const Divider(color: AppConstants.dividerColor),
                ListTile(
                  leading: const Icon(
                    Icons.privacy_tip_outlined,
                    color: AppConstants.accentColor,
                  ),
                  title: const Text(
                    'سياسة الخصوصية',
                    style: TextStyle(color: AppConstants.textDark),
                  ),
                  trailing: const Icon(
                    Icons.open_in_new_rounded,
                    color: AppConstants.textMuted,
                    size: 18,
                  ),
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppConstants.primaryColor, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppConstants.textDark,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.cardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.dividerColor),
        boxShadow: [
          BoxShadow(
            color: AppConstants.primaryColor.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Future<void> _setLanguage(String lang) async {
    setState(() => _language = lang);
    await StorageService.instance.setLanguage(lang);
  }

  Future<void> _setPdfViewerPref(String pref) async {
    setState(() => _pdfViewerPref = pref);
    await StorageService.instance.setPdfViewerPreference(pref);
  }

  void _confirmDeleteAll() {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppConstants.cardLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'حذف جميع التنزيلات',
            style: TextStyle(
              color: AppConstants.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'سيتم حذف جميع الملفات المحملة نهائياً ولا يمكن التراجع. متأكد؟',
            style: TextStyle(color: AppConstants.textDark),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'إلغاء',
                style: TextStyle(color: AppConstants.textMuted),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await StorageService.instance.deleteAllDownloads();
                _loadSettings();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('تم حذف جميع التنزيلات'),
                      backgroundColor: AppConstants.primaryDark,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'حذف الكل',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
