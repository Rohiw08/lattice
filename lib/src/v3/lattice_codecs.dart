// Node-data codec signatures for the V3 rewrite.
//
// `LatticeNode.toJson` / `LatticeNode.fromJson` accept these to convert the
// opaque `data` payload to and from JSON-safe values. When null, `data`
// passes through by reference untouched.
typedef EncodeNodeData = Object? Function(String type, Object? data);
typedef DecodeNodeData = Object? Function(String type, Object? json);
