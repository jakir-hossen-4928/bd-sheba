import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class UpdateInfo {
  final int latestVersionCode;
  final String latestVersionName;
  final String updateUrl;
  final bool forceUpdate;
  final String releaseNotes;

  UpdateInfo({
    required this.latestVersionCode,
    required this.latestVersionName,
    required this.updateUrl,
    required this.forceUpdate,
    required this.releaseNotes,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      latestVersionCode: json['versionCode'] ?? 0,
      latestVersionName: json['versionName'] ?? '',
      updateUrl: json['updateUrl'] ?? '',
      forceUpdate: json['forceUpdate'] ?? false,
      releaseNotes: json['releaseNotes'] ?? '',
    );
  }
}

class UpdateState {
  final bool isChecking;
  final UpdateInfo? updateInfo;
  final String? error;
  final bool hasUpdate;

  UpdateState({
    this.isChecking = false,
    this.updateInfo,
    this.error,
    this.hasUpdate = false,
  });

  UpdateState copyWith({
    bool? isChecking,
    UpdateInfo? updateInfo,
    String? error,
    bool? hasUpdate,
  }) {
    return UpdateState(
      isChecking: isChecking ?? this.isChecking,
      updateInfo: updateInfo ?? this.updateInfo,
      error: error ?? this.error,
      hasUpdate: hasUpdate ?? this.hasUpdate,
    );
  }
}

class UpdateNotifier extends Notifier<UpdateState> {
  // Replace this with your actual version config URL
  static const String _updateUrl = 'https://raw.githubusercontent.com/jakir-hossen-4928/bd-sheba/main/version.json';

  @override
  UpdateState build() {
    return UpdateState();
  }

  Future<void> checkForUpdate() async {
    state = state.copyWith(isChecking: true, error: null);

    try {
      final response = await http.get(Uri.parse(_updateUrl)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final updateInfo = UpdateInfo.fromJson(data);
        
        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersionCode = int.parse(packageInfo.buildNumber);

        if (updateInfo.latestVersionCode > currentVersionCode) {
          state = state.copyWith(
            isChecking: false,
            updateInfo: updateInfo,
            hasUpdate: true,
          );
        } else {
          state = state.copyWith(isChecking: false, hasUpdate: false);
        }
      } else {
        state = state.copyWith(
          isChecking: false,
          error: 'Failed to check for update: ${response.statusCode}',
        );
      }
    } catch (e) {
      state = state.copyWith(isChecking: false, error: e.toString());
    }
  }
}

final updateProvider = NotifierProvider<UpdateNotifier, UpdateState>(
  UpdateNotifier.new,
);
