Primeiramente, precisa ajustar a variável global "path_abs" localizada na linha 4 do arquivo
"main.cu" na pasta src/, subsituindo pelo path de acordo com sua máquina.

Para compilar o programa, escreva a seguinte linha de comando no terminal: 
	nvcc src/main.cu -o main_cuda

Execute utilizando ./main_cuda