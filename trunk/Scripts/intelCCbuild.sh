export cwd=`pwd`; icc -D _SLKP_LFENGINE_REWRITE_ -D __UNIX__ -w -o HYPHYMPICC -msse3 -static -mdynamic-no-pic -O3 -no-prec-div -fpermissive -I$cwd/Source -$cwd/Source/SQLite -D INTPTR_TYPE=long -openmp  -D __MP__ -D __MP2__ -unroll4 Source/*cpp Source/SQLite/*.c Source/main-unix.cxx -lssl -lcrypto -lcurl -lm
