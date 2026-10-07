void explode(int depth) {
  if (depth == 0) {
    throw StateError('boom');
  }
  explode(depth - 1);
}

void main() {
  try {
    explode(2);
  } catch (error, stack) {
    print(stack);
  }
}
