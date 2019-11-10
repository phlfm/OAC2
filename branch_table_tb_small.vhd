-- Escola Politecnica da Universidade de Sao Paulo
-- PCS3422 - Organizacao e Arquitetura de Computadores II
-- 2019 - Autor: Pedro H L F de Mendonca

library IEEE;
use ieee.numeric_bit.all;

entity branch_table_tb is
	generic
	(
		addrSize	: NATURAL	:= 4; -- tamanho do bus de enderecos
		tableSize	: NATURAL	:= 4; -- quantos desvios guardar na tabela
        CLOCK_PERIOD: time := 5 ns
	);
  port(
       branch_addrR : out bit_vector(addrSize-1 downto 0); -- end para o qual desviar
       prediction : out bit; -- se deve desviar ou nao

       test_number: out integer; -- Test number
       test_end : out bit
  );
end branch_table_tb;

architecture tb of branch_table_tb is

component branch_table_stimuli is
	generic
	(
		addrSize	: NATURAL	:= 16; -- tamanho do bus de enderecos
		tableSize	: NATURAL	:= 16 -- quantos desvios guardar na tabela
	);
	 port(
         clock:    out 	bit;
         reset:	  out 	bit;

-- Esses sao usados no FETCH:
		 instruction_addrR: out bit_vector(addrSize-1 downto 0); -- end da inst atual

-- Esses sao usados no EXECUTE:
		 branch_instruction: out bit; -- age como um enable de escrita
		 branch_result : out bit; -- resultado do branch para atualizar
		 instruction_addrW: out bit_vector(addrSize-1 downto 0); -- end da inst atual
		 branch_addrW : out bit_vector(addrSize-1 downto 0); -- end para o qual desviar
-- se instruction_addrW nao existir na tabela, ele cria uma nova entrada, se nao, so atualiza.

     -- Test informations
		test_number: out integer; -- Test number
		test_end : out bit
	     );
end component;

component branch_table is
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
end component;


signal s_clock : bit;
signal s_reset : bit;
signal s_instruction_addrR : bit_vector(addrSize-1 downto 0);
signal s_branch_instruction : bit;
signal s_branch_result : bit;
signal s_instruction_addrW : bit_vector(addrSize-1 downto 0);
signal s_branch_addrW : bit_vector(addrSize-1 downto 0);

begin

    stimuli : branch_table_stimuli generic map (addrSize => addrSize, tableSize => tableSize)
    	 port map (clock => s_clock, reset => s_reset,
        instruction_addrR => s_instruction_addrR,
        branch_instruction => s_branch_instruction,
        branch_result  => s_branch_result,
        instruction_addrW => s_instruction_addrW,
        branch_addrW  => s_branch_addrW,
        test_number => test_number,
        test_end  => test_end);

    DUT : branch_table generic map (addrSize => addrSize, tableSize => tableSize)
    	 port map (clock => s_clock, reset => s_reset,
        instruction_addrR => s_instruction_addrR,
        branch_addrR  => branch_addrR,
        prediction  => prediction,
        branch_instruction => s_branch_instruction,
        branch_result  => s_branch_result,
        instruction_addrW => s_instruction_addrW,
        branch_addrW  => s_branch_addrW);
end tb;
