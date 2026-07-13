import 'dart:typed_data';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Wrapper de Firebase Storage para upload de documentos (driver, vehicle,
/// partner). Cria simultaneamente uma entrada em
/// `/documents/{ownerType}/{ownerId}/{docId}` na RTDB com URL público,
/// status `pending` e timestamp.
class StorageService {
  StorageService({FirebaseStorage? storage, FirebaseDatabase? database})
      : _storage = storage ?? FirebaseStorage.instance,
        _database = database ?? FirebaseDatabase.instance;

  final FirebaseStorage _storage;
  final FirebaseDatabase _database;

  /// Faz upload de uma imagem para Storage e devolve o URL público — sem
  /// criar entrada em `/documents` (ao contrário de [uploadDocument]; usa-se
  /// para fotos que não passam por aprovação, ex.: foto de veículo).
  /// [pathPrefix] segue o padrão de regras `documents/{ownerType}/{ownerId}`
  /// já aberto no storage.rules (qualquer utilizador autenticado escreve,
  /// validado por tamanho/content-type).
  Future<String> uploadImage({
    required Uint8List bytes,
    required String pathPrefix,
    required String filename,
    String? contentType,
  }) async {
    final String ext = _extensionOf(filename);
    final int millis = DateTime.now().millisecondsSinceEpoch;
    final Reference ref = _storage.ref('$pathPrefix/$millis.$ext');
    final SettableMetadata metadata = SettableMetadata(
      contentType: contentType ?? _contentTypeFor(ext),
    );
    final TaskSnapshot snap = await ref.putData(bytes, metadata);
    return snap.ref.getDownloadURL();
  }

  /// Faz upload do conteúdo `bytes` para Storage e regista o documento na
  /// RTDB. Devolve o `docId` gerado (push key).
  ///
  /// [ownerType] ∈ `driver | vehicle | partner`.
  /// [docType] é livre (ex: `licence`, `medical`, `insurance`).
  /// [filename] é usado para inferir extensão; default `.pdf` se não tem.
  Future<String> uploadDocument({
    required Uint8List bytes,
    required String ownerType,
    required String ownerId,
    required String docType,
    required String filename,
    String? contentType,
    DateTime? expiresAt,
  }) async {
    final String ext = _extensionOf(filename);
    final int millis = DateTime.now().millisecondsSinceEpoch;
    final String storagePath =
        'documents/$ownerType/$ownerId/$docType-$millis.$ext';

    final Reference ref = _storage.ref(storagePath);
    final SettableMetadata metadata = SettableMetadata(
      contentType: contentType ?? _contentTypeFor(ext),
    );
    final TaskSnapshot snap = await ref.putData(bytes, metadata);
    final String url = await snap.ref.getDownloadURL();

    final DatabaseReference dbRef =
        _database.ref('documents/$ownerType/$ownerId').push();
    final String docId = dbRef.key as String;
    await dbRef.set(<String, dynamic>{
      'type': docType,
      'url': url,
      'storagePath': storagePath,
      'filename': filename,
      'status': 'pending',
      'uploadedAt': DateTime.now().toIso8601String(),
      if (expiresAt != null) 'expiresAt': expiresAt.toIso8601String(),
    });

    return docId;
  }

  /// Aprova um documento existente. Apenas admins têm permissão por rules.
  Future<void> approveDocument({
    required String ownerType,
    required String ownerId,
    required String docId,
  }) async {
    await _database
        .ref('documents/$ownerType/$ownerId/$docId')
        .update(<String, dynamic>{
      'status': 'approved',
      'approvedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Rejeita um documento, opcionalmente com motivo.
  Future<void> rejectDocument({
    required String ownerType,
    required String ownerId,
    required String docId,
    String? reason,
  }) async {
    await _database
        .ref('documents/$ownerType/$ownerId/$docId')
        .update(<String, dynamic>{
      'status': 'rejected',
      'rejectedAt': DateTime.now().toIso8601String(),
      if (reason != null) 'rejectionReason': reason,
    });
  }

  /// Apaga um documento da RTDB e do Storage (best-effort no Storage).
  Future<void> deleteDocument({
    required String ownerType,
    required String ownerId,
    required String docId,
  }) async {
    final DatabaseReference dbRef =
        _database.ref('documents/$ownerType/$ownerId/$docId');
    final DataSnapshot snap = await dbRef.get();
    if (!snap.exists) return;
    final Map<dynamic, dynamic> data =
        Map<dynamic, dynamic>.from(snap.value as Map);
    final String? storagePath = data['storagePath'] as String?;
    await dbRef.remove();
    if (storagePath != null) {
      try {
        await _storage.ref(storagePath).delete();
      } catch (_) {
        // best-effort
      }
    }
  }

  String _extensionOf(String filename) {
    final int dot = filename.lastIndexOf('.');
    if (dot == -1 || dot == filename.length - 1) return 'pdf';
    return filename.substring(dot + 1).toLowerCase();
  }

  String _contentTypeFor(String ext) {
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      default:
        return 'application/octet-stream';
    }
  }
}
