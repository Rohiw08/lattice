import 'package:uuid/uuid.dart';

/// Utility class for generating unique identifiers for flow canvas elements.
///
/// Uses RFC4122 UUID v4 (random) for cryptographically strong unique IDs
/// with negligible collision probability. For 1 billion generated IDs,
/// the collision probability is approximately 10^-18.
///
/// ## Why UUID?
///
/// UUIDs provide several advantages over custom ID generation:
/// - **Cryptographically secure**: Uses strong random number generation
/// - **Globally unique**: Safe across distributed systems without coordination
/// - **Collision-resistant**: Practically impossible to generate duplicates
/// - **Standard format**: RFC4122 compliant, widely recognized
/// - **No central authority**: Each client can generate IDs independently
///
/// ## Performance
///
/// UUID generation is very fast (microseconds) and suitable for real-time
/// applications. While UUIDs are larger than integers (128 bits vs 32/64 bits),
/// the overhead is negligible for most use cases.
///
/// ## Alternative: UUID v7
///
/// If you need time-ordered IDs for database indexing performance,
/// consider UUID v7 which embeds timestamps while maintaining uniqueness.
///
/// See also:
///
///  * [Uuid] class from the uuid package
///  * RFC4122: https://www.ietf.org/rfc/rfc4122.txt
///  * RFC9562: https://www.ietf.org/rfc/rfc9562.txt (UUID v6, v7, v8)
class IdGenerator {
  /// Private constructor to prevent instantiation.
  const IdGenerator._();

  /// Singleton UUID generator instance.
  ///
  /// Reusing a single instance is more efficient than creating new
  /// instances for each ID generation.
  static const _uuid = Uuid();

  /// Generates a unique node ID using UUID v4 (random).
  ///
  /// Returns a string in the format: 'node_xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
  /// where x is a hexadecimal digit and y is one of 8, 9, A, or B.
  ///
  /// Example:
  /// ```
  /// final id = generateNodeId();
  /// // Returns: 'node_550e8400-e29b-41d4-a716-446655440000'
  /// ```
  ///
  /// ## Collision Probability
  ///
  /// - 1 million IDs: ~10^-24 collision probability
  /// - 1 billion IDs: ~10^-18 collision probability
  /// - 1 trillion IDs: ~10^-15 collision probability
  ///
  /// To put this in perspective, you're more likely to be hit by a meteorite
  /// than to generate two identical UUIDs in normal usage.
  static String generateNodeId() {
    return 'node_${_uuid.v4()}';
  }

  /// Generates a unique edge ID using UUID v4 (random).
  ///
  /// Returns a string in the format: 'edge_xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
  ///
  /// Example:
  /// ```
  /// final id = generateEdgeId();
  /// // Returns: 'edge_8f3e4a2b-1c9d-4e5f-a8b3-7c6d5e4f3a2b'
  /// ```
  static String generateEdgeId() {
    return 'edge_${_uuid.v4()}';
  }

  /// Generates a unique handle/port ID using UUID v4 (random).
  ///
  /// Returns a string in the format: 'handle_xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
  ///
  /// Example:
  /// ```
  /// final id = generateHandleId();
  /// // Returns: 'handle_7b2c1d9e-3f4a-4b5c-9d6e-8f7a6b5c4d3e'
  /// ```
  static String generateHandleId() {
    return 'handle_${_uuid.v4()}';
  }

  /// Generates a raw UUID v4 without any prefix.
  ///
  /// Useful when you need a pure UUID string for other purposes.
  ///
  /// Example:
  /// ```
  /// final id = generateUuid();
  /// // Returns: '6ba7b810-9dad-11d1-80b4-00c04fd430c8'
  /// ```
  static String generateUuid() {
    return _uuid.v4();
  }

  /// Generates a time-ordered UUID v7 with optional prefix.
  ///
  /// UUID v7 embeds a timestamp in the high-order bits, resulting in
  /// monotonically increasing IDs. This provides:
  /// - Better database index performance (less page splitting)
  /// - Natural time-based sorting
  /// - Still globally unique across systems
  ///
  /// Use this when database performance is critical and you need
  /// chronological ordering of IDs.
  ///
  /// Example:
  /// ```
  /// final id = generateTimeOrderedId('node');
  /// // Returns: 'node_018c3f42-8e2f-7xxx-xxxx-xxxxxxxxxxxx'
  /// // The first part (018c3f42-8e2f-7xxx) contains the timestamp
  /// ```
  ///
  /// See also:
  ///
  ///  * RFC9562 for UUID v7 specification
  static String generateTimeOrderedId([String? prefix]) {
    final id = _uuid.v7();
    return prefix != null ? '${prefix}_$id' : id;
  }

  /// Generates a compact, URL-safe unique ID.
  ///
  /// Returns a shorter ID (22 characters) that's URL-safe and has similar
  /// collision resistance to UUID v4. Useful when you need shorter IDs
  /// for URLs or display purposes.
  ///
  /// Uses base64 URL-safe encoding of a UUID v4.
  ///
  /// Example:
  /// ```
  /// final id = generateCompactId();
  /// // Returns: 'X3JJU09NX0lE'
  /// ```
  static String generateCompactId([String? prefix]) {
    // Generate UUID v4 and convert to compact format
    final uuid = _uuid.v4obj();
    // Convert UUID bytes to base64url (URL-safe, no padding)
    final bytes = uuid.toBytes();
    final base64 = Uri.encodeComponent(
      String.fromCharCodes(bytes),
    ).replaceAll('%', '');

    return prefix != null ? '${prefix}_$base64' : base64;
  }
}
