#include <stdio.h>

int main() {
	FILE *fp;

	fp = fopen("/tmp/hacked.txt", "w");

	if (fp == NULL) {
		perror("Error creating file..");
		return 1;
	}

	fprintf(fp, "hacked!!");

	fclose(fp);
	return 0;
}
