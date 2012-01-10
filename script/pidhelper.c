#include <getopt.h>
#include <stdio.h>
#include <stdlib.h>

int main (int argc, char **argv)
{
  int c;
  int pid = getpid();
  FILE *output = stdout;

  opterr = 0;

  while ((c = getopt(argc, argv, "spo:")) != -1) {
    switch (c) {
      case 'p':
        pid = getppid();
        break;
      case 's':
        pid = getpid();
        break;
      case 'o':
        output = fopen(optarg, "w");
        break;
      default:
        abort();
        break;
    }
  }

  fprintf(output, "%d\n", pid);

  return 0;
}
