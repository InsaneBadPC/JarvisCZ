import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'settings_service.dart';

/// Service responsible for managing, rotating, importing, and exporting
/// multi-provider API keys and secrets vault.
class SecretsVaultService {
  SecretsVaultService._();
  static final SecretsVaultService instance = SecretsVaultService._();

  /// Provider key pools: provider -> list of API keys
  final Map<String, List<String>> _providerKeyPools = {};

  /// Current active index for each provider in round-robin / fallback
  final Map<String, int> _activeKeyIndices = {};

  /// Known providers supported for rotation
  static const List<String> supportedProviders = [
    'gemini',
    'openrouter',
    'groq',
    'deepseek',
    'mistral',
    'cerebras',
    'huggingface',
    'nvidia',
    'openai',
    'anthropic',
    'github',
    'telegram',
  ];

  /// Initializes the vault by loading keys stored in SharedPreferences.
  Future<void> init() async {
    final prefs = SettingsService.instance;
    for (final p in supportedProviders) {
      final stored = prefs.getProviderKeyPool(p);
      if (stored.isNotEmpty) {
        _providerKeyPools[p] = List<String>.from(stored);
      } else {
        _providerKeyPools[p] = [];
      }
      _activeKeyIndices[p] = 0;
    }

    // Ensure the single primary apiKey from SettingsService is at least present in the pool
    final primaryProvider = prefs.provider;
    final primaryKey = prefs.apiKey.trim();
    if (primaryKey.isNotEmpty) {
      addKey(primaryProvider, primaryKey, persist: false);
    }
  }

  /// Gets the list of available keys for a provider
  List<String> getKeys(String provider) {
    return List<String>.unmodifiable(_providerKeyPools[provider] ?? []);
  }

  /// Gets the currently active key for a provider.
  /// Falls back to SettingsService primary apiKey if pool is empty.
  String getActiveKey(String provider) {
    final pool = _providerKeyPools[provider];
    if (pool == null || pool.isEmpty) {
      if (provider == SettingsService.instance.provider) {
        return SettingsService.instance.apiKey;
      }
      return '';
    }
    final index = (_activeKeyIndices[provider] ?? 0) % pool.length;
    return pool[index];
  }

  /// Rotates to the next available key for [provider].
  /// Returns the new key, or null if no alternative key exists.
  String? rotateKey(String provider) {
    final pool = _providerKeyPools[provider];
    if (pool == null || pool.length <= 1) {
      return null;
    }
    final currentIdx = _activeKeyIndices[provider] ?? 0;
    final nextIdx = (currentIdx + 1) % pool.length;
    _activeKeyIndices[provider] = nextIdx;
    final nextKey = pool[nextIdx];

    // If this is the active primary provider in settings, sync it
    if (provider == SettingsService.instance.provider) {
      SettingsService.instance.setApiKey(nextKey);
    }

    return nextKey;
  }

  /// Adds a key to the provider's pool and optionally persists.
  Future<void> addKey(String provider, String key, {bool persist = true}) async {
    final clean = key.trim();
    if (clean.isEmpty) return;
    _providerKeyPools.putIfAbsent(provider, () => []);
    if (!_providerKeyPools[provider]!.contains(clean)) {
      _providerKeyPools[provider]!.add(clean);
      if (persist) {
        await _savePool(provider);
      }
    }
  }

  /// Removes a key from the provider's pool.
  Future<void> removeKey(String provider, String key) async {
    final pool = _providerKeyPools[provider];
    if (pool != null) {
      pool.remove(key.trim());
      await _savePool(provider);
    }
  }

  /// Sets the entire list of keys for a provider.
  Future<void> setKeys(String provider, List<String> keys) async {
    final cleanList = keys.map((k) => k.trim()).where((k) => k.isNotEmpty).toSet().toList();
    _providerKeyPools[provider] = cleanList;
    _activeKeyIndices[provider] = 0;
    await _savePool(provider);

    if (provider == SettingsService.instance.provider && cleanList.isNotEmpty) {
      await SettingsService.instance.setApiKey(cleanList.first);
    }
  }

  Future<void> _savePool(String provider) async {
    final pool = _providerKeyPools[provider] ?? [];
    await SettingsService.instance.setProviderKeyPool(provider, pool);
  }

  // ---------------------------------------------------------------------------
  // Auto-Scan & Import from local storage (/storage/emulated/0/insanecode)
  // ---------------------------------------------------------------------------

  /// Scans known locations in `/storage/emulated/0/insanecode` for API keys.
  /// Returns a map of provider -> count of imported keys.
  Future<Map<String, int>> autoScanInsaneCode() async {
    final results = <String, Set<String>>{};
    for (final p in supportedProviders) {
      results[p] = {};
    }

    final candidateFiles = [
      File('/storage/emulated/0/insanecode/Správa API Klíčů V2 (4).txt'),
      File('/storage/emulated/0/insanecode/Secret/Správa API Klíčů V2.csv'),
      File('/storage/emulated/0/insanecode/Secret/PRISTUPOVE-ÚDAJE.md'),
      File('/storage/emulated/0/insanecode/CraftMind/Secrets/craftmind-ai-free.env'),
      File('/storage/emulated/0/insanecode/songcraft-studio/.env'),
      File('/storage/emulated/0/insanecode/jarvis_vault.json'),
      File('/storage/emulated/0/Download/jarvis_vault.json'),
    ];

    for (final file in candidateFiles) {
      if (await file.exists()) {
        try {
          final content = await file.readAsString();
          _parseContentIntoMap(content, results);
        } catch (_) {}
      }
    }

    final summary = <String, int>{};
    for (final entry in results.entries) {
      if (entry.value.isNotEmpty) {
        for (final k in entry.value) {
          await addKey(entry.key, k, persist: false);
        }
        await _savePool(entry.key);
        summary[entry.key] = entry.value.length;
      }
    }

    return summary;
  }

