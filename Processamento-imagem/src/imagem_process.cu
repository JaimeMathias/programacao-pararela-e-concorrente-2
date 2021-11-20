#include "imagem_process.h"
#define RGB 3

#ifdef INSTALL_CUDA

unsigned char * cuda_malloc_managed_aux(unsigned int len)
{
	unsigned char * data;
	if ((data = (unsigned char *)malloc(sizeof(unsigned char *))) == NULL) {
		printf("Erro de Alocação de Memória 0x01\n");
		exit(1);
	}
	cudaMallocManaged(&data, sizeof(unsigned char) * len);

	if (data == NULL) {
		printf("Erro na alocação da memória 0x01\n");
		exit(1);
	}
}

__global__
void cuda_tonalidade_gray(unsigned char * data, unsigned char * data_aux, unsigned int header_size, unsigned int n)
{	
	int i = (blockIdx.x * blockDim.x + threadIdx.x) * 3 + header_size;
	if (i < n) {
		data_aux[i] = (int) ((0.299 * data[i]) + (0.587 * data[i + 1]) + (0.144 * data[i + 2])); //calcula o valor para conversão
		data_aux[i + 1] = data_aux[i]; //copia o valor para
		data_aux[i + 2] = data_aux[i];  //todas componentes

		if (data_aux[i] > 255) {
			data_aux[i] = 255;
			data_aux[i + 1] = 255;
			data_aux[i + 2] = 255;
		}
	} 
}

__global__
void cuda_inverte_image(unsigned char * data, unsigned char * data_aux,  unsigned int header_size, unsigned int n)
{
	int i = (blockIdx.x * blockDim.x + threadIdx.x);
	if (i < n) {
		data_aux[header_size + i] = data[n - i];
	}
}


__global__
void cuda_tonalidade_toogle_gray(unsigned char * data, unsigned char * data_aux, unsigned int header_size, unsigned int n, unsigned int largura)
{	
	int i = (blockIdx.x * blockDim.x + threadIdx.x) * 3 + header_size, k = 0;

	int largura_rgb = largura * 3;
	int divisao_res = (int) (i / largura_rgb);

	k = i;
	// if (divisao_res % 2 == 0) {
	// 	k += n / 2;
	// }

	// if (k < n) {
	if (k < n && divisao_res % 2 != 0) {
		data_aux[k] = (int) ((0.299 * data[k]) + (0.587 * data[k + 1]) + (0.144 * data[k + 2])); //calcula o valor para conversão
		data_aux[k + 1] = data_aux[k]; //copia o valor para
		data_aux[k + 2] = data_aux[k];  //todas componentes

			if (data_aux[k] > 255) {
				data_aux[k] = 255;
				data_aux[k + 1] = 255;
				data_aux[k + 2] = 255;
			}
	}
}

#endif

void print_data(unsigned char * data, unsigned int len)
{
	unsigned int i, k = 0;
	for (i = 0; i < len; i++, k++) {
		printf("%d. %c , %d\n", i, data[i], data[i]);
	}
	exit(1);
}

FILE * open_arquivo(char * str, char * modo) {

    FILE * arq; //Arquivo lógico
    if ((arq = fopen(str, modo)) == NULL) {
        printf("Erro na abertura do arquivo %s\n", "filename");
        exit(0x3);
    }
    return arq;
}

unsigned long get_len_fptr(FILE * f)
{
	fseek(f, 0, SEEK_END);
	unsigned long len = (unsigned long)ftell(f);
	fseek(f, SEEK_SET, 0);
	return len;
}

void read_file_bin(FILE* f, unsigned char * ptr, unsigned long len_esperado)
{
	unsigned long  qtd_bytes_read;
	qtd_bytes_read = fread(ptr, sizeof(unsigned char), len_esperado, f);
	if (qtd_bytes_read != len_esperado) {
		printf("Erro na Leitura do arquivo\n");
		printf("Número de bytes lidos %ld\n", qtd_bytes_read);
	} else
		printf("Leitura realizada com sucesso\n");
}

void grava_arquivo(char * path, unsigned char * ptr, int tamanho)
{
	FILE * f = open_arquivo(path, "wb");
    unsigned long qtd_bytes_gravados;
    qtd_bytes_gravados = fwrite(ptr, sizeof(unsigned char), tamanho, f);
    if(qtd_bytes_gravados != tamanho) { // verifica se a gravacao funcionou
	printf("Erro na gravacao do arquivo!\n");
	exit(1);
    } else
	printf("Gravacao realizada com sucesso! (%ld)\n", qtd_bytes_gravados);
}

