import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class VtopWebviewScreen extends StatefulWidget {
  const VtopWebviewScreen({super.key});

  @override
  State<VtopWebviewScreen> createState() => _VtopWebviewScreenState();
}

class _VtopWebviewScreenState extends State<VtopWebviewScreen> {
  final GlobalKey webViewKey = GlobalKey();
  InAppWebViewController? webViewController;
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VTOP Portal'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              webViewController?.reload();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          InAppWebView(
            key: webViewKey,
            initialUrlRequest: URLRequest(
              url: WebUri('https://vtop.vitap.ac.in/vtop/'),
            ),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              transparentBackground: true,
            ),
            onWebViewCreated: (controller) {
              webViewController = controller;
            },
            onLoadStart: (controller, url) {
              setState(() {
                _isLoading = true;
              });
            },
            onLoadStop: (controller, url) {
              setState(() {
                _isLoading = false;
              });
            },
            onReceivedError: (controller, request, error) {
              debugPrint("WebView Error: ${error.description}");
            },
            onReceivedServerTrustAuthRequest: (controller, challenge) async {
              // WARNING: This bypasses all SSL certificate errors.
              // Used here specifically because the VTOP portal certificate often errors.
              return ServerTrustAuthResponse(
                action: ServerTrustAuthResponseAction.PROCEED,
              );
            },
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
