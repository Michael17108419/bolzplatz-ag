/// Deterministic random numbers for the whole game.
///
/// The algorithm is xoshiro128** with all arithmetic kept inside 32 bits and
/// without overflowing 53 bits, so the same seed gives the same sequence on
/// every platform. Nothing here uses the platform random source.
class SeededRandom {
  /// Creates a generator from a seed in the range 0 to 2^32 - 1.
  SeededRandom(int seed)
    : seed = seed & _mask,
      _s0 = 0,
      _s1 = 0,
      _s2 = 0,
      _s3 = 0 {
    var z = this.seed;
    z = (z + _golden) & _mask;
    _s0 = _mix32(z);
    z = (z + _golden) & _mask;
    _s1 = _mix32(z);
    z = (z + _golden) & _mask;
    _s2 = _mix32(z);
    z = (z + _golden) & _mask;
    _s3 = _mix32(z);
  }

  static const int _mask = 0xFFFFFFFF;
  static const int _golden = 0x9E3779B9;
  static const int _two32 = 0x100000000;

  /// The seed this generator was created with.
  final int seed;

  int _s0;
  int _s1;
  int _s2;
  int _s3;

  /// Multiplies two unsigned 32-bit values modulo 2^32 without leaving the
  /// range that is exact on every platform.
  static int _mul32(int a, int b) {
    final low = (a & 0xFFFF) * b;
    final high = (((a >>> 16) * b) & 0xFFFF) << 16;
    return (low + high) & _mask;
  }

  static int _rotl(int x, int k) => ((x << k) | (x >>> (32 - k))) & _mask;

  /// Murmur3 finalizer, used for seeding and for deriving child seeds.
  static int _mix32(int input) {
    var x = input & _mask;
    x ^= x >>> 16;
    x = _mul32(x, 0x85EBCA6B);
    x ^= x >>> 13;
    x = _mul32(x, 0xC2B2AE35);
    x ^= x >>> 16;
    return x & _mask;
  }

  static int _fnv1a32(String text) {
    var h = 0x811C9DC5;
    for (final unit in text.codeUnits) {
      h ^= unit;
      h = _mul32(h, 0x01000193);
    }
    return h;
  }

  /// Next unsigned 32-bit value.
  int nextUint32() {
    final result = _mul32(_rotl(_mul32(_s1, 5), 7), 9);
    final t = (_s1 << 9) & _mask;
    _s2 ^= _s0;
    _s3 ^= _s1;
    _s1 ^= _s2;
    _s0 ^= _s3;
    _s2 ^= t;
    _s3 = _rotl(_s3, 11);
    return result;
  }

  /// Uniform integer from 0 (inclusive) to [max] (exclusive), without bias.
  int nextInt(int max) {
    if (max <= 0 || max > _two32) {
      throw ArgumentError.value(max, 'max', 'must be in 1..2^32');
    }
    final limit = _two32 - (_two32 % max);
    while (true) {
      final v = nextUint32();
      if (v < limit) return v % max;
    }
  }

  /// Uniform integer from [min] to [max], both inclusive.
  int nextIntInRange(int min, int max) {
    if (max < min) {
      throw ArgumentError('max must not be smaller than min');
    }
    return min + nextInt(max - min + 1);
  }

  /// Uniform double in [0, 1) with 53 random bits.
  double nextDouble() {
    final a = nextUint32() >>> 5;
    final b = nextUint32() >>> 6;
    return (a * 67108864 + b) / 9007199254740992.0;
  }

  /// True with the given probability.
  bool nextBool([double probability = 0.5]) => nextDouble() < probability;

  /// Approximately normal value with mean 0 and standard deviation 1.
  ///
  /// Uses the sum of twelve uniform values, which needs only additions and
  /// therefore gives identical results on every platform.
  double nextGaussian() {
    var sum = 0.0;
    for (var i = 0; i < 12; i++) {
      sum += nextDouble();
    }
    return sum - 6.0;
  }

  /// Picks one element of a non-empty list.
  T pick<T>(List<T> items) {
    if (items.isEmpty) throw ArgumentError('items must not be empty');
    return items[nextInt(items.length)];
  }

  /// Index chosen with probability proportional to its weight.
  int weightedIndex(List<double> weights) {
    var total = 0.0;
    for (final w in weights) {
      if (w < 0) throw ArgumentError('weights must not be negative');
      total += w;
    }
    if (total <= 0) throw ArgumentError('weights must have a positive sum');
    final r = nextDouble() * total;
    var acc = 0.0;
    for (var i = 0; i < weights.length; i++) {
      acc += weights[i];
      if (r < acc) return i;
    }
    return weights.length - 1;
  }

  /// Shuffles [items] in place (Fisher-Yates).
  void shuffle<T>(List<T> items) {
    for (var i = items.length - 1; i > 0; i--) {
      final j = nextInt(i + 1);
      final tmp = items[i];
      items[i] = items[j];
      items[j] = tmp;
    }
  }

  /// A new, independent generator for a named purpose.
  ///
  /// The child depends only on this generator's seed and the label, never on
  /// how many numbers were drawn before. This keeps parts of the world stable
  /// when other parts change.
  SeededRandom fork(String label) {
    return SeededRandom(
      _mix32((_mul32(seed, 0x9E3779B1) + _fnv1a32(label)) & _mask),
    );
  }
}
