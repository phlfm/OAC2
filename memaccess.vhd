
library ieee;
use ieee.numeric_bit.all;

entity MemAccess is

    generic(doubleWord: natural := 64;
            word: natural := 32;
            halfWord: natural := 16);
	port (		
		clock: in bit;
        reset: in bit;
		
        branch: in bit;	    --CONTROL
		MemRead: in bit;	--CONTROL
		MemWrite: in bit;	--CONTROL
        
		Address: in bit_vector(doubleWord-1 downto 0);
		AddResult: in bit_vector(doubleWord-1 downto 0);
		WriteData: in bit_vector(doubleWord-1 downto 0);
        instruction4to0: in bit_vector(4 downto 0);
        zero: in bit;  
	
		AddressOut: out bit_vector(doubleWord-1 downto 0);
		ReadData: out bit_vector(doubleWord-1 downto 0);
		Instruction4to0Out: out bit_vector(4 downto 0);
		PCSrc: out bit;
		BranchAddress: out bit_vector(doubleWord-1 downto 0);
		
		--LÓGICA DA PREVISÃO DE DESVIO 
		branch_prediction_in: in bit;
		prediction_out: out bit
	);
		
end entity MemAccess;

architecture MemAccess of MemAccess is
    
    component ram is
        generic (
            addressSize : natural := 64;
            wordSize    : natural := 32
        );
        port (
            ck, wr : in  bit;
            addr   : in  bit_vector(addressSize-1 downto 0);
            data_i : in  bit_vector(wordSize-1 downto 0);
            data_o : out bit_vector(wordSize-1 downto 0)
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
	
	component alu is
        port (
            A, B : in  signed(63 downto 0); -- inputs
            F    : out signed(63 downto 0); -- output
            S    : in  bit_vector (3 downto 0); -- op selection
            Z    : out bit -- zero flag
        );
    end component; 	
	
	--LÓGICA DA PREVISÃO DE DESVIO
	component branch_table is
	port(	 
         clock:    in 	bit; 
         reset:	  in 	bit; 
		 
		 branch_result : in bit;   -- Zero???
		 branch_instruction: in bit; --Controle
		 prediction : out bit
	     );
	end component;

    signal temp_AddressOut: bit_vector(doubleWord-1 downto 0);
    signal temp_ReadData: bit_vector(doubleWord-1 downto 0);
    signal temp_Instruction4to0Out: bit_vector(4 downto 0);
    signal temp_PCSrc: bit;	

begin

    MEM_ram : ram generic map (doubleWord, doubleWord) port map (
        ck => clock,
        wr => MemWrite,
        addr => Address,
        data_i => WriteData,
        data_o => temp_ReadData
    );

    ReadData_reg : reg generic map (doubleWord) port map (
        clock => clock, 
        reset => reset, 
        load => '1',
        d => temp_ReadData,
        q => ReadData
    );

    Address_reg : reg generic map (doubleWord) port map (
        clock => clock, 
        reset => reset, 
        load => '1',
        d => Address,
        q => AddressOut
    );

    instruction4to0_reg : reg generic map (5) port map (
        clock => clock, 
        reset => reset, 
        load => '1', 
        d => instruction4to0,
        q => Instruction4to0Out
    );
    
    BranchAddress <= AddResult;
    PCSrc <= zero and branch;
	
	--LÓGICA DE PREVISÃO DE DESVIO
	BranchTab: branch_table port map(
		 clock => clock,
         reset => reset, 
		 
		 branch_result => zero,   -- Zero???
		 branch_instruction => branch, --Controle
		 prediction => prediction_out
	);
	
end architecture MemAccess;
