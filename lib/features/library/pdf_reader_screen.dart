import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:open_filex/open_filex.dart';
import 'package:zad_mobile/app/constants.dart';

class PdfReaderScreen extends StatefulWidget {
  final String filePath;
  final String title;

  const PdfReaderScreen({
    super.key,
    required this.filePath,
    required this.title,
  });

  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  int _totalPages = 0;
  int _currentPage = 0;
  bool _isReady = false;
  String? _errorMessage;
  PDFViewController? _pdfController;

  @override
  Widget build(BuildContext context) {
    final fileExists = File(widget.filePath).existsSync();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppConstants.bgDark,
        appBar: AppBar(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text(
            widget.title,
            style: const TextStyle(fontSize: 14, color: Colors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.open_in_new_rounded, size: 20),
              tooltip: 'فتح بتطبيق خارجي',
              onPressed: () async {
                final res = await OpenFilex.open(widget.filePath);
                if (res.type != ResultType.done && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تعذر فتح الملف: ${res.message}'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
            ),
            if (_totalPages > 0)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(
                    '${_currentPage + 1} / $_totalPages',
                    style: const TextStyle(
                      color: AppConstants.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: Stack(
          children: [
            if (fileExists)
              PDFView(
                filePath: widget.filePath,
                enableSwipe: true,
                swipeHorizontal: false,
                autoSpacing: true,
                pageFling: true,
                pageSnap: true,
                fitPolicy: FitPolicy.WIDTH,
                backgroundColor: const Color(0xFF525659),
                nightMode: false,
                onRender: (pages) {
                  setState(() {
                    _totalPages = pages ?? 0;
                    _isReady = true;
                  });
                },
                onViewCreated: (controller) {
                  _pdfController = controller;
                },
                onPageChanged: (page, total) {
                  setState(() {
                    _currentPage = page ?? 0;
                    _totalPages = total ?? 0;
                  });
                },
                onError: (error) {
                  debugPrint('PDF error: $error');
                  setState(() {
                    _errorMessage = error.toString();
                  });
                },
                onPageError: (page, error) {
                  debugPrint('PDF page error ($page): $error');
                },
              )
            else
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Colors.redAccent,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'الملف غير موجود في الذاكرة',
                        style: TextStyle(
                          color: AppConstants.textLight,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.filePath,
                        style: const TextStyle(
                          color: AppConstants.textMuted,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            if (fileExists && !_isReady && _errorMessage == null)
              const Center(
                child: CircularProgressIndicator(
                  color: AppConstants.secondaryColor,
                ),
              ),
            if (_errorMessage != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Colors.redAccent,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'تعذر عرض الملف داخلياً: $_errorMessage',
                        style: const TextStyle(
                          color: AppConstants.textLight,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => OpenFilex.open(widget.filePath),
                        icon: const Icon(Icons.open_in_new_rounded),
                        label: const Text('فتح عبر تطبيق قارئ PDF الخارجي'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: _totalPages > 1
            ? Container(
                color: AppConstants.cardDark,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _currentPage > 0
                          ? () => _pdfController?.setPage(_currentPage - 1)
                          : null,
                      icon: Icon(
                        Icons.arrow_back_ios_rounded,
                        color: _currentPage > 0
                            ? AppConstants.textLight
                            : AppConstants.textMuted,
                        size: 20,
                      ),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppConstants.primaryLight,
                          inactiveTrackColor:
                              AppConstants.textMuted.withValues(alpha: 0.2),
                          thumbColor: AppConstants.secondaryColor,
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 5),
                        ),
                        child: Slider(
                          value: _currentPage.toDouble().clamp(0, (_totalPages - 1).toDouble().clamp(0, double.infinity)),
                          max: (_totalPages - 1).toDouble().clamp(0, double.infinity),
                          onChanged: (value) {
                            _pdfController?.setPage(value.toInt());
                          },
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _currentPage < _totalPages - 1
                          ? () => _pdfController?.setPage(_currentPage + 1)
                          : null,
                      icon: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: _currentPage < _totalPages - 1
                            ? AppConstants.textLight
                            : AppConstants.textMuted,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              )
            : null,
      ),
    );
  }
}
