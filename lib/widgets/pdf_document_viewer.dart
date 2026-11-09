import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:pdfx/pdfx.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/music_model.dart';
import '../theme/app_colors.dart';

class PdfDocumentViewer extends StatefulWidget {
  const PdfDocumentViewer({
    super.key,
    required this.music,
    this.pdfUrl,
    this.showFullScreen = false,
  });
  final MusicModel music;
  final String? pdfUrl;
  final bool showFullScreen;

  @override
  State<PdfDocumentViewer> createState() => _PdfDocumentViewerState();
}

class _PdfDocumentViewerState extends State<PdfDocumentViewer> {
  PdfController? _pdfController;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 0;

  /// The URL to use for fetching/opening the PDF - either the explicit
  /// [PdfDocumentViewer.pdfUrl] override or the music's own sheet music URL.
  String? get _resolvedPdfUrl => widget.pdfUrl ?? widget.music.sheetMusicUrl;

  @override
  void initState() {
    super.initState();
    final pdfUrl = _resolvedPdfUrl;
    if (pdfUrl == null || pdfUrl.isEmpty) {
      // Nothing to fetch - go straight to the empty state.
      _isLoading = false;
      return;
    }
    // Use post-frame callback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePdf();
    });
  }

  Future<void> _initializePdf() async {
    final pdfUrl = _resolvedPdfUrl;
    if (pdfUrl == null || pdfUrl.isEmpty) {
      setState(() {
        _isLoading = false;
        _hasError = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    final previousController = _pdfController;

    try {
      final bytes = await _fetchPdfFromUrl(pdfUrl);
      final controller = PdfController(document: PdfDocument.openData(bytes));

      if (!mounted) {
        controller.dispose();
        return;
      }

      setState(() {
        _pdfController = controller;
        _currentPage = 1;
        _totalPages = 0;
        _isLoading = false;
        _hasError = false;
      });

      previousController?.dispose();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  /// Fetches the raw PDF bytes from [url] over HTTP.
  ///
  /// Throws a descriptive [Exception] on timeout, network failure, a
  /// non-200 response, or an empty body so the UI can show the real cause
  /// of the failure instead of a generic message.
  Future<Uint8List> _fetchPdfFromUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      throw Exception('Invalid PDF URL: $url');
    }

    http.Response response;
    try {
      response = await http.get(uri).timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw Exception('Timed out while fetching sheet music PDF from $url');
    } on http.ClientException catch (e) {
      throw Exception('Network error while fetching PDF: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch PDF: $e');
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Server returned HTTP ${response.statusCode} while fetching $url',
      );
    }

    if (response.bodyBytes.isEmpty) {
      throw Exception('Received empty PDF content from $url');
    }

    return response.bodyBytes;
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showFullScreen) {
      return Scaffold(
        appBar: AppBar(
          title: Text('${widget.music.title} - Sheet Music'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          actions: [
            if (!_hasError && !_isLoading && _pdfController != null) ...[
              IconButton(
                tooltip: 'Open in browser',
                icon: const Icon(Icons.open_in_browser),
                onPressed: _openInBrowser,
              ),
              IconButton(
                tooltip: 'Download',
                icon: const Icon(Icons.download),
                onPressed: _downloadPdf,
              ),
            ],
          ],
        ),
        body: _buildPdfContent(),
        bottomNavigationBar: _buildPageNavigation(),
      );
    } else {
      return _buildPdfContent();
    }
  }

  Widget _buildPdfContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_hasError) {
      return _buildErrorState();
    }

    final pdfUrl = _resolvedPdfUrl;
    if (pdfUrl == null || pdfUrl.isEmpty) {
      return _buildEmptyState();
    }

    final controller = _pdfController;
    if (controller == null) {
      // Shouldn't normally happen, but fall back to a loading indicator
      // rather than crashing on a null controller.
      return _buildLoadingState();
    }

    return _buildPdfViewer(controller);
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            SizedBox(height: 16),
            Text(
              'Loading sheet music...',
              style: TextStyle(fontSize: 16, color: AppColors.gray600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              const Text(
                'Unable to load PDF',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: AppColors.gray700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Unknown error',
                style: const TextStyle(fontSize: 14, color: AppColors.gray500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _initializePdf,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _openInBrowser,
                    icon: const Icon(Icons.open_in_browser),
                    label: const Text('Open Original'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final sourceWebsite = widget.music.sourceWebsite;
    final hasSourceWebsite = sourceWebsite != null && sourceWebsite.isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.music_off, size: 64, color: AppColors.gray400),
              const SizedBox(height: 16),
              const Text(
                'No sheet music available',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: AppColors.gray700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.music.title} does not have a sheet music PDF on file.',
                style: const TextStyle(fontSize: 14, color: AppColors.gray500),
                textAlign: TextAlign.center,
              ),
              if (hasSourceWebsite) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _openSourceWebsite,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open source website'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPdfViewer(PdfController controller) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(12)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Header with song info
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.primary,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.music.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'by ${widget.music.artist}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_totalPages > 0)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Page $_currentPage of $_totalPages',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                if (!widget.showFullScreen)
                  IconButton(
                    icon: const Icon(Icons.fullscreen, color: Colors.white),
                    onPressed: _openFullScreen,
                  ),
              ],
            ),
          ),

          // Real PDF content, rendered by pdfx.
          Expanded(
            child: PdfView(
              controller: controller,
              onDocumentLoaded: (document) {
                if (!mounted) return;
                setState(() {
                  _totalPages = document.pagesCount;
                });
              },
              onPageChanged: (page) {
                if (!mounted) return;
                setState(() {
                  _currentPage = page;
                });
              },
              onDocumentError: (error) {
                if (!mounted) return;
                setState(() {
                  _hasError = true;
                  _errorMessage = 'Error rendering PDF: $error';
                });
              },
            ),
          ),

          // Compact actions row for the embedded (non-fullscreen) view,
          // since it has no AppBar to host these.
          if (!widget.showFullScreen)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.gray200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: _openInBrowser,
                    icon: const Icon(Icons.open_in_browser, size: 18),
                    label: const Text('Open in Browser'),
                  ),
                  TextButton.icon(
                    onPressed: _downloadPdf,
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Download'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPageNavigation() {
    if (_hasError || _isLoading || _totalPages <= 1) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton.icon(
            onPressed: _currentPage > 1 ? _previousPage : null,
            icon: const Icon(Icons.keyboard_arrow_left),
            label: const Text('Previous'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gray200,
              foregroundColor: AppColors.gray700,
            ),
          ),
          Text(
            '$_currentPage / $_totalPages',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.gray700,
            ),
          ),
          ElevatedButton.icon(
            onPressed: _currentPage < _totalPages ? _nextPage : null,
            icon: const Icon(Icons.keyboard_arrow_right),
            label: const Text('Next'),
            iconAlignment: IconAlignment.end,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gray200,
              foregroundColor: AppColors.gray700,
            ),
          ),
        ],
      ),
    );
  }

  // Navigation methods - delegate to the pdfx PdfController so the actual
  // PdfView scrolls; `_currentPage` itself is kept in sync via the
  // PdfView.onPageChanged callback.
  void _previousPage() {
    final controller = _pdfController;
    if (controller == null || _currentPage <= 1) return;
    controller.previousPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _nextPage() {
    final controller = _pdfController;
    if (controller == null || _currentPage >= _totalPages) return;
    controller.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  // Note: pdfx's PdfController (v2.9.2) does not expose a public zoom API -
  // pinch-to-zoom is instead built into PdfView's page rendering directly,
  // so there are intentionally no zoom in/out controls here.

  Future<void> _downloadPdf() async {
    final pdfUrl = _resolvedPdfUrl;
    if (pdfUrl == null || pdfUrl.isEmpty) {
      _showSnack(
        'No PDF available',
        'There is no sheet music PDF to download.',
        AppColors.warning,
      );
      return;
    }
    // There is no in-app file-download/save pipeline for this feature yet,
    // so we hand off to the system browser, which can natively download
    // or save the PDF - rather than pretending a download happened here.
    await _launchUrlString(pdfUrl);
  }

  Future<void> _openInBrowser() async {
    final url = _resolvedPdfUrl ?? widget.music.sourceWebsite;
    if (url == null || url.isEmpty) {
      _showSnack(
        'No link available',
        'There is no link available for this sheet music.',
        AppColors.warning,
      );
      return;
    }
    await _launchUrlString(url);
  }

  Future<void> _openSourceWebsite() async {
    final url = widget.music.sourceWebsite;
    if (url == null || url.isEmpty) return;
    await _launchUrlString(url);
  }

  Future<void> _launchUrlString(String rawUrl) async {
    var uri = Uri.tryParse(rawUrl);
    if (uri != null && !uri.hasScheme) {
      uri = Uri.tryParse('https://$rawUrl');
    }
    if (uri == null) {
      _showSnack(
        'Invalid link',
        'The link "$rawUrl" could not be opened.',
        AppColors.error,
      );
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      _showSnack(
        'Unable to open link',
        'Could not open $rawUrl',
        AppColors.error,
      );
    }
  }

  void _showSnack(String title, String message, Color color) {
    Get.snackbar(
      title,
      message,
      backgroundColor: color,
      colorText: Colors.white,
    );
  }

  void _openFullScreen() {
    Get.to(
      () => PdfDocumentViewer(
        music: widget.music,
        pdfUrl: widget.pdfUrl,
        showFullScreen: true,
      ),
    );
  }
}
