
# REQUIREMENTS

Developed and tested on WSL with Ubuntu v24 (v22 should work too).

1) ARM GNU toolchain
2) AARCH64 QEMU
3) gdb-multiarch

# QUICKSTART
Run `make ascl` to build the aarch64 executable "ascl"

Run `make clean` to clean.

Run `.\qemu.sh` to execute.

# DEBUGGING

First, have two separate windows opened to this directory.

In the first one, run `.\qemudb.sh`.

In the second one, run `gdb-multiarch`. 

Once gdb is open, run: `(gdb) target remote :1234`


Now GDB to you heart's content. Use `(gdb) break file:line` (i.e main.c:33, ascl.s:22) and `(gdb) print var` (remember to use $x0 for registers) and `(gdb) continue ` most commonly, but any gdb command should work.





