-- Funcionamento:

-- Estagio de FETCH:
-- writeEnable = 0, retorna prediction para addrR.
-- (Se a instrucao nao ta na branch_table, retorna 0, tudo continua normal)
-- (prediction eh consultado da tabela que eh escrita/populada no estagio execute)

-- Estagio EXECUTE:
-- Se for instrucao de branch, coloca o end em addrW, writeEnable = 1 e escreve branch_result
-- O modulo vai guardar o addrW numa tabela junto com a maquina de estados de previsao associado a esse addr.

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_bit.all;

entity branch_table is
	generic
	(
		addrSize	: NATURAL	:= 8; -- tamanho do bus de enderecos
		tableSize	: NATURAL	:= 16; -- quantos desvios guardar na tabela
		selectorSize : NATURAL := 4 -- como regra, selectorSize = numero de 1's em (tableSize-1) e tableSize = potencia de 2.
-- selectorSize precisa ser grande o suficiente para acomodar tableSize, exemplo:
-- se tableSize = 8, entao vamos acessar de 0 a (8-1), entao temos de 0 a 7, logo
	-- selectorSize precisa ser 3 para acomodar 000 a 111
-- se tableSize = 16, entao vamos acessar de 0 a (16-1), entao temos de 0 a 15, logo
	-- selectorSize precisa ser 4 para acomodar 0000 a 1111
	);
	 port(
         clock:    in 	bit;
         reset:	  in 	bit;

-- Esses sao usados no FETCH:
		 instruction_addrR: in bit_vector(addrSize-1 downto 0); -- end da inst atual
		 branch_addrR : out bit_vector(addrSize-1 downto 0); -- end para o qual desviar
		 prediction : out bit; -- se deve desviar ou nao

-- Esses sao usados no EXECUTE:
		 branch_instruction: in bit; -- age como um enable de escrita
		 branch_result : in bit; -- resultado do branch para atualizar
		 instruction_addrW: in bit_vector(addrSize-1 downto 0); -- end da inst atual
		 branch_addrW : in bit_vector(addrSize-1 downto 0) -- end para o qual desviar
-- se instruction_addrW nao existir na tabela, ele cria uma nova entrada, se nao, so atualiza.

	     );
end branch_table;


architecture branch_table of branch_table is

	-- Estados: 00 => Fortemente nao tomar
	--          01 => Fracamente nao tomar
	--          10 => Fracamente tomar
	--          11 => Fortemente tomar
	signal state : bit_vector(tableSize*2-1 downto 0) := ( others => '0');
	--signal next_state : bit_vector(tableSize*2-1 downto 0) := ( others => '0');
	signal instruction_addr : bit_vector(addrSize*tableSize-1 downto 0) := ( others => '0');
	signal branch_addr : bit_vector(addrSize*tableSize-1 downto 0) := ( others => '0');

	signal selector : unsigned(selectorSize-1 downto 0) := (others=> '0');

begin

tableProc: process(clock, reset) is
begin
if reset = '1' then
	state <= ( others => '0');
	instruction_addr <= ( others => '0');
	branch_addr <= ( others => '0');
	selector <= ( others => '0');
else -- else do reset
	if rising_edge(clock) then

	end if; -- rising_edge(clock)
end if;	-- else do reset
end process tableProc;


end branch_table;
