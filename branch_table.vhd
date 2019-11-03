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
		tableSize	: NATURAL	:= 16 -- quantos desvios guardar na tabela
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
	signal instruction_addr : bit_vector(addrSize*tableSize-1 downto 0) := ( others => '0');
	signal branch_addr : bit_vector(addrSize*tableSize-1 downto 0) := ( others => '0');

begin

tableProc: process(clock, reset) is
	variable current_stateW : bit_vector(1 downto 0) := ( others => '0');
	variable next_stateW : bit_vector(1 downto 0) := ( others => '0');
	variable read_prediction: bit := '0';
	variable read_branchAddr : bit_vector(addrSize-1 downto 0) := ( others => '0');

-- as variaveis acima sao settadas na logica dentro do ELSE do if abaixo.
-- depois que as variaveis sao settadas, as saidas da entity sao assinaladas fora do if
begin
if reset = '1' then
-- atribuicao de signals
	state <= ( others => '0');
	instruction_addr <= ( others => '0');
	branch_addr <= ( others => '0');
-- atribuicao de variaveis
	read_prediction := '0';
	read_branchAddr := (others => '0');

else -- else do reset
	if rising_edge(clock) then
---------------------------------------------------
------    WRITE    ---------------------------------
---------------------------------------------------
-- TODOS OS INDICES DAQUI P BAIXO DEVEM SER iW (ate a secao de read)
		-- faz write e depois read
		if branch_instruction = '1' then
			-- faz um for procurando o addrW (input) na tabela
			search_instruction_addr_on_write: for iW in (tableSize-1) to 0 loop
			-- se addr(tabela) = addrW(input), entao atualiza o estado
				if instruction_addr(addrSize*(iW+1)-1 downto addrSize*iW) = instruction_addrW then
					current_stateW := state((iW+1)*2-1 downto (iW+1)*2-2);
				-- atualiza o estado
					if branch_result = '1' then
					-- incrementa o estado
						case current_stateW is
							when "00" => next_stateW := "01";
							when "01" => next_stateW := "10";
							when others => next_stateW := "11";
						end case;
					else
					-- decrementa o estado
						case current_stateW is
							when "11" => next_stateW := "10";
							when "10" => next_stateW := "01";
							when others => next_stateW := "00";
						end case;
				 	end if; -- if da atualizacao de estado (branch_result)
					-- atualiza o estado de fato:
					state((iW+1)*2-1 downto (iW+1)*2-2) <= next_stateW;
				else -- NAO encontrou a entrada no buffer, criar uma nova:
					-- TODO: criar nova entrada
				end if; -- if addr(tabela) = addrW(input)
			end loop search_instruction_addr_on_write;
		end if; -- if branch_instruction (eh o write)
---------------------------------------------------
------    READ    ---------------------------------
---------------------------------------------------
-- TODOS OS INDICES DAQUI P BAIXO DEVEM SER iR
		-- ja fez write, agora faz read
		-- faz um for procurando o addrW (input) na tabela
		search_instruction_addr_on_read: for iR in (tableSize-1) to 0 loop
		-- se addr(tabela) = addrW(input), entao atualiza o estado
			if instruction_addr(addrSize*(iR+1)-1 downto addrSize*iR) = instruction_addrR then
				current_stateW := state((iR+1)*2-1 downto (iR+1)*2-2);
				read_prediction := current_stateW(1);
				read_branchAddr := branch_addr(addrSize*(iR+1)-1 downto addrSize*iR);
				EXIT;
			else -- NAO encontrou a entrada no buffer, fazer output da predicao = 0
				read_prediction := '0';
				read_branchAddr := (others => '0');
			end if;  -- if addr(tabela) = addrR(input)
		end loop search_instruction_addr_on_read;
	end if; -- rising_edge(clock)
end if;	-- else do reset

-- Assinalar os sinais da entity (os outputs) DAQUI PRA BAIXO!! \/
	branch_addrR <= read_branchAddr;
	prediction <= read_prediction;
end process tableProc;


end branch_table;

-- ULTIMA COMPILACAO: MODELSIM 2019-11-03 20:49
-- vcom -reportprogress 300 -work work C:/temp/gitLEGv8/branch_table.vhd
-- # Model Technology ModelSim - Intel FPGA Edition vcom 10.5b Compiler 2016.10 Oct  5 2016
-- # Start time: 20:49:34 on Nov 03,2019
-- # vcom -reportprogress 300 -work work C:/temp/gitLEGv8/branch_table.vhd
-- # -- Loading package STANDARD
-- # -- Loading package TEXTIO
-- # -- Loading package std_logic_1164
-- # -- Loading package NUMERIC_BIT
-- # -- Compiling entity branch_table
-- # -- Compiling architecture branch_table of branch_table
-- # End time: 20:49:34 on Nov 03,2019, Elapsed time: 0:00:00
-- # Errors: 0, Warnings: 0
