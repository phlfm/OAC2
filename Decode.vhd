
library ieee;
use ieee.numeric_bit.all;

entity Decode is

generic(doubleWord: natural := 64;
			  word: natural := 32;
			  halfWord: natural := 16);
	port (
		clock: in bit;
		reset: in bit;
	   
		PC: in bit_vector(doubleword-1 downto 0);
		instruction: in bit_vector(word-1 downto 0);
		RegWriteWB: in bit;
		WriteReg: in bit_vector(4 downto 0);
		WriteData:in bit_vector(doubleword-1 downto 0);

		PCOut: out bit_vector(doubleword-1 downto 0);
		instruction64: out bit_vector(doubleword-1 downto 0);
		OPCode: out bit_vector(10 downto 0);
		instruction4to0: out bit_vector(4 downto 0);
		ReadData1: out bit_vector(doubleword-1 downto 0);
		ReadData2: out bit_vector(doubleword-1 downto 0);  
		
		--LÓGICA DA PREVISÃO DE DESVIO 
		branch_prediction_in: in bit;
		branch_prediction_out: out bit;
		branch_address: out bit_vector(63 downto 0)
	);
		
end entity Decode;

architecture Decode of Decode is

	component mux2to1 is
	  generic(ws: natural := 4); -- word size
	  port(
		  s:      in  bit; -- selection: 0=a, 1=b
		  a, b:   in	bit_vector(ws-1 downto 0); -- inputs
		  o:  	out	bit_vector(ws-1 downto 0)  -- output
	 ); 
    end component;	
	 
	component signExtend is
		generic(
		ws_in:  natural := 32; -- input word size
		ws_out: natural := 64); -- output word size
		port(
		i: in	 bit_vector(ws_in-1  downto 0); -- input
		o: out bit_vector(ws_out-1 downto 0)  -- output
		);
	end component;
	
	component reg_file is
		 generic(wordSize: natural :=64);
		 port(
			  clock : in bit;
			  reset : in bit;
			  read_reg1 : in bit_vector(4 downto 0);
			  read_reg2 : in bit_vector(4 downto 0);
			  write_reg : in bit_vector(4 downto 0);
			  write_data : in bit_vector(wordSize-1 downto 0);
			  read_data1 : out    bit_vector(wordSize-1 downto 0);
			  read_data2 : out    bit_vector(wordSize-1 downto 0)
		 );
	end component;
	
	 component reg is
        generic(wordSize: natural :=4);
        port(
            clock:    in 	bit; --! entrada de clock
            reset:	  in 	bit; --! clear assÃ­ncrono
            load:     in 	bit; --! write enable (carga paralela)
            d:   			in	bit_vector(wordSize-1 downto 0); --! entrada
            q:  			out	bit_vector(wordSize-1 downto 0) --! saÃ­da
        );
    end component;
	
	
	--LÓGICA DA PREVISÃO DE DESVIO -- Calculo do endereço de desvio é passado para o estágio de DECODE
	component alu is
	port (
		A, B : in  signed(63 downto 0); -- inputs
		F    : out signed(63 downto 0); -- output
		S    : in  bit_vector (3 downto 0); -- op selection
		Z    : out bit -- zero flag
		);
	end component;	
	
	component shiftleft2 is
		generic(
			ws: natural := 64); -- word size
		port(
			i: in	 bit_vector(ws-1 downto 0); -- input
			o: out bit_vector(ws-1 downto 0)  -- output
		);
	end component;
	
	
	
	
	signal ReadReg2_In :      bit_vector(4 downto 0);	
	signal read_data1_out:    bit_vector(doubleword-1 downto 0);
	signal read_data2_out:    bit_vector(doubleword-1 downto 0);
	signal s_instruction64:   bit_vector(doubleword-1 downto 0);
	signal s_instruction4to0: bit_vector(4 downto 0);
	signal s_writeReg:        bit_vector(4 downto 0);
	
	signal temp_reg2Loc: bit_vector(0 downto 0);
												  
	signal temp_PC: bit_vector(0 downto 0);		  
													 
	signal temp_PCOut: bit_vector(0 downto 0);
								   
	signal  s_PCSrcOut: 	bit;				  
	signal 	s_reg2Loc:		bit;
	
	signal selectreg:			bit_vector(4 downto 0);	  
	
	--LÓGICA DA PREVISÃO DE DESVIO 
	signal temp_branch_prediction_in: bit_vector (0 downto 0);
	signal temp_branch_prediction_out: bit_vector (0 downto 0);	   
	signal temp_instruction64: bit_vector(doubleword-1 downto 0); 
	signal temp_SLL_out: bit_vector(63 downto 0); 
	signal temp_branch_address: signed(63 downto 0);
		
