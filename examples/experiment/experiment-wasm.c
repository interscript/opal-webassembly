void *retpointer(void *ptr) {
  return ptr;
}

float retfloat(float f) {
  return -f*2;
}

double retdouble(double f) {
  return -f*2;
}

char *retstring(char *c) {
  c[3] += 1;
  c[5] += 1;
  return c+2;
}

int longsize(void)       { return sizeof(long); }
int longlongsize(void)   { return sizeof(long long); }
int ptrsize(void)        { return sizeof(void*); }
int floatsize(void)      { return sizeof(float); }
int doublesize(void)     { return sizeof(double); }
int longdoublesize(void) { return sizeof(long double); }

struct test_struct {
  int a;
  long long b;
  char c;
  int d;
  char e;
  void *f;
  char g;
  long double h;
} test_struct;

int structalignll(void) { return (long)&test_struct.b - (long)&test_struct.a; }
int structaligni(void)  { return (long)&test_struct.d - (long)&test_struct.c; }
int structalignp(void)  { return (long)&test_struct.f - (long)&test_struct.e; }
int structalignld(void) { return (long)&test_struct.h - (long)&test_struct.g; }

////// BASIC stdlib below:
extern unsigned char __heap_base;

unsigned int bump_pointer = (unsigned int)&__heap_base;

//// Adapted from: https://github.com/WebAssembly/wasi-libc / musl
void *memcpy(void *restrict dest, const void *restrict src, unsigned long n)
{
	unsigned char *d = dest;
	const unsigned char *s = src;
	for (; n; n--) *d++ = *s++;
	return dest;
}

// IT LEAKS BY DESIGN; adapted from: https://surma.dev/things/c-to-webassembly/
void* malloc(unsigned long n) {
  unsigned int r = bump_pointer;
  bump_pointer += 4 + ((n|3)+1);
  unsigned long *ptr = (unsigned long *)r;
  *ptr = n;
  return (void *)(ptr + 1);
}

void free(void* p) {
  // lol
}

void *realloc(void *ptr, unsigned long size) {
  unsigned int cursize = *(int *)(ptr - 4);
  void *newptr = malloc(size);
  memcpy(newptr, ptr, cursize);
  return newptr;
}
