#define IN_ADDR (0x86)          //Endpoint 6 (FPGA2USB Endpoint)
#define OUT_ADDR (0x02)         //Endpoint 2 (USB2FPGA Endpoint)

void initialize_io_interface(unsigned char *input_buffer);
void send_data(unsigned char *output_buffer, unsigned int size_in_bytes);
int receive_data(unsigned char *input_buffer, unsigned int size_in_bytes);
int receive_packet(unsigned char *input_buffer);
void close_io_interface(void);

