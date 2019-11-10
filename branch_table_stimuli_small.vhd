-- Escola Politecnica da Universidade de Sao Paulo
-- PCS3422 - Organizacao e Arquitetura de Computadores II
-- 2019 - Autor: Pedro H L F de Mendonca

library IEEE;
use ieee.numeric_bit.all;

entity branch_table_stimuli is
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
end branch_table_stimuli;

architecture stimuli of branch_table_stimuli is
    signal internal_test : integer := 0;

    component clock_generator is
         generic (CLOCK_PERIOD: time := 5 ns);
        port (
            clk: out  bit
        );
         end component;

begin -- begin architecture
    test_number <= internal_test;

     clocker: clock_generator generic map (CLOCK_PERIOD => 5 ns) port map (clk => clock);

generate_stimuli : process

procedure wait_test (waittime: in time) is begin internal_test <= internal_test + 1; wait for waittime; end procedure wait_test;
-- funcao que converte natural para bit_vector(tamanho-1 downto 0)
    function converte (NUMERO, TAMANHO: NATURAL) return bit_vector is
      variable RESULT: bit_vector(TAMANHO-1 downto 0);
      variable I_VAL: NATURAL := NUMERO;
    begin -- begin function
      for I in 0 to RESULT'LEFT loop
        if (I_VAL mod 2) = 0 then
          RESULT(I) := '0';
        else
          RESULT(I) := '1';
        end if;
        I_VAL := I_VAL/2;
      end loop;
      if not(I_VAL =0) then
            report "converte: vector truncated"
            severity WARNING;
      end if;
      return RESULT;
    end converte;

begin -- process
    test_end <= '0';

    -- Test 1 - ver como se comporta em estado desconhecido
    wait_test(5*5 ns);

    -- Test 2 - colocar em estado conhecido
    reset              <= '1';
    instruction_addrR  <= (others => '0'); -- FETCH - end da inst atual
    branch_instruction <= '0'; -- EXECUTE:  age como um enable de escrita
    branch_result      <= '0'; -- EXECUTE: resultado do branch para atualizar
    instruction_addrW  <= (others => '0'); -- EXECUTE: end da inst atual
    branch_addrW       <= (others => '0'); -- end EXECUTE: para o qual desviar
    wait_test(2*5 ns);

    -- Test 3 - ver como se comporta em estado conhecido tudo zero
	-- E da um offset nos valores para estarem estaveis na borda de clock
    reset <= '0';
    wait_test(27.5 ns);

-- No teste SMALL a gente usa addrSize = 4 e tableSize = 4
-- ou seja, da pra guardar 4 branches e enderecos de 0 a 15

    -- Test 4 - ler o endereco 6, escrever no endereco 14
		instruction_addrR  <= 4D"6";
		instruction_addrW  <= 4D"14";
		branch_instruction <= '1';
		branch_result  	   <= '1';
		branch_addrW  	   <= 4D"6";
        wait_test(5 ns);
-- Estado da tabela:
-- 14->6 (10)

    -- Test 5 - ler o endereco 14, escrever no endereco 7
		instruction_addrR  <= 4D"14";
		instruction_addrW  <= 4D"7";
		branch_instruction <= '1';
		branch_result  	   <= '0';
		branch_addrW  	   <= 4D"13";
        wait_test(5 ns);
-- Estado da tabela:
-- 14->06 (10)
-- 07->13 (01)

    -- Test 6 - ler o endereco 14, atualizar o endereco 14
		instruction_addrR  <= 4D"14";
		instruction_addrW  <= 4D"14";
		branch_instruction <= '1';
		branch_result  	   <= '1';
		branch_addrW  	   <= 4D"13"; -- tentamos escrever 13, NADA deve acontecer pq 14 ja existe na tabela apontando pra 6.
        wait_test(5 ns);
-- Estado da tabela:
-- 14->06 (11)
-- 07->13 (01)

    -- Test 7 - ler o endereco 7, atualizar o endereco 7
		instruction_addrR  <= 4D"7";
		instruction_addrW  <= 4D"7";
		branch_instruction <= '1';
		branch_result  	   <= '0';
		branch_addrW  	   <= 4D"13"; -- tentamos escrever 13, NADA deve acontecer pq 7 ja existe na tabela apontando pra 13.
        wait_test(5 ns);
