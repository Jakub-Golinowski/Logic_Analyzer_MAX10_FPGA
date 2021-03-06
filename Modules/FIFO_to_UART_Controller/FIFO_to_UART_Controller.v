module FIFO_to_UART_Controller(
	rst,
	clk,
	FIFO_wrfull,
	FIFO_rdempty,
	UART_txempty,
<<<<<<< HEAD
	UART_rxempty,
	
	UART_rx_data,
	
	rxclk,
=======
	UART_rxdata,
	UART_rxempty,
>>>>>>> WPAM
	
	FIFO_rdreq,
	UART_rst,
	UART_uld_rx_data,
	UART_tx_enable,
	UART_rx_enable,
	
	
	triggerBlock_Syncrst,
	triggerBlock_Mask,
	
	Bit_Padder_Sel,
	
	state_debug,
<<<<<<< HEAD
	UART_ld_tx_data
=======
	UART_rx_enable,
	UART_uld_rx_data,
	debug_pin,
>>>>>>> WPAM
);
//Opis wejść/wyjść
input wire rst;
input wire clk;			//Clock of the system
input wire FIFO_wrfull;		//write-full flag from FIFO
input wire FIFO_rdempty;		//read-empty flag.
input wire UART_txempty;		//TxD-empty flag. Set when UART 8-bit data buffer is empty
<<<<<<< HEAD
input wire UART_rxempty;
input wire  [7:0]UART_rx_data;
input wire rxclk;
=======
input wire [7:0]UART_rxdata;
input wire UART_rxempty;
>>>>>>> WPAM

output reg FIFO_rdreq;
output reg UART_rst;
output reg UART_tx_enable;	//enables tx_tansmission.
output reg UART_rx_enable;
output reg UART_ld_tx_data;
output reg UART_uld_rx_data;

output reg triggerBlock_Syncrst;	//Triger Block has to be rst after each full read from FIFO
<<<<<<< HEAD
output reg [2:0]triggerBlock_Mask;		//Masks which inputs trigger the TriggerBlock
=======
output reg [2:0]triggerBlock_Mask = 3'b111;			//Masks which inputs trigger the TriggerBlock
>>>>>>> WPAM

output reg [1:0] Bit_Padder_Sel; //Used to select what type of data is pushed into UART
											// 00 => Pipe (pads 3 bit sream with 5 zero bits)
											// 01 => 0x0A (new line ASCII symbol)
											// 10 => Pipe
											// 11 => Pipe  
											
output wire [4:0] state_debug;
output reg UART_rx_enable = 1'b1;
output reg UART_uld_rx_data;
output wire debug_pin;

//Lokalne stałe
localparam [4:0] INITIAL				= 5'b00000;
localparam [4:0] IDLE 					= 5'b01101;
localparam [4:0] SET_READ_REQUEST 		= 5'b00010;
localparam [4:0] WAIT_TX_EMPTY 			= 5'b00011;
localparam [4:0] LOAD_DATA_TO_UART 		= 5'b00100;
localparam [4:0] FINALIZE_DATA_CYCLE 	= 5'b00101;
localparam [4:0] SEND_NEW_LINE_CHAR 	= 5'b00110;
localparam [4:0] WAIT_FOR_NEW_LINE_CHAR_SEND 	= 5'b00111;

//Lokalne zmienne
reg counter;	
reg [4:0] state;
reg [4:0] next_state;

assign state_debug = state;
	
//Przypisanie nowego stanu co takt zegara
always @ (posedge clk)	begin
		if(rst)
			state <= INITIAL;
		else
			state <= next_state;				