begin
	
	Decode_Mux : mux2to1 port map(
		s => s_reg2Loc,
		a => Instruction(3 downto 0),
		b => Instruction(3 downto 0), 
		o => ReadReg2_In(3 downto 0)
	);
	
	
	Decode_reg_file : reg_file port map( 
		clock => clock,
		reset => reset,
		read_reg1 => instruction(4 downto 0),
		read_reg2 => ReadReg2_In,
		Write_reg => WriteReg,
		write_data => writeData,
		
		Read_Data1 =>read_data1_out,
		Read_data2 =>read_data2_out
	);
	
	Decode_signExtend : signExtend port map(
		i => instruction,
		o => s_instruction64
	);
	
	
	reg_PC : reg generic map(64) port map(
	 clock => clock, 
        reset => reset, 
        load => '1', 
        d => PC,
        q => PCOut
	);
	
	reg_data1 : reg generic map(64) port map(
	 clock => clock, 
        reset => reset, 
        load => '1', 
        d => read_data1_out,
        q => ReadData1
	);
	
	reg_data2 : reg generic map(64) port map(
	 clock => clock,
        reset => reset, 
        load => '1',
        d => read_data2_out,
        q => ReadData2
	);
	
	reg_instruction4to0 : reg generic map(5) port map(
	 clock => clock,
        reset => reset, 
        load => '1',
        d => instruction(4 downto 0),
        q => instruction4to0
	);			 
	
	reg_instruction64 : reg generic map(64) port map(
	 clock => clock,
        reset => reset, 
        load => '1',
        d => S_instruction64,
        q => temp_instruction64	 --LÓGICA DA PREVISÃO DE DESVIO
	);	
	instruction64 <= temp_instruction64;
	
	reg_OPCode : reg generic map(11) port map(
	 clock => clock,
        reset => reset, 
        load => '1',
        d => instruction(31 downto 21),
        q => OPCode
	);
	
	
	--LÓGICA DA PREVISÃO DE DESVIO
	temp_branch_prediction_in(0) <= branch_prediction_in;
	Branch_Reg : reg generic map (1) port map (
        clock => clock, 
        reset => reset, 
        load => '1', 
        d => temp_branch_prediction_in,
        q => temp_branch_prediction_out
    );	 
	branch_prediction_out <= temp_branch_prediction_out(0);	 
	
	Execute_SLL2: shiftleft2 port map(	   -- O CALCULO DO ENDEREÇO É PASSADO PARA O DECODE
		i => temp_instruction64,
		o => temp_SLL_out
	); 
	
	PC_adder: alu port map(
		A => signed(temp_SLL_out),
		B => signed(PC),
		F => temp_branch_address,
		S => "0010",
		Z => open
	);	   
	
	Branch_ADD_Reg : reg generic map (1) port map (  -- REG PARA O ENDEREÇO DO BRANCH
        clock => clock, 
        reset => reset, 
        load => '1', 
        d => bit_vector(temp_branch_address),
        q => branch_address
    );	 														
	
end architecture Decode;