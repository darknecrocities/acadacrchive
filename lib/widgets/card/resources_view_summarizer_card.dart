import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as ex;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sfPdf;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ResourcesViewSummarizeCard extends StatefulWidget {
  final String title;
  final String fileUrl;
  final String? description;
  final String courseSemester;

  const ResourcesViewSummarizeCard({
    super.key,
    required this.title,
    required this.fileUrl,
    this.description,
    required this.courseSemester,
  });

  @override
  State<ResourcesViewSummarizeCard> createState() =>
      _ResourcesViewSummarizeCardState();
}

class _ResourcesViewSummarizeCardState
    extends State<ResourcesViewSummarizeCard> {
  bool _isLoading = false;
  String _extractedText = "";
  String _summary = "";
  final FlutterTts _tts = FlutterTts();
  bool _speaking = false;

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<String> _ocrFile(File file) async {
    try {
      final recognizer = TextRecognizer();
      final inputImage = InputImage.fromFile(file);
      final recognizedText = await recognizer.processImage(inputImage);
      await recognizer.close();
      return recognizedText.text.isNotEmpty
          ? recognizedText.text
          : "No readable text found in image/PDF.";
    } catch (e) {
      return "Failed OCR: $e";
    }
  }

  Future<String> _extractText(File file) async {
    final ext = file.path.split('.').last.toLowerCase();

    try {
      if (ext == 'pdf') {
        // Use Syncfusion PDF for text extraction
        final bytes = await file.readAsBytes();
        final document = sfPdf.PdfDocument(inputBytes: bytes);
        String text = sfPdf.PdfTextExtractor(document).extractText();
        document.dispose();

        return text.isNotEmpty ? text : "No extractable text in PDF.";
      } else if (ext == 'jpg' || ext == 'jpeg' || ext == 'png') {
        return _ocrFile(file);
      } else if (ext == 'docx') {
        final bytes = await file.readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);
        final docFile = archive.firstWhere(
                (f) => f.name == 'word/document.xml',
            orElse: () => throw Exception("DOCX structure invalid"));
        final xmlDoc = XmlDocument.parse(utf8.decode(docFile.content));
        return xmlDoc.findAllElements('w:t').map((e) => e.text).join(' ');
      } else if (ext == 'pptx') {
        final bytes = await file.readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);
        final slidesText = archive
            .where((f) => f.name.startsWith('ppt/slides/slide'))
            .map((f) {
          final xmlDoc = XmlDocument.parse(utf8.decode(f.content));
          return xmlDoc.findAllElements('a:t').map((e) => e.text).join(' ');
        }).join('\n');
        if (slidesText.trim().isNotEmpty) return slidesText;
      } else if (ext == 'csv') {
        final content = await file.readAsString();
        final rows = const CsvToListConverter().convert(content);
        return rows.map((r) => r.join(', ')).join('\n');
      } else if (ext == 'xls' || ext == 'xlsx') {
        final bytes = await file.readAsBytes();
        final excel = ex.Excel.decodeBytes(bytes);
        final buffer = StringBuffer();
        for (var table in excel.tables.keys) {
          for (var row in excel.tables[table]!.rows) {
            buffer.writeln(row.map((c) => c?.value ?? '').join(', '));
          }
        }
        return buffer.toString();
      }
    } catch (e) {
      debugPrint("Text extraction failed: $e");
      return "Text extraction failed: $e";
    }

    // fallback
    return _ocrFile(file);
  }




  Future<File> _downloadTemp(String url) async {
    final uri = Uri.parse(url);
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception("Failed to download file (status ${res.statusCode})");
    }
    final tmpDir = await getTemporaryDirectory();
    final fileName =
    uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'tempfile';
    final file = File("${tmpDir.path}/$fileName");
    await file.writeAsBytes(res.bodyBytes);
    return file;
  }


  String _localSummarize(String text, {int sentenceCount = 4}) {
    if (text.trim().isEmpty) {
      return "No extractable text found in the file.";
    }
    final sentences =
    text.replaceAll('\n', ' ').split(RegExp(r'(?<=[.!?])\s+'));
    final take = sentences.take(sentenceCount).join(' ').trim();
    return take.isEmpty
        ? text.substring(0, text.length.clamp(0, 300))
        : take;
  }

  Future<String> _summarizeWithGemini(String promptText) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception("No Gemini API key configured.");
    }

    final endpoint =
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey";
    final body = jsonEncode({
      "contents": [
        {
          "parts": [
            {
              "text":
              "You are a concise academic summarizer. Summarize this text in 4 sentences:\n$promptText"
            }
          ]
        }
      ],
      "generationConfig": {"temperature": 0.5, "maxOutputTokens": 1000}
    });

    final res = await http.post(
      Uri.parse(endpoint),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (res.statusCode != 200) {
      throw Exception("Gemini API failed: ${res.statusCode} ${res.body}");
    }

    final decoded = jsonDecode(res.body);
    return decoded['candidates']?[0]?['content']?['parts']?[0]?['text'] ??
        "No summary generated.";
  }

  Future<void> _generateSummary() async {
    setState(() {
      _isLoading = true;
      _summary = "";
      _extractedText = "";
    });

    try {
      final file = await _downloadTemp(widget.fileUrl);
      final txt = await _extractText(file);
      _extractedText = txt;

      final promptSource = (txt.trim().length > 100)
          ? txt
          : "Title: ${widget.title}\nMeta: ${widget.courseSemester}\nDescription: ${widget.description ?? ''}\nURL: ${widget.fileUrl}";

      String summary;
      try {
        summary = await _summarizeWithGemini(promptSource);
      } catch (e) {
        summary = _localSummarize(promptSource);
      }

      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _summary = "Failed to generate summary: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _speakSummary() async {
    if (_summary.trim().isEmpty) return;
    try {
      setState(() => _speaking = true);
      await _tts.setLanguage("en-US");
      await _tts.setSpeechRate(0.45);
      await _tts.speak(_summary);
    } finally {
      setState(() => _speaking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 600),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12)],
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// 🧾 Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.title,
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black)),
                            const SizedBox(height: 6),
                            Text(widget.courseSemester,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.black54)),
                            if (widget.description != null &&
                                widget.description!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(widget.description!,
                                    style: const TextStyle(
                                        fontSize: 13, color: Colors.black87)),
                              ),
                          ],
                        )),
                    IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.black87))
                  ],
                ),
                const SizedBox(height: 12),

                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Summary",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black)),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        constraints:
                        const BoxConstraints(minHeight: 80, maxHeight: 300),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            _summary.isEmpty
                                ? "No summary yet. Tap 'Generate summary'."
                                : _summary,
                            style: const TextStyle(
                                fontSize: 14, color: Colors.black87, height: 1.4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      /// 🎛 Action Buttons (responsive)
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed:
                            _summary.isEmpty ? _generateSummary : null,
                            icon: const Icon(Icons.auto_mode_outlined, size: 18),
                            label: const Text("Generate summary (AI)"),
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.black,
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: _extractedText.isNotEmpty
                                ? () {
                              showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title:
                                    const Text("Extracted Text"),
                                    content: SingleChildScrollView(
                                      child: Text(_extractedText),
                                    ),
                                    actions: [
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(),
                                          child:
                                          const Text("Close"))
                                    ],
                                  ));
                            }
                                : null,
                            icon:
                            const Icon(Icons.article_outlined, size: 18),
                            label: const Text("View Extracted Text"),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey.shade800,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed:
                            _summary.isNotEmpty ? _speakSummary : null,
                            icon: Icon(
                                _speaking
                                    ? Icons.volume_off_rounded
                                    : Icons.volume_up_rounded,
                                size: 18),
                            label: const Text("Speak Summary"),
                          ),
                        ],
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Note: This AI summarization uses Gemini (model: 2.5-flash). Text recognition powered by Google ML Kit.",
                    style: TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
