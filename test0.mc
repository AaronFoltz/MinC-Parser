int [4] Aaron;
Aaron a;

{
	int x;
	bool y;
} Foltz;

Foltz f;
Foltz b;
int incr (int x) 
{
	b.x = true;
	x = 5;
	
  return (x);
}

int add (int x, int y, int z) {
  if (y == 0) return (x);
  else return (incr(add(x,y-1,z)));
}

bool main() {
  int a;
  int b;
  a = getint(); b = getint();
  printint(add (a, b, a)); 
}


