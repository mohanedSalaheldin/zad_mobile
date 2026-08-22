import 'package:flutter/material.dart';
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
      _usedStorageMb = used;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppConstants.bgDark,
        appBar: AppBar(
          backgroundColor: AppConstants.cardDark,
          foregroundColor: AppConstants.textLight,
          elevation: 0,
          title: const Text(
            'الإعدادات',
            style: TextStyle(fontWeight: FontWeight.bold),
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
                // Storage usage
                ListTile(
                  leading: const Icon(
                    Icons.pie_chart_rounded,
                    color: AppConstants.primaryLight,
                  ),
                  title: const Text(
                    'المساحة المستخدمة',
                    style: TextStyle(color: AppConstants.textLight),
                  ),
                  subtitle: Text(
                    StorageService.instance.formatStorageUsed(_usedStorageMb),
                    style: const TextStyle(color: AppConstants.textMuted),
                  ),
                ),
                const Divider(color: AppConstants.bgDark),
                // Max storage slider
                ListTile(
                  leading: const Icon(
                    Icons.sd_storage_rounded,
                    color: AppConstants.secondaryColor,
                  ),
                  title: const Text(
                    'الحد الأقصى للتخزين',
                    style: TextStyle(color: AppConstants.textLight),
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
                      activeTrackColor: AppConstants.primaryLight,
                      inactiveTrackColor:
                          AppConstants.textMuted.withValues(alpha: 0.2),
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
                const Divider(color: AppConstants.bgDark),
                // Delete all
                ListTile(
                  leading: const Icon(
                    Icons.delete_forever_rounded,
                    color: Colors.redAccent,
                  ),
                  title: const Text(
                    'حذف جميع التنزيلات',
                    style: TextStyle(color: Colors.redAccent),
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
                        activeColor: AppConstants.primaryLight,
                        title: const Text(
                          'العربية',
                          style: TextStyle(color: AppConstants.textLight),
                        ),
                      ),
                      RadioListTile<String>(
                        value: 'en',
                        activeColor: AppConstants.primaryLight,
                        title: const Text(
                          'English',
                          style: TextStyle(color: AppConstants.textLight),
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
                    color: AppConstants.primaryLight,
                  ),
                  title: Text(
                    AppConstants.appShortName,
                    style: TextStyle(
                      color: AppConstants.textLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'منظم المقررات والتنزيلات • الإصدار 1.0.0',
                    style: TextStyle(color: AppConstants.textMuted),
                  ),
                ),
                const Divider(color: AppConstants.bgDark),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    AppConstants.appShortDescription,
                    style: TextStyle(
                      color: AppConstants.textLight,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
                const Divider(color: AppConstants.bgDark),
                const ListTile(
                  leading: Icon(
                    Icons.verified_user_outlined,
                    color: AppConstants.secondaryColor,
                  ),
                  title: Text(
                    'إخلاء مسؤولية (Disclaimer)',
                    style: TextStyle(
                      color: AppConstants.textLight,
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
                const Divider(color: AppConstants.bgDark),
                ListTile(
                  leading: const Icon(
                    Icons.privacy_tip_outlined,
                    color: AppConstants.accentColor,
                  ),
                  title: const Text(
                    'سياسة الخصوصية',
                    style: TextStyle(color: AppConstants.textLight),
                  ),
                  trailing: const Icon(
                    Icons.open_in_new_rounded,
                    color: AppConstants.textMuted,
                    size: 18,
                  ),
                  onTap: () {
                    // Will open in WebView or external browser
                  },
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
        Icon(icon, color: AppConstants.primaryLight, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppConstants.textLight,
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
        color: AppConstants.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppConstants.textMuted.withValues(alpha: 0.1),
        ),
      ),
      child: Column(children: children),
    );
  }

  Future<void> _setLanguage(String lang) async {
    setState(() => _language = lang);
    await StorageService.instance.setLanguage(lang);
  }

  void _confirmDeleteAll() {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppConstants.cardDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'حذف جميع التنزيلات',
            style: TextStyle(
              color: AppConstants.textLight,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'سيتم حذف جميع الملفات المحملة نهائياً ولا يمكن التراجع. متأكد؟',
            style: TextStyle(color: AppConstants.textLight),
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
                      backgroundColor: AppConstants.primaryColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
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
