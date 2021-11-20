parell: main.o threads.o lista_th.o lista.o 
	nvcc -o parell main.o threads.o lista_th.o lista.o -lpthread -fopenmp

main.o: src/main.cu src/main.h src/libs/lib_thread/threads.h src/libs/lib_lista_int/lista.h src/libs/lib_thread/lista_th.h
	nvcc -c src/main.cu
	
threads.o: src/libs/lib_thread/threads.cu src/libs/lib_thread/threads.h src/libs/lib_lista_int/lista.h src/libs/lib_thread/lista_th.h -lpthread
	nvcc -c src/libs/lib_thread/threads.cu

lista_th.o: src/libs/lib_thread/lista_th.cu src/libs/lib_thread/lista_th.h
	nvcc -c src/libs/lib_thread/lista_th.cu

lista.o: src/libs/lib_lista_int/lista.cu src/libs/lib_lista_int/lista.h
	nvcc -c src/libs/lib_lista_int/lista.cu	