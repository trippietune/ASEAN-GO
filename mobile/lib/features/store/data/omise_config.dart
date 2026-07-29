/// Omise's publishable key — safe to embed in client code (it can only
/// create tokens, never charge or refund). Override at build time with
/// --dart-define=OMISE_PUBLIC_KEY=pkey_test_... once a real sandbox key
/// exists; until then tokenization calls fail with a clear error rather
/// than silently hitting Omise with an empty key.
const omisePublicKey = String.fromEnvironment('OMISE_PUBLIC_KEY');

bool get isOmiseConfigured => omisePublicKey.isNotEmpty;
