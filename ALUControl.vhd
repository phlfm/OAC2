--

library ieee;
use ieee.numeric_bit.all;

entity ALUControl is
	port (
	 	ULAOp: in bit_vector(1 downto 0);
		instruction31to21: in bit_vector(10 downto 0);
		
		aluCtl: out bit_vector(3 downto 0)
	);
end entity ALUControl;

architecture ALUControl of ALUControl is
	signal arithmetic: bit_vector(3 downto 0) := (others => '0');

begin

	with instruction31to21 select arithmetic <=
		 "0010" when "10001011000", -- ADD
		 "0110" when "11001011000", -- SUB
		 "0000" when "10001010000", -- AND
		 "0001" when "10101010000", -- ORR
		 (others=>'0') when others;

		 
	with ULAOp select aluCtl <=
		 "0010" when "00", -- ADD
		 "0111" when "01", -- PASS B
		  arithmetic when "10", -- ARITHMETIC
		 (others=>'0') when others;
	
end architecture ALUControl;
