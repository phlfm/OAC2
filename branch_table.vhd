-------------------------------------------------------------------------------
--
-- Title       : branch_table
-- Design      : LEGv8
-- Author      : pliga@globo.com
-- Company     : USP
--
-------------------------------------------------------------------------------
--
-- File        : d:\Active_HDL\LEGv8\src\branch_table.vhd
-- Generated   : Sat Oct 19 18:51:17 2019
-- From        : interface description file
-- By          : Itf2Vhdl ver. 1.22
--
-------------------------------------------------------------------------------
--
-- Description :
--
-------------------------------------------------------------------------------

--{{ Section below this comment is automatically maintained
--   and may be overwritten
--{entity {branch_table} architecture {branch_table}}

library IEEE;
use IEEE.std_logic_1164.all;

entity branch_table is
	 port(
         clock:    in 	bit;
         reset:	  in 	bit;

		 branch_result : in bit;   -- Zero???
		 branch_instruction: in bit; --Controle
		 prediction : out bit
	     );
end branch_table;

--}} End of automatically maintained section

architecture branch_table of branch_table is

	component reg is
        generic(wordSize: natural :=4);
        port(
            clock:    in 	bit; --! entrada de clock
            reset:	  in 	bit; --! clear assíncrono
            load:     in 	bit; --! write enable (carga paralela)
            d:   			in	bit_vector(wordSize-1 downto 0); --! entrada
            q:  			out	bit_vector(wordSize-1 downto 0) --! saida
        );
    end component;


	-- Estados: 00 => Fortemente nao tomar
	--          01 => Fracamente nao tomar
	--          10 => Fracamente tomar
	--          11 => Fortemente tomar
	signal state : bit_vector(1 downto 0) := "01";
	signal next_state : bit_vector(1 downto 0);

	signal test_result : bit_vector(1 downto 0);
	signal Lff, Lfv, Lvf, Lvv : bit_vector(1 downto 0);

begin

	-- Teste 0: Se instrucao eh de desvio
	test_result(0) <= branch_instruction;

	-- Teste 1: Se desvio foi tomado
	test_result(1) <= branch_result;



	-- Lff -> Instru��o n�o � de desvio. Estado se mant�m
	Lff <= state;

	-- Lvf -> Instru��o n�o � de desvio. Estado se mant�m.
	-- A flag de desvio foi para 1, mas em fun��o de outra instru��o, que n�o tem nada a ver com desvio
	Lvf <= state;

	-- Lfv -> Instru��o � de desvio e o desvio N�O foi tomado
	with state
	select Lfv <= 	"00" when "00",
				  	"00" when "01",
	 				"01" when "10",
				  	"10" when "11",
					"00" when others;

	-- Lfv -> Instru��o � de desvio e o desvio FOI tomado
	with state
	select Lvv <=  	"01" when "00",
				  	"10" when "01",
	 				"11" when "10",
				  	"11" when "11",
					"00" when others;

	-- MUX com os Links
	with test_result
	select next_state <=	Lff when "00",
						  	Lfv when "01",
			 				Lvf when "10",
						  	Lvv when "11",
							"01" when others;

	state_reg : reg generic map (2) port map (
		clock => clock,
		reset => reset,
		load => '1',
		d => next_state,
		q => state
	);


	prediction <= state(0);

end branch_table;