-- Estado da tabela:
-- 14->06 (11)
-- 07->13 (00)

    -- Test 8 - ler o endereco 7, atualizar o endereco 14
		instruction_addrR  <= 4D"7";
		instruction_addrW  <= 4D"14";
		branch_instruction <= '1';
		branch_result  	   <= '0';
		branch_addrW  	   <= 4D"13"; -- tentamos escrever 13, NADA deve acontecer pq 14 ja existe na tabela apontando pra 13.
        wait_test(5 ns);
-- Estado da tabela:
-- 14->06 (10)
-- 07->13 (00)

    -- Test 9 - ler o endereco 14, atualizar o endereco 14
		instruction_addrR  <= 4D"14";
		instruction_addrW  <= 4D"14";
		branch_instruction <= '1';
		branch_result  	   <= '0';
		branch_addrW  	   <= 4D"13"; -- tentamos escrever 13, NADA deve acontecer pq 14 ja existe na tabela apontando pra 13.
        wait_test(5 ns);
-- Estado da tabela:
-- 14->06 (01)
-- 07->13 (00)

    -- Test 10 - ler o endereco 14, atualizar o endereco 14
		instruction_addrR  <= 4D"14";
		instruction_addrW  <= 4D"14";
		branch_instruction <= '1';
		branch_result  	   <= '0';
		branch_addrW  	   <= 4D"13"; -- tentamos escrever 13, NADA deve acontecer pq 14 ja existe na tabela apontando pra 13.
        wait_test(5 ns);
-- Estado da tabela:
-- 14->06 (00)
-- 07->13 (00)

    -- Test 11 - ler o endereco 7, atualizar o endereco 7
		instruction_addrR  <= 4D"7";
		instruction_addrW  <= 4D"7";
		branch_instruction <= '1';
		branch_result  	   <= '1';
		branch_addrW  	   <= 4D"13"; -- tentamos escrever 13, NADA deve acontecer pq 7 ja existe na tabela apontando pra 13.
        wait_test(5 ns);
-- Estado da tabela:
-- 14->06 (00)
-- 07->13 (01)

    -- Test 12 - ler o endereco 7, atualizar o endereco 7
		instruction_addrR  <= 4D"7";
		instruction_addrW  <= 4D"7";
		branch_instruction <= '1';
		branch_result  	   <= '1';
		branch_addrW  	   <= 4D"13"; -- tentamos escrever 13, NADA deve acontecer pq 7 ja existe na tabela apontando pra 13.
        wait_test(5 ns);
-- Estado da tabela:
-- 14->06 (00)
-- 07->13 (10)

    -- Test 13 - ler o endereco 7, atualizar o endereco 7
		instruction_addrR  <= 4D"7";
		instruction_addrW  <= 4D"7";
		branch_instruction <= '1';
		branch_result  	   <= '1';
		branch_addrW  	   <= 4D"13"; -- tentamos escrever 13, NADA deve acontecer pq 7 ja existe na tabela apontando pra 13.
        wait_test(5 ns);
-- Estado da tabela:
-- 14->06 (00)
-- 07->13 (11)

    -- Test 14 - ler o endereco 14 e NAO inserir o 9
		instruction_addrR  <= 4D"14";
		instruction_addrW  <= 4D"9";
		branch_instruction <= '0';
		branch_result  	   <= '1'; -- mesmo aqui estando 1, nao devia mexer em nada
		branch_addrW  	   <= 4D"10"; -- mesmo com 10 aqui, nada devia acontecer
        wait_test(5 ns);
-- Estado da tabela:
-- 14->06 (00)
-- 07->13 (11)

    -- Test 15 - ler o endereco 9, inserir nova entrada em 9
		instruction_addrR  <= 4D"9";
		instruction_addrW  <= 4D"9";
		branch_instruction <= '1';
		branch_result  	   <= '1';
		branch_addrW  	   <= 4D"10";
        wait_test(5 ns);
-- Estado da tabela:
-- 14->06 (00)
-- 07->13 (01)
-- 09->10 (10)

    -- Test 16 - ler o endereco 9, inserir nova entrada em 10
		instruction_addrR  <= 4D"9";
		instruction_addrW  <= 4D"10";
		branch_instruction <= '1';
		branch_result  	   <= '0';
		branch_addrW  	   <= 4D"10";
        wait_test(5 ns);
