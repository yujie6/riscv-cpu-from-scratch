#!/bin/bash
test='testdata'

build_test(){
		set -e
		Green='\e[0;32m'        # Green
		BGreen='\e[1;32m'       # Green
		NC='\e[m'

		prefix='/opt/riscv'
		rpath=$prefix/bin/
		# clearing test dir
		if [ ! -e './testdata' ]
		then
			mkdir -p ./$test/bin
			mkdir -p ./$test/data
			mkdir -p ./$test/dump
			mkdir -p ./$test/om
		fi
		tool1=riscv32-unknown-elf-
		tool2=riscv32-unknown-linux-gnu-
		tool=${tool1}
		# compiling rom
		${rpath}${tool}as -o ./sys/rom.o -march=rv32i ./sys/rom.s
		# compiling testcase
		cp ./testcase/$1.c ./$test/$1.c
		${rpath}${tool}gcc -o ./$test/$1.o -I ./sys -c ./$test/$1.c -O2 -march=rv32i -mabi=ilp32 -Wall
		# linking
		${rpath}${tool}ld -T ./sys/memory.ld ./sys/rom.o ./$test/$1.o -L $prefix/riscv32-unknown-elf/lib/ -L $prefix/lib/gcc/riscv32-unknown-elf/9.2.0/ -lc -lm -lgcc -lnosys -o ./$test/$1.om
		# converting to verilog format
		${rpath}${tool}objcopy -O verilog ./$test/$1.om ./$test/$1.data
		# converting to binary format(for ram uploading)
		${rpath}${tool}objcopy -O binary ./$test/$1.om ./$test/$1.bin
		# decompile (for debugging)
		${rpath}${tool}objdump -D ./$test/$1.om > ./$test/$1.dump
		mv ./$test/$1.bin ./$test/bin/
		mv ./$test/$1.dump ./$test/dump/
		mv ./$test/$1.om ./$test/om/
		mv ./$test/$1.data ./$test/data/
		rm ./$test/$1.o
		rm ./$test/$1.c
		echo -e "Build test file for $1 ${BGreen}Complete${NC}"
}


if [[ $1 == 'all' ]]
then
		for i in $(ls ./testcase/*.c)
		do
			a=${i//'.c'/}
			b=${a//'./testcase/'/}
			build_test $b
		done
fi

if [[ $1 == "clean" ]]
then
	rm -rf $test
fi
