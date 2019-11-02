
library ieee;
use ieee.numeric_bit.all;

entity Fetch is
	generic (
        doubleWord: natural := 64;
        word: natural := 32;
        halfWord: natural := 16
    );
	port (
		clock: in bit;
        reset: in bit;	
        
		PCSrc: in bit;
		BranchAddress: in bit_vector(doubleword-1 downto 0);
		
		PCout: out bit_vector(doubleword-1 downto 0);
		instruction: out bit_vector(word-1 downto 0);
		
		
		--LÓGICA DA PREVISÃO DE DESVIO 
		branch_prediction_in: in bit;
		branch_prediction_out: out bit
	);
		
end entity Fetch;

architecture Fetch of Fetch is

	component rom is
    generic (
        addressSize: natural := 64;
        wordSize: natural := 32;
        mifFileName: string  := "rom.dat"
    );
    port (
        addr: in  bit_vector(addressSize-1 downto 0);
        data: out bit_vector(wordSize-1 downto 0)
    );
	end component;

    component mux2to1 is
    generic(ws: natural := 4); -- word size
    port(
        s:      in  bit; -- selection: 0=a, 1=b
        a, b:   in	bit_vector(ws-1 downto 0); -- inputs
        o:  	out	bit_vector(ws-1 downto 0)  -- output
    ); 
    end component;	

    component alu is
        port (
            A, B : in  signed(63 downto 0); -- inputs
            F    : out signed(63 downto 0); -- output
            S    : in  bit_vector (3 downto 0); -- op selection
            Z    : out bit -- zero flag
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

    signal temp_PC_in : bit_vector(63 downto 0);
    signal temp_PC_out : bit_vector(63 downto 0);
    signal adder_result : signed(63 downto 0);
    signal temp_instruction : bit_vector(31 downto 0);

    signal four : signed(63 downto 0) := "0000000000000000000000000000000000000000000000000000000000000100";
	
	--LÓGICA DA PREVISÃO DE DESVIO 
	signal temp_branch_prediction_in: bit_vector (0 downto 0);
	signal temp_branch_prediction_out: bit_vector (0 downto 0);
	
begin

    Fetch_mux : mux2to1 generic map (doubleWord) port map (
        s => PCSrc,
        a => bit_vector(adder_result),
        b => BranchAddress,
        o => temp_PC_in
    );

    Fetch_PC : reg generic map (doubleWord) port map (
        clock => clock, 
        reset => reset, 
        load => '1',
        d => temp_PC_in,
        q => temp_PC_out
    );

    Fetch_adder : alu port map (
        A => signed(temp_PC_Out),
        B => four,
        F => adder_result,
        S => "0010",
        Z => open
    );

    Fetch_rom : rom port map (
        addr => temp_PC_out,
        data => temp_instruction
    );

    Instruction_Reg : reg generic map (word) port map (
        clock => clock,
        reset => reset, 
        load => '1',
        d => temp_instruction,
        q => instruction
    );

    PC_Reg : reg generic map (doubleWord) port map (
        clock => clock, 
        reset => reset, 
        load => '1', 
        d => temp_PC_out,
        q => PCout
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
	
end architecture Fetch;	
