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

entity branch_table is
	 port(
         clock:    in 	bit;
         reset:	  in 	bit;

-- Esses sao usados no FETCH:
		 instruction_addrR: in bit_vector(11 downto 0); -- end da inst atual
		 branch_addrR : in bit_vector(11 downto 0); -- end para o qual desviar
		 prediction : out bit; -- se deve desviar ou nao

-- Esses sao usados no EXECUTE:
		 branch_instruction: in bit; -- age como um enable de escrita
		 branch_result : in bit; -- resultado do branch para atualizar
		 instruction_addrW: in bit_vector(11 downto 0); -- end da inst atual
		 branch_addrW : in bit_vector(11 downto 0) -- end para o qual desviar
-- se instruction_addrW nao existir na tabela, ele cria uma nova entrada, se nao, so atualiza.

	     );
end branch_table;


architecture branch_table of branch_table is

	-- Estados: 00 => Fortemente nao tomar
	--          01 => Fracamente nao tomar
	--          10 => Fracamente tomar
	--          11 => Fortemente tomar
	signal state : bit_vector(1 downto 0) := "01";
	signal next_state : bit_vector(1 downto 0);

	signal test_result : bit_vector(1 downto 0);
	signal Lff, Lfv, Lvf, Lvv : bit_vector(1 downto 0);

begin


end branch_table;
