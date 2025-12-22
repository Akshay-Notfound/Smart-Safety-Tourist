import 'package:flutter/material.dart';
import 'package:ota_update/ota_update.dart';
import 'package:permission_handler/permission_handler.dart';

class UpdateDialog extends StatefulWidget {
  final String latestVersion;
  final String apkUrl;
  final String changes;

  const UpdateDialog({
    super.key,
    required this.latestVersion,
    required this.apkUrl,
    required this.changes,
  });

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  OtaEvent? currentEvent;
  bool isDownloading = false;

  Future<void> _startUpdate() async {
    // Request storage permissions first if needed (Android < 11 mostly, but good practice)
    var status = await Permission.storage.request();
    if (status.isGranted ||
        status.isLimited ||
        await Permission.storage.isRestricted) {
      // Proceed even if restricted, sometimes it works depending on scope
    }

    // Android 11+ might need REQUEST_INSTALL_PACKAGES check at runtime,
    // but ota_update usually handles the intent.

    setState(() {
      isDownloading = true;
    });

    try {
      // LINK MUST BE DIRECT DOWNLOAD AND HTTPS
      OtaUpdate().execute(widget.apkUrl).listen((OtaEvent event) {
        if (mounted) {
          setState(() {
            currentEvent = event;
          });
          if (event.status == OtaStatus.INSTALLING) {
            // Close dialog when installing starts or just let user interact
            Navigator.of(context).pop();
          }
        }
      }, onError: (error) {
        print("OTA Error: $error");
        if (mounted) {
          setState(() {
            isDownloading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Update failed: $error")),
          );
        }
      });
    } catch (e) {
      print("OTA Exception: $e");
      if (mounted) {
        setState(() {
          isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("App Update Available"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isDownloading) ...[
            Text("A new version ${widget.latestVersion} is available."),
            const SizedBox(height: 10),
            if (widget.changes.isNotEmpty) ...[
              const Text("What's New:",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(widget.changes),
              const SizedBox(height: 10),
            ],
            const Text(
                "Please update to ensure optimal performance and access to new features."),
          ] else ...[
            const Text("Downloading update...",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: (currentEvent != null && currentEvent!.value != null)
                  ? double.tryParse(currentEvent!.value!)! / 100
                  : null,
            ),
            const SizedBox(height: 8),
            Text(currentEvent != null
                ? "${currentEvent!.status}: ${currentEvent!.value}%"
                : "Starting..."),
          ],
        ],
      ),
      actions: [
        if (!isDownloading) ...[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("Later"),
          ),
          ElevatedButton(
            onPressed: _startUpdate,
            child: const Text("Update Now"),
          ),
        ],
      ],
    );
  }
}
