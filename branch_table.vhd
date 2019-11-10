-- Escola Politecnica da Universidade de Sao Paulo
-- PCS3422 - Organizacao e Arquitetura de Computadores II
-- 2019 - Autor: Pedro H L F de Mendonca

-- Funcionamento:
-- Estagio de FETCH:
	-- writeEnable = 0, retorna prediction para addrR.
	-- (Se a instrucao nao ta na branch_table, retorna 0, tudo continua normal)
	-- (prediction eh consultado da tabela que eh escrita/populada no estagio execute)
-- Estagio EXECUTE:
	-- Se for instrucao de branch, coloca o end em addrW, writeEnable = 1 e escreve branch_result
	-- O modulo vai guardar o addrW numa tabela junto com a maquina de estados de previsao associado a esse addr.

library IEEE;
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
	signal s_state : bit_vector(tableSize*2-1 downto 0) := ( others => '0');
	signal s_instruction_addr : bit_vector(addrSize*tableSize-1 downto 0) := ( others => '0');
	signal s_branch_addr : bit_vector(addrSize*tableSize-1 downto 0) := ( others => '0');

	signal s_instruction_addrR: bit_vector(addrSize-1 downto 0) := (others => '0');
	signal s_read_prediction: bit := '0';
	signal s_read_branchAddr : bit_vector(addrSize-1 downto 0) := ( others => '0');

begin

---------------------------------------------------
------    WRITE    ---------------------------------
---------------------------------------------------
tableWRITE: process(clock, reset) is
	variable v_current_stateW : bit_vector(1 downto 0) := ( others => '0');
	variable v_next_stateW : bit_vector(1 downto 0) := ( others => '0');
	variable v_found_branch_instruction_onWrite : bit := '0';
	variable v_ringBufferCount : integer range 0 to (tableSize-1);

-- as variaveis acima sao settadas na logica dentro do ELSE do if abaixo.
-- depois que as variaveis sao settadas, as saidas da entity sao assinaladas fora do if
begin
if reset = '1' then
-- atribuicao de signals
	s_state <= ( others => '0');
	s_instruction_addr <= ( others => '0');
	s_branch_addr <= ( others => '0');
	s_instruction_addrR <= (others => '0');
-- atribuicao de variaveis
	v_found_branch_instruction_onWrite := '0';
	v_ringBufferCount := 0;

else -- else do reset
	if rising_edge(clock) then
	s_instruction_addrR <= instruction_addrR;
-- TODOS OS INDICES DAQUI P BAIXO DEVEM SER iW (ate a secao de read)
		-- faz write e depois read
		if branch_instruction = '1' then
			v_found_branch_instruction_onWrite := '0';
			-- faz um for procurando o addrW (input) na tabela
			search_instruction_addr_on_write: for iW in (tableSize-1) downto 0 loop
			-- se addr(tabela) = addrW(input), entao atualiza o estado
				if s_instruction_addr(addrSize*(iW+1)-1 downto addrSize*iW) = instruction_addrW then
					v_found_branch_instruction_onWrite := '1';
					v_current_stateW := s_state((iW+1)*2-1 downto (iW+1)*2-2);
				-- atualiza o estado
					if branch_result = '1' then
					-- incrementa o estado
						case v_current_stateW is
							when "00" => v_next_stateW := "01";
							when "01" => v_next_stateW := "10";
							when others => v_next_stateW := "11";
						end case;
					else
					-- decrementa o estado
						case v_current_stateW is
							when "11" => v_next_stateW := "10";
							when "10" => v_next_stateW := "01";
							when others => v_next_stateW := "00";
						end case;
				 	end if; -- if da atualizacao de estado (branch_result)
					-- atualiza o estado de fato:
					s_state((iW+1)*2-1 downto (iW+1)*2-2) <= v_next_stateW;
				EXIT search_instruction_addr_on_write;
				end if; -- if addr(tabela) = addrW(input)
			end loop search_instruction_addr_on_write;
			-- se NAO encontrou a entrada no buffer, criar uma nova:
			if v_found_branch_instruction_onWrite = '0' then
				if branch_result = '1' then
					s_state(v_ringBufferCount*2+1 downto v_ringBufferCount*2) <= "10"; -- Assinala a entrada nova no estado 10
				else
					s_state(v_ringBufferCount*2+1 downto v_ringBufferCount*2) <= "01"; -- Assinala a entrada nova no estado 10
				end if;

				s_instruction_addr((v_ringBufferCount+1)*addrSize-1 downto v_ringBufferCount*addrSize) <= instruction_addrW;
				s_branch_addr((v_ringBufferCount+1)*addrSize-1 downto v_ringBufferCount*addrSize) <= branch_addrW;
				--report "antes: " & integer'image((v_ringBufferCount));
				if v_ringBufferCount = (tableSize-1) then
					v_ringBufferCount := 0;
				else
					v_ringBufferCount := v_ringBufferCount+1;
				end if;
				--report "depois: " & integer'image((v_ringBufferCount));
			end if; -- if v_found_branch_instruction = 0
		end if; -- if branch_instruction (eh o write)
	end if; -- rising_edge(clock)
end if;	-- else do reset
end process tableWRITE;

---------------------------------------------------
------    READ    ---------------------------------
---------------------------------------------------
tableREAD: process(clock, s_state, s_instruction_addr, s_branch_addr) is
begin
if reset = '1' then
	s_read_prediction <= '0';
	s_read_branchAddr <= ( others => '0');
else
	if falling_edge(clock) then
	-- TODOS OS INDICES DAQUI P BAIXO DEVEM SER iR
		-- ja fez write, agora faz read
		-- faz um for procurando o addrW (input) na tabela
		search_instruction_addr_on_read: for iR in (tableSize-1) downto 0 loop
		-- se addr(tabela) = addrW(input), entao atualiza o estado
			--report "iR: " & integer'image(iR);
			if s_instruction_addr(addrSize*(iR+1)-1 downto addrSize*iR) = s_instruction_addrR then
				--report "vReadPrediction: " & integer'image(iR*2+1);
				s_read_prediction <= s_state(iR*2+1);
				s_read_branchAddr <= s_branch_addr(addrSize*(iR+1)-1 downto addrSize*iR);
				EXIT search_instruction_addr_on_read;
			else -- NAO encontrou a entrada no buffer, fazer output da predicao = 0
				--report "vReadPrediction: NO BUFFER";
				s_read_prediction <= '0';
				s_read_branchAddr <= (others => '0');
			end if;  -- if addr(tabela) = addrR(input)
		end loop search_instruction_addr_on_read;
	end if; -- rising_edge(clock)
end if; -- reset

end process tableREAD;

-- Assinalar os sinais da entity (os outputs) DAQUI PRA BAIXO!! \/
	prediction <= s_read_prediction;
	branch_addrR <= s_read_branchAddr;

end branch_table;

-- ULTIMA COMPILACAO:
-- vcom -work work C:/temp/gitLEGv8/branch_table.vhd
-- # Model Technology ModelSim - Intel FPGA Edition vcom 10.5b Compiler 2016.10 Oct  5 2016
-- # Start time: 12:41:16 on Nov 10,2019
-- # vcom -reportprogress 300 -work work C:/temp/gitLEGv8/branch_table.vhd
-- # -- Loading package STANDARD
-- # -- Loading package TEXTIO
-- # -- Loading package NUMERIC_BIT
-- # -- Compiling entity branch_table
-- # -- Compiling architecture branch_table of branch_table
-- # End time: 12:41:16 on Nov 10,2019, Elapsed time: 0:00:00
-- # Errors: 0, Warnings: 0
