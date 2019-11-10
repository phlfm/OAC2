library IEEE;
use ieee.numeric_bit.all;

entity branch_prediction_table is
generic (
	addrSize	: NATURAL	:= 4;
	tableSize	: NATURAL	:= 4);
port (
    clock : in bit;
	input_addr: in bit_vector(addrSize-1 downto 0);
	return_value : out bit );
end branch_prediction_table;

architecture branch_table of branch_prediction_table is

	signal keysTable : bit_vector(addrSize*tableSize-1 downto 0) := ( others => '0');
	signal valuesTable : bit_vector(tableSize*2-1 downto 0) := ( others => '0');

begin

	tableProc: process(clock) is

		variable valueFromTable : bit;
	begin
		if rising_edge(clock) then

			search_table: for iR in (tableSize-1) downto 0 loop

				if (keysTable(addrSize*(iR+1)-1 downto addrSize*iR) = input_addr) then
					valueFromTable := valuesTable((iR+1)*2-1);
					EXIT search_table;
				else
					valueFromTable := '0';
				end if;

			end loop search_table;

			return_value <= valueFromTable;

		end if; -- rising_edge(clock)
	end process tableProc;
end branch_table;
