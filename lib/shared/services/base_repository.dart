import 'package:cloud_firestore/cloud_firestore.dart';

/// Base repository interface for common CRUD operations
/// Provides a unified approach for data access across modules
abstract class BaseRepository<T> {
  /// Collection reference for Firestore operations
  CollectionReference get collection;

  /// Convert Firestore document to model
  T fromFirestore(DocumentSnapshot doc);

  /// Convert model to Firestore data
  Map<String, dynamic> toFirestore(T model);

  /// Get document by ID
  Future<T?> getById(String id) async {
    try {
      final doc = await collection.doc(id).get();
      if (doc.exists) {
        return fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw RepositoryException('Failed to get document by ID: $id', e);
    }
  }

  /// Get all documents
  Future<List<T>> getAll() async {
    try {
      final snapshot = await collection.get();
      return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
    } catch (e) {
      throw RepositoryException('Failed to get all documents', e);
    }
  }

  /// Get documents with query
  Future<List<T>> getWhere({
    String? field,
    dynamic value,
    Query Function(Query query)? queryBuilder,
  }) async {
    try {
      Query query = collection;

      if (field != null && value != null) {
        query = query.where(field, isEqualTo: value);
      }

      if (queryBuilder != null) {
        query = queryBuilder(query);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
    } catch (e) {
      throw RepositoryException('Failed to query documents', e);
    }
  }

  /// Create new document
  Future<String> create(T model) async {
    try {
      final docRef = await collection.add(toFirestore(model));
      return docRef.id;
    } catch (e) {
      throw RepositoryException('Failed to create document', e);
    }
  }

  /// Create document with specific ID
  Future<void> createWithId(String id, T model) async {
    try {
      await collection.doc(id).set(toFirestore(model));
    } catch (e) {
      throw RepositoryException('Failed to create document with ID: $id', e);
    }
  }

  /// Update existing document
  Future<void> update(String id, T model) async {
    try {
      await collection.doc(id).update(toFirestore(model));
    } catch (e) {
      throw RepositoryException('Failed to update document: $id', e);
    }
  }

  /// Update specific fields
  Future<void> updateFields(String id, Map<String, dynamic> fields) async {
    try {
      await collection.doc(id).update(fields);
    } catch (e) {
      throw RepositoryException('Failed to update fields for document: $id', e);
    }
  }

  /// Delete document
  Future<void> delete(String id) async {
    try {
      await collection.doc(id).delete();
    } catch (e) {
      throw RepositoryException('Failed to delete document: $id', e);
    }
  }

  /// Check if document exists
  Future<bool> exists(String id) async {
    try {
      final doc = await collection.doc(id).get();
      return doc.exists;
    } catch (e) {
      throw RepositoryException('Failed to check document existence: $id', e);
    }
  }

  /// Get documents count
  Future<int> count() async {
    try {
      final snapshot = await collection.get();
      return snapshot.docs.length;
    } catch (e) {
      throw RepositoryException('Failed to count documents', e);
    }
  }

  /// Get documents with pagination
  Future<PaginatedResult<T>> getPaginated({
    int limit = 20,
    DocumentSnapshot? startAfter,
    String? orderBy,
    bool descending = false,
  }) async {
    try {
      Query query = collection;

      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      query = query.limit(limit);

      final snapshot = await query.get();
      final items = snapshot.docs.map((doc) => fromFirestore(doc)).toList();

      return PaginatedResult<T>(
        items: items,
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        hasMore: snapshot.docs.length == limit,
      );
    } catch (e) {
      throw RepositoryException('Failed to get paginated documents', e);
    }
  }

  /// Listen to document changes
  Stream<T?> listenById(String id) {
    return collection.doc(id).snapshots().map((doc) {
      if (doc.exists) {
        return fromFirestore(doc);
      }
      return null;
    });
  }

  /// Listen to collection changes
  Stream<List<T>> listenToAll() {
    return collection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
    });
  }