unsigned char * read_image_input(char * _arq, unsigned long * _len_fptr)
{
	FILE* arq = open_arquivo(_arq, "rb");
	*_len_fptr = get_len_fptr(arq);
	printf("O tamanho do arquivo %s é %ld bytes.\n", _arq, *_len_fptr);

	unsigned char *ptr;
	//ptr =  (unsigned char *) malloc(sizeof(unsigned char) * *_len_fptr);
	cudaMallocManaged(&ptr, sizeof(unsigned char) * *_len_fptr);
	if (ptr == NULL) {
		printf("Erro na alocação da memória\n");
		exit(1);
	}
	read_file_bin(arq, ptr, *_len_fptr);
	fclose(arq);
	return ptr;
}

void config_params_date_aux(unsigned char * data_aux, unsigned char * data, unsigned int len_header)
{
	for (int i = 0; i < len_header; i++)
	{
		data_aux[i] = data[i];
	}
}

unsigned char * tonalidade_gray(unsigned char * data, unsigned int len_img, unsigned int x)
{
	unsigned char * data_aux = cuda_malloc_managed_aux(len_img);
	
	config_params_date_aux(data_aux, data, DEFAULT_HEADER_SIZE + x);
	unsigned int N = DEFAULT_HEADER_SIZE + x;

	printf("Aplicando tonalidade gray!\n");
	
	#ifdef INSTALL_CUDA

		int block_size = 1024;
		int len_img_pixel = (len_img - N) / 3;
		int num_blocks = (len_img_pixel + block_size - 1) / block_size;
		cuda_tonalidade_gray<<<num_blocks, block_size >>>(data, data_aux, N, len_img);
		cudaDeviceSynchronize();

	#endif

	#ifdef INSTALL_CPU

		for (unsigned int i = N; i < len_img; i += RGB) {
			data_aux[i] = (int) ((0.299 * data[i]) + (0.587 * data[i + 1]) + (0.144 * data[i + 2])); //calcula o valor para conversão
			data_aux[i + 1] = data_aux[i]; //copia o valor para
			data_aux[i + 2] = data_aux[i];  //todas componentes

			if (data_aux[i] > 255) {
				data_aux[i] = 255;
				data_aux[i + 1] = 255;
				data_aux[i + 2] = 255;
			}
		}
	#endif

	return data_aux;
}

unsigned char * inverte_image(unsigned char * data, unsigned int len_img, unsigned int x)
{
	unsigned char * data_aux = cuda_malloc_managed_aux(len_img);
	
	config_params_date_aux(data_aux, data, DEFAULT_HEADER_SIZE + x);
	unsigned int N = DEFAULT_HEADER_SIZE + x;

	printf("Aplicando inverte_image!\n");
	
	#ifdef INSTALL_CUDA

		int block_size = 1024;
		int len_img_pixel = len_img - N;
		int num_blocks = (len_img_pixel + block_size - 1) / block_size;
		cuda_inverte_image<<<num_blocks, block_size >>>(data, data_aux, N, len_img);
		cudaDeviceSynchronize();

	#endif;

	#ifdef INSTALL_CPU
	
	for (unsigned int i = len_img, j = DEFAULT_HEADER_SIZE + x; i > 14; i--, j++)
	{
		data_aux[j] = data[i];
	}

	#endif

	return data_aux;
}

unsigned char * tonalidade_toggle_gray(unsigned char * data, unsigned int len_img, unsigned largura, unsigned int x)
{
	unsigned char * data_aux = cuda_malloc_managed_aux(len_img);

	config_params_date_aux(data_aux, data, len_img);
	unsigned int N = DEFAULT_HEADER_SIZE + x;

	printf("Aplicando tonalidade gray toogle!\n");

	#ifdef INSTALL_CUDA

		int block_size = 1024;
		// int len_img_pixel = ((len_img - N) / 2) / 3;
		int len_img_pixel = (len_img - N) / 3;
		int num_blocks = (len_img_pixel + block_size - 1) / block_size;
		cuda_tonalidade_toogle_gray<<<num_blocks, block_size>>>(data, data_aux, N, len_img, largura);
		cudaDeviceSynchronize();

	#endif

	#ifdef INSTALL_CPU
	bool state_linha = true;
	for (unsigned int i = DEFAULT_HEADER_SIZE + x, k = 0; i < len_img; i += RGB) {
		k = i;
		if (state_linha) {
			data_aux[i] = (int) ((0.299 * data[i]) + (0.587 * data[i + 1]) + (0.144 * data[i + 2])); //calcula o valor para conversão
			data_aux[i + 1] = data_aux[i]; //copia o valor para
			data_aux[i + 2] = data_aux[i];  //todas componentes

	        if (data_aux[i] > 255) {
	            data_aux[i] = 255;
	            data_aux[i + 1] = 255;
	            data_aux[i + 2] = 255;
			}

			if (k > largura * RGB) {
				state_linha = false;
				k = 0;
			}
		}
		else {
			if (k > largura * RGB) {
				state_linha = true;
				k = 0;
			}
		}
	}
	#endif

	return data_aux;
}
