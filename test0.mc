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
	{
		bool y;
		int z;
		b.x = x+getint();
		a[3] = 5;
		return(b.x);
	}
  x = 5;
  return (x + 1);
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