  /// Listen to query changes
  Stream<List<T>> listenToWhere({
    String? field,
    dynamic value,
    Query Function(Query query)? queryBuilder,
  }) {
    Query query = collection;

    if (field != null && value != null) {
      query = query.where(field, isEqualTo: value);
    }

    if (queryBuilder != null) {
      query = queryBuilder(query);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
    });
  }

  /// Batch operations
  Future<void> batchWrite(List<BatchOperation<T>> operations) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      for (final operation in operations) {
        switch (operation.type) {
          case BatchOperationType.create:
            final model = operation.model;
            if (model == null) {
              throw ArgumentError('Model cannot be null for create operation');
            }
            if (operation.id != null) {
              batch.set(collection.doc(operation.id), toFirestore(model));
            } else {
              batch.set(collection.doc(), toFirestore(model));
            }
            break;
          case BatchOperationType.update:
            final id = operation.id;
            final model = operation.model;
            if (id == null) {
              throw ArgumentError('ID cannot be null for update operation');
            }
            if (model == null) {
              throw ArgumentError('Model cannot be null for update operation');
            }
            batch.update(collection.doc(id), toFirestore(model));
            break;
          case BatchOperationType.delete:
            final id = operation.id;
            if (id == null) {
              throw ArgumentError('ID cannot be null for delete operation');
            }
            batch.delete(collection.doc(id));
            break;
        }
      }

      await batch.commit();
    } catch (e) {
      throw RepositoryException('Failed to execute batch operations', e);
    }
  }
}

/// Paginated result wrapper
class PaginatedResult<T> {
  final List<T> items;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;

  const PaginatedResult({required this.items, this.lastDocument, required this.hasMore});
}

/// Batch operation definition
class BatchOperation<T> {
  final BatchOperationType type;
  final String? id;
  final T? model;

  const BatchOperation.create(this.model, {this.id}) : type = BatchOperationType.create;
  const BatchOperation.update(this.id, this.model) : type = BatchOperationType.update;
  const BatchOperation.delete(this.id) : type = BatchOperationType.delete, model = null;
}

/// Batch operation types
enum BatchOperationType { create, update, delete }

/// Repository exception for error handling
class RepositoryException implements Exception {
  final String message;
  final dynamic originalError;

  const RepositoryException(this.message, [this.originalError]);

  @override
  String toString() {
    if (originalError != null) {
      return 'RepositoryException: $message\nOriginal error: $originalError';
    }
    return 'RepositoryException: $message';
  }
}

/// Mixin for common repository functionality
mixin RepositoryMixin<T> {
  /// Validate model before operations
  void validateModel(T model) {
    // Override in concrete repositories for specific validation
  }

  /// Handle repository errors
  Never handleError(String operation, dynamic error) {
    throw RepositoryException('Failed to $operation', error);
  }

  /// Log repository operations (can be overridden)
  void logOperation(String operation, [Map<String, dynamic>? details]) {
    // Override for logging implementation
  }
}

/// Abstract base for cached repositories
abstract class CachedRepository<T> extends BaseRepository<T> {
  final Map<String, T> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Duration cacheDuration;

  CachedRepository({this.cacheDuration = const Duration(minutes: 5)});

  @override
  Future<T?> getById(String id) async {
    // Check cache first
    if (_isValidCacheEntry(id)) {
      return _cache[id];
    }

    // Fetch from repository
    final result = await super.getById(id);
    if (result != null) {
      _updateCache(id, result);
    }

    return result;
  }

  /// Clear cache
  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  /// Clear specific cache entry
  void clearCacheEntry(String id) {
    _cache.remove(id);
    _cacheTimestamps.remove(id);
  }

  bool _isValidCacheEntry(String id) {
    if (!_cache.containsKey(id)) return false;

    final timestamp = _cacheTimestamps[id];
    if (timestamp == null) return false;

    return DateTime.now().difference(timestamp) < cacheDuration;
  }

  void _updateCache(String id, T model) {
    _cache[id] = model;
    _cacheTimestamps[id] = DateTime.now();
  }
}
