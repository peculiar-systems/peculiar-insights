int fault_here(int *pointer) {
  return *pointer + 1;
}

int entry(int value) {
  return fault_here(0) + value;
}