end

	
//Logika obliczania następnego stanu
always @ * begin
//	UART_rx_enable = 1'b1;
	FIFO_rdreq = 1'b0;
	UART_ld_tx_data= 1'b0;
	UART_rst = 1'b0;
	UART_tx_enable = 1'b1;
	triggerBlock_Syncrst = 1'b1; // Trigger is disabled by default, except for the IDLE state
	Bit_Padder_Sel = 2'b00;
	triggerBlock_Mask = 3'b111;	
	
	
	case(state)
	INITIAL:	begin
					triggerBlock_Syncrst = 1;
					UART_rst = 1;	
					next_state = IDLE;
				end
	IDLE:	begin 
				triggerBlock_Syncrst = 1'b0;     // Enable trigger so the FIFO can fill up
				if(FIFO_wrfull)
					next_state = SET_READ_REQUEST;
				else
					next_state = state;
			end
	
	SET_READ_REQUEST:	begin
								FIFO_rdreq = 1'b1;
								next_state = WAIT_TX_EMPTY;
							end
	WAIT_TX_EMPTY:	begin
							if(UART_txempty)
								next_state = LOAD_DATA_TO_UART;
							else
								next_state = state;
						end
	LOAD_DATA_TO_UART:	begin
									UART_ld_tx_data = 1'b1;	
									if(UART_txempty)
										next_state = state;
									else
										next_state = FINALIZE_DATA_CYCLE;										
								end
	FINALIZE_DATA_CYCLE: begin
                          UART_ld_tx_data = 1'b0;
                          if(FIFO_rdempty) //FIFO is empty go back to IDLE when transmission is over
                            begin
                              if(UART_txempty) begin
                                next_state = SEND_NEW_LINE_CHAR;
                                end
                              else
                                next_state = state;
                            end
                          else
                            begin
                              if(UART_txempty)
                                next_state = SET_READ_REQUEST;
                              else
                                next_state = state;
                            end
                      	end
  SEND_NEW_LINE_CHAR: begin
                        Bit_Padder_Sel = 2'b01;
                        UART_ld_tx_data = 1'b1;	
                        if(UART_txempty) begin
                          next_state = state;
                        end
                        else begin
                          UART_ld_tx_data = 1'b0;	
                          next_state = WAIT_FOR_NEW_LINE_CHAR_SEND;
                        end
                      end
  WAIT_FOR_NEW_LINE_CHAR_SEND: begin
    															Bit_Padder_Sel = 2'b01;
                                  if(UART_txempty)
                                    next_state = IDLE;
                                  else
                                    next_state = state;
  														 end
	default: next_state = state; // stay in current state - when hung it means reached default.
endcase
end

<<<<<<< HEAD
//always @( posedge rxclk ) begin
//	if( UART_rxempty ) 
//		begin
//		UART_uld_rx_data = 1'b0;
//		end
//	else 
//		begin
//		UART_uld_rx_data = 1'b1;
//		end
//		
//end
//
//always @( UART_rx_data[7:0]) begin
//	triggerBlock_Mask = UART_rx_data[2:0];
//end
	
=======
//always @*
//begin
//	if(!UART_rxempty) begin
//		UART_uld_rx_data <= 1'b1;
//	end else begin
//		UART_uld_rx_data <= 1'b0;
//	end
//	
//end
>>>>>>> WPAM


  
////Logika wyjść
//always @ (state)
//begin
////Domyślne wartości
//FIFO_rdreq = 1'b0;
//UART_ld_tx_data= 1'b0;
//UART_rst = 1'b0;
//UART_tx_enable = 1'b1;
//triggerBlock_Syncrst = 1'b0;
//Bit_Padder_Sel = 2'b00;
//	case(state)
//		INITIAL: begin
//						triggerBlock_Syncrst = 1;
//						UART_rst = 1;
//					end
//		IDLE:	 ;//nothing
//		SET_READ_REQUEST: FIFO_rdreq = 1'b1;
//		WAIT_TX_EMPTY: ;//nothing
//		LOAD_DATA_TO_UART:	UART_ld_tx_data = 1'b1;
//		FINALIZE_DATA_CYCLE: begin
//										UART_ld_tx_data = 1'b0;
//										triggerBlock_Syncrst = 1'b1;
//										Bit_Padder_Sel = 2'b01;
//									end
//		default: ;//stay in default state
//	endcase
//end
  
endmodule
