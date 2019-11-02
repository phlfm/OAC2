library ieee;
use ieee.numeric_bit.all;

entity Execute is

generic(doubleWord: natural := 64;
			  word: natural := 32;
			  halfWord: natural := 16);
	port (
			clock: in bit;
			reset: in bit;
			
			AluSrc: in bit;						 --CONTROL
			AluCtl: in bit_vector(3 downto 0);	 --CONTROL
														   
			PC: in bit_vector(doubleword-1 downto 0);
			ReadData1: in bit_vector(doubleword-1 downto 0);
			ReadData2: in bit_vector(doubleword-1 downto 0);
			instruction64: in bit_vector(doubleword-1 downto 0);  -- SÓ É USADO NO MUX. O ENDEREÇO JÁ FOI CALCULADO NO DECODE
			OPCode: in bit_vector(10 downto 0);
			instruction4to0: in bit_vector(4 downto 0);
			
			
			AluResult: out bit_vector(doubleword-1 downto 0);
			AddResult: out bit_vector(doubleword-1 downto 0);  -- EQUIVALENTE AO branch_adress, QUE FOI CALCULADO NO DECODE
			Zero: out bit;
			ReadData2Out: out bit_vector(doubleword-1 downto 0);
			Instruction4to0Out: out bit_vector(4 downto 0);
			
			--LÓGICA DA PREVISÃO DE DESVIO 
			branch_prediction_in: in bit;
			branch_prediction_out: out bit;
			
			branch_address: in bit_vector(63 downto 0) --O branch_address continua no pipeline pelo AddResult
	);
		
end entity Execute;


architecture Execute of Execute is

	component alu is
	port (
		A, B : in  signed(63 downto 0); -- inputs
		F    : out signed(63 downto 0); -- output
		S    : in  bit_vector (3 downto 0); -- op selection
		Z    : out bit -- zero flag
		);
	end component;

	component mux2to1 is
		generic(ws: natural := 64); -- word size
		port(
			s:    in  bit; -- selection: 0=a, 1=b
			a, b: in	bit_vector(ws-1 downto 0); -- inputs
			o:  	out	bit_vector(ws-1 downto 0)  -- output
		);
	end component;

	--PODE SER ESQUECIDO, POIS O ENDEREÇO FOI CALCULADO NO DECODE 
--	
--	component shiftleft2 is
--		generic(
--			ws: natural := 64); -- word size
--		port(
--			i: in	 bit_vector(ws-1 downto 0); -- input
--			o: out bit_vector(ws-1 downto 0)  -- output
--		);
--	end component;
	
	
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
	
	
	signal temp_ALU_in : bit_vector(63 downto 0);
    signal temp_SLL_out : bit_vector(63 downto 0);			 
	signal temp_ALU_result_out : signed(63 downto 0);
	signal temp_ADD_result_out : signed(63 downto 0);
	signal temp_ZERO_out : bit;

	 											 
	signal temp_Zero_Reg: bit_vector(0 downto 0);
	signal temp_Zero_RegOut: bit_vector(0 downto 0); 
	
	--LÓGICA DA PREVISÃO DE DESVIO 
	signal temp_branch_prediction_in: bit_vector (0 downto 0);
	signal temp_branch_prediction_out: bit_vector (0 downto 0);

begin

	Execute_Mux: mux2to1 port map(
		s => AluSrc,
        a => ReadData2,
        b => instruction64,
		o => temp_ALU_in
		);
	
	--PODE SER ESQUECIDO, POIS O ENDEREÇO FOI CALCULADO NO DECODE	 
--	
--	Execute_SLL2: shiftleft2 port map(
--		i => instruction64,
--		o => temp_SLL_out
--	);	
	

	Execute_Alu: alu port map(
		A => signed(ReadData1),
		B => signed(temp_ALU_in),
		F => temp_ALU_result_out,
		S => AluCtl,
		Z => temp_ZERO_out
	);
	
	--PODE SER ESQUECIDO, POIS O ENDEREÇO FOI CALCULADO NO DECODE
--	
--	PC_adder: alu port map(
--		A => signed(temp_SLL_out),
--		B => signed(PC),
--		F => temp_ADD_result_out,
--		S => "0010",
--		Z => open
--	);
	

	AluResult_Reg : reg generic map(64) port map (
        clock => clock,
        reset => reset,
        load => '1',
        d => bit_vector(temp_ALU_result_out),
        q => AluResult
	);
	
	--PODE SER ESQUECIDO, POIS O ENDEREÇO FOI CALCULADO NO DECODE. AddResult é o branch_address
--	
--	AddResult_Reg : reg generic map(64) port map (
--        clock => clock,
--        reset => reset,
--        load => '1',
--        d => bit_vector(temp_ADD_result_out),
--        q => AddResult
--	); 
	
	
	temp_Zero_Reg(0) <= temp_ZERO_out;
	Zero_Reg : reg generic map(1) port map (
        clock => clock,
        reset => reset,
        load => '1',
        d => temp_Zero_Reg,
        q => temp_Zero_RegOut
	);	
	Zero <= temp_Zero_RegOut(0);

	ReadData2Out_Reg : reg generic map(64) port map (
        clock => clock, 
        reset => reset, 
        load => '1',
        d => ReadData2,
        q => ReadData2Out
	);

	Instruction4to0_Reg : reg generic map(5) port map (
        clock => clock,
        reset => reset,
        load => '1',
        d => Instruction4to0,
        q => Instruction4to0Out
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
	
	Branch_Address_Reg : reg generic map (1) port map (
        clock => clock, 
        reset => reset, 
        load => '1', 
        d => branch_address,
        q => AddResult
    );							  
	
end architecture Execute;