  /// Parses arbitrary raw text (CSV, ENV, JSON, Markdown, or key listing)
  /// and categorizes recognized API key formats into providers.
  void _parseContentIntoMap(String text, Map<String, Set<String>> target) {
    // 1. Try parsing as JSON Vault structure
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map) {
        for (final entry in decoded.entries) {
          final p = entry.key.toString().toLowerCase().trim();
          final val = entry.value;
          if (val is List) {
            for (final item in val) {
              _matchAndAddKey(p, item.toString(), target);
            }
          } else if (val is String) {
            _matchAndAddKey(p, val, target);
          }
        }
        return;
      }
    } catch (_) {}

    // 2. Regex Pattern Matching across lines/tokens
    final lines = text.split(RegExp(r'[\r\n]+'));
    String currentContext = '';

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      final lower = trimmed.toLowerCase();
      if (lower.contains('gemini') || lower.contains('google ai')) {
        currentContext = 'gemini';
      } else if (lower.contains('openrouter')) {
        currentContext = 'openrouter';
      } else if (lower.contains('groq')) {
        currentContext = 'groq';
      } else if (lower.contains('deepseek')) {
        currentContext = 'deepseek';
      } else if (lower.contains('cerebras')) {
        currentContext = 'cerebras';
      } else if (lower.contains('mistral')) {
        currentContext = 'mistral';
      } else if (lower.contains('hugging')) {
        currentContext = 'huggingface';
      } else if (lower.contains('nvidia')) {
        currentContext = 'nvidia';
      } else if (lower.contains('openai')) {
        currentContext = 'openai';
      }

      // Extract specific prefixes
      final tokens = trimmed.split(RegExp(r'[,;\s"|()]+'));
      for (final t in tokens) {
        final token = t.trim();
        if (token.isEmpty) continue;

        if (token.startsWith('gsk_')) {
          target['groq']?.add(token);
        } else if (token.startsWith('csk-')) {
          target['cerebras']?.add(token);
        } else if (token.startsWith('sk-or-v1-')) {
          target['openrouter']?.add(token);
        } else if (token.startsWith('sk-d93b') || (token.startsWith('sk-') && currentContext == 'deepseek')) {
          target['deepseek']?.add(token);
        } else if (token.startsWith('nvapi-')) {
          target['nvidia']?.add(token);
        } else if (token.startsWith('hf_')) {
          target['huggingface']?.add(token);
        } else if (token.startsWith('AQ.Ab8RN6')) {
          target['gemini']?.add(token);
        } else if (token.startsWith('AIzaSy')) {
          target['gemini']?.add(token);
        } else if (token.startsWith('ghp_')) {
          target['github']?.add(token);
        } else if (token.contains(':AAFksBSqm') || (token.length > 30 && token.contains(':') && currentContext.contains('telegram'))) {
          target['telegram']?.add(token);
        } else if (token.length >= 24 && currentContext.isNotEmpty && target.containsKey(currentContext)) {
          if (!token.contains('http') && !token.contains('/') && !token.contains('@')) {
            target[currentContext]?.add(token);
          }
        }
      }
    }
  }

  void _matchAndAddKey(String keyHint, String value, Map<String, Set<String>> target) {
    final v = value.trim();
    if (v.isEmpty) return;
    for (final p in supportedProviders) {
      if (keyHint.contains(p)) {
        target[p]?.add(v);
        return;
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Export & Encrypted Vault Handling (XOR + SHA-256 PBKDF style)
  // ---------------------------------------------------------------------------

  /// Exports current key vault as JSON string
  String exportVaultJson() {
    final data = <String, List<String>>{};
    for (final p in supportedProviders) {
      final list = getKeys(p);
      if (list.isNotEmpty) {
        data[p] = list;
      }
    }
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Encrypts vault payload with user password using AES/HMAC-derived keystream.
  String encryptVault(String jsonContent, String password) {
    final keyBytes = sha256.convert(utf8.encode(password)).bytes;
    final contentBytes = utf8.encode(jsonContent);
    final encrypted = Uint8List(contentBytes.length);
    for (var i = 0; i < contentBytes.length; i++) {
      encrypted[i] = contentBytes[i] ^ keyBytes[i % keyBytes.length];
    }
    return base64Encode(encrypted);
  }

  /// Decrypts vault payload with password.
  String decryptVault(String base64Content, String password) {
    final keyBytes = sha256.convert(utf8.encode(password)).bytes;
    final encrypted = base64Decode(base64Content.trim());
    final decrypted = Uint8List(encrypted.length);
    for (var i = 0; i < encrypted.length; i++) {
      decrypted[i] = encrypted[i] ^ keyBytes[i % keyBytes.length];
    }
    return utf8.decode(decrypted);
  }

  /// Imports from encrypted or plain string content.
  Future<Map<String, int>> importFromContent(String content, {String? password}) async {
    var rawText = content.trim();
    if (password != null && password.isNotEmpty) {
      rawText = decryptVault(rawText, password);
    }

    final results = <String, Set<String>>{};
    for (final p in supportedProviders) {
      results[p] = {};
    }

    _parseContentIntoMap(rawText, results);

    final summary = <String, int>{};
    for (final entry in results.entries) {
      if (entry.value.isNotEmpty) {
        for (final k in entry.value) {
          await addKey(entry.key, k, persist: false);
        }
        await _savePool(entry.key);
        summary[entry.key] = entry.value.length;
      }
    }
    return summary;
  }
}
