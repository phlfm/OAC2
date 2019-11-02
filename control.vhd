--

library ieee;
use ieee.numeric_bit.all;

entity control is
	port (
		clock : in bit;
		reset: in bit;

	    instruction31to21: in bit_vector(10 downto 0);

		AluSrc: out bit;		      		--EX
	    AluOP: out bit_vector(1 downto 0);	--EX

		branch: out bit;					--MEM
		MemRead: out bit;					--MEM
	    MemWrite: out bit; 					--MEM

	    RegWrite: out bit;					--WB
	    MemToReg: out bit					--WB
	);
end entity control;

architecture control of control is
	signal R : bit;
	signal LDUR : bit;
	signal STUR : bit;
	signal CBZ : bit;

	signal temp_AluSrc: 	bit;		      		--EX
	signal temp_AluOP: 		bit_vector(1 downto 0);	--EX
	signal temp_branch: 	bit;					--MEM
	signal temp_MemRead: 	bit;					--MEM
	signal temp_MemWrite: 	bit; 					--MEM
	signal temp_RegWrite: 	bit;					--WB
	signal temp_MemToReg: 	bit;					--WB

	signal DECODE_data:		bit_vector(7 downto 0);
	signal EX_Reg:			bit_vector(7 downto 0);
	signal MEM_Reg:			bit_vector(4 downto 0);
	signal WB_Reg:			bit_vector(1 downto 0);

	component reg is
        generic(wordSize: natural :=4);
        port(
            clock:    in    bit; --! entrada de clock
            reset:    in    bit; --! clear assíncrono
            load:     in    bit; --! write enable (carga paralela)
            d:              in  bit_vector(wordSize-1 downto 0); --! entrada
            q:              out bit_vector(wordSize-1 downto 0) --! saída
        );
    end component;

begin
	-- CBZ  = "10110100XXX" => 10X0001001
	-- STUR = "11111000000" => 11X0010000
	-- LDUR = "11111000010" => X111100000
	-- R    = "1XX0101X000" => 0001000010


	R		<= '1' when instruction31to21(10) = '1' and instruction31to21(7 downto 4) = "0101" and instruction31to21(2 downto 0) = "000" else '0';
	LDUR	<= '1' when instruction31to21 = "11111000010" else '0';
	STUR	<= '1' when instruction31to21 = "11111000000" else '0';
	CBZ	 	<= '1' when instruction31to21(10 downto 3) = "10110100" else '0';


	--reg2loc	<= STUR or CBZ; -- STUR | CBZ

	temp_AluSrc		<= LDUR or STUR; 	-- LDUR | STUR

	temp_MemToReg	<= LDUR; 			-- LDUR
	temp_RegWrite	<= R or LDUR; 		-- R | LDUR

	temp_MemRead	<= LDUR; 			-- LDUR
	temp_MemWrite 	<= STUR; 			-- STUR

	temp_branch		<= CBZ; 			-- CBZ
	--uncondBranch <= '0'; -- ?

	temp_AluOP(1)	<= R; 				-- R
	temp_AluOP(0)	<= CBZ;				-- CBZ




	--REGISTRADORES DO PIPELINE

	DECODE_data <= temp_AluSrc & temp_AluOP & temp_branch & temp_MemRead & temp_MemWrite & temp_RegWrite & temp_MemToReg; -- concat de bits: https://stackoverflow.com/questions/209458/concatenating-bits-in-vhdl

	regEX : reg generic map (8)
	port map(
		clock => clock,
		reset => reset,
		load => '1',
		d => DECODE_data,
		q => EX_Reg
	);

	AluSrc <= EX_Reg(7);
	AluOP <= EX_Reg(6 downto 5);

	regMEM : reg generic map (5)
	port map(
		clock => clock,
		reset => reset,
		load => '1',
		d => EX_Reg(4 downto 0),
		q => MEM_Reg
	);

	branch <= MEM_Reg(4);
	MemRead <= MEM_Reg(3);
	MemWrite <= MEM_Reg(2);

	regWB : reg generic map (2)
	port map(
		clock => clock,
		reset => reset,
		load => '1',
		d => MEM_Reg(1 downto 0),
		q => WB_Reg
	);

	RegWrite <= WB_Reg(1);
	MemToReg <= WB_Reg(0);

end architecture control;
