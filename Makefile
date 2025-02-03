ascl:
	aarch64-linux-gnu-as -g -o ascl.o ascl.s
	aarch64-linux-gnu-gcc -g -c -o main.o main.c 
	aarch64-linux-gnu-gcc -g -o ascl ascl.o main.o -lc -lm

clean:
	rm ascl.o main.o ascl 
