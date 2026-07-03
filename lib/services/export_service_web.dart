import 'dart:html' as html;

class PlatformExport {
  static void downloadFile(String base64Data, String fileName, String mimeType) {
    final dataUrl = 'data:$mimeType;base64,$base64Data';
    
    // Create a temporary link element and trigger download
    final anchor = html.AnchorElement(href: dataUrl)
      ..setAttribute('download', fileName)
      ..style.display = 'none';
    
    html.document.body?.children.add(anchor);
    anchor.click();
    html.document.body?.children.remove(anchor);
  }
}