-- Estado da tabela:
-- 14->06 (00)
-- 07->13 (01)
-- 09->10 (10)
-- 10->10 (01)

    -- Test 17 - A tabela esta cheia, vamos tentar inserir nova entrada enquanto lemos a 2a entrada (07)
		instruction_addrR  <= 4D"07";
		instruction_addrW  <= 4D"06";
		branch_instruction <= '1';
		branch_result  	   <= '0';
		branch_addrW  	   <= 4D"11";
        wait_test(5 ns);
-- Estado da tabela:
-- 14->06 (00) --> substituido: 06->11 (01)
-- 07->13 (01)
-- 09->10 (10)
-- 10->10 (01)

    -- Test 18 - A tabela esta cheia, vamos tentar inserir nova entrada enquanto lemos a 2a entrada (07), que vai cair fora
		instruction_addrR  <= 4D"07";
		instruction_addrW  <= 4D"14"; -- devia ter caido fora da tabela
		branch_instruction <= '1';
		branch_result  	   <= '1';
		branch_addrW  	   <= 4D"15";
        wait_test(5 ns);
-- Estado da tabela:
-- 14->06 (00) --> substituido: 06->11 (01)
-- 07->13 (01) --> substituido: 14->15 (10)
-- 09->10 (10)
-- 10->10 (01)

    -- Test 19 - A tabela esta cheia, vamos tentar inserir nova entrada enquanto lemos a 2a entrada (14)
		instruction_addrR  <= 4D"14";
		instruction_addrW  <= 4D"08";
		branch_instruction <= '1';
		branch_result  	   <= '0';
		branch_addrW  	   <= 4D"15";
        wait_test(5 ns);
-- Estado da tabela:
-- 14->06 (00) --> substituido: 06->11 (01)
-- 07->13 (01) --> substituido: 14->15 (10)
-- 09->10 (10) --> substituido: 08->15 (01)
-- 10->10 (01)

    -- Test 20 - A tabela esta cheia, vamos tentar inserir nova entrada enquanto lemos um read after write
		instruction_addrR  <= 4D"07";
		instruction_addrW  <= 4D"07";
		branch_instruction <= '1';
		branch_result  	   <= '1';
		branch_addrW  	   <= 4D"01";
        wait_test(5 ns);
-- Estado da tabela:
-- 14->06 (00) --> substituido: 06->11 (01)
-- 07->13 (01) --> substituido: 14->15 (10)
-- 09->10 (10) --> substituido: 08->15 (01)
-- 10->10 (01) --> substituido: 07->01 (10)

    -- Test 21 - A tabela esta cheia, vamos tentar inserir nova entrada enquanto lemos um read after write que caiu fora da tabela
		instruction_addrR  <= 4D"06";
		instruction_addrW  <= 4D"05";
		branch_instruction <= '1';
		branch_result  	   <= '1';
		branch_addrW  	   <= 4D"02";
        wait_test(7.5 ns);
-- Estado da tabela:
-- 14->06 (00) --> substituido: 05->02 (10)
-- 07->13 (01) --> substituido: 14->15 (10)
-- 09->10 (10) --> substituido: 08->15 (01)
-- 10->10 (01) --> substituido: 07->01 (10)

	-- Test 22 - dar um reset e ver se tudo continua funcionando
    reset <= '1';
    wait_test(10 ns);

    -- Test 23 - ler o endereco 7, inserir end 8
		reset <= '0';
		instruction_addrR  <= 4D"7";
		instruction_addrW  <= 4D"8";
		branch_instruction <= '1';
		branch_result  	   <= '0';
		branch_addrW  	   <= 4D"13";
        wait_test(5 ns);
-- Estado da tabela:
-- 08->13 (01)

    -- Test 24 - ler o endereco 8 e NAO inserir o 9
		instruction_addrR  <= 4D"8";
		instruction_addrW  <= 4D"9";
		branch_instruction <= '0';
		branch_result  	   <= '1'; -- mesmo aqui estando 1, nao devia mexer em nada
		branch_addrW  	   <= 4D"10"; -- mesmo com 10 aqui, nada devia acontecer
        wait_test(5 ns);
-- Estado da tabela:
-- 08->13 (01)



-- test end
    test_end <= '1';
    wait for 5000 ns;
end process;

end stimuli;
