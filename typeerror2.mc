bool f1 (int x, int y) {
   return (true);
}

int f2 (int x, int y) {
   return (true);
}

int main() {
  int a;
  int b;
  bool c;
  a = getint(); b = getint();
  c = getint();
  c = f1(2,b);
  c = f1(a,b,2);
  b = f1(a,b);
  c = f2(a,b);
  b = f2(a,c);
  b = f3(b);
  a = b(a);
}


