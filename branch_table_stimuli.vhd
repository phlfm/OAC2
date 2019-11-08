-- Escola Politecnica da Universidade de Sao Paulo
-- PCS3422 - Organizacao e Arquitetura de Computadores II
-- 2019 - Autor: Pedro H L F de Mendonca

library IEEE;
use ieee.numeric_bit.all;

entity branch_table_stimuli is
	generic
	(
		addrSize	: NATURAL	:= 16; -- tamanho do bus de enderecos
		tableSize	: NATURAL	:= 16; -- quantos desvios guardar na tabela
		ringBufferSize : NATURAL := 4 -- como regra, ringBufferSize = numero de 1's em (tableSize-1) e tableSize = potencia de 2.
		-- ringBufferSize precisa ser grande o suficiente para acomodar tableSize, exemplo:
		-- se tableSize = 8, entao vamos acessar de 0 a (8-1), entao temos de 0 a 7, logo
		-- ringBufferSize precisa ser 3 para acomodar 000 a 111
		-- se tableSize = 16, entao vamos acessar de 0 a (16-1), entao temos de 0 a 15, logo
		-- ringBufferSize precisa ser 4 para acomodar 0000 a 1111
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

    signal s_addrIR : bit_vector(addrSize-1 downto 0);
    signal s_addrIW : bit_vector(addrSize-1 downto 0);
    signal s_addrBW : bit_vector(addrSize-1 downto 0);

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
    reset <= '0';
    wait_test(5*5 ns);

    -- Test 4 a 30 - inserir varios valores...
    -- Quando teste PAR:
        -- o end de leitura vai ser o proprio endereco
        -- o end de escrita vai ser o proximo impar * 2
        -- o end de branch vai ser 10* o atual +1
        -- o resultado do branch vai ser 1
    -- Quando impar:
        -- vai ler *2 o atual (que foi escrito no par anterior)
        -- vai escrever no *2 (que ja foi escrito pelo par anterior)
        -- assim ja testa write before READ
        -- o end de branch eh zero pq nao deveria influenciar
        -- o resultado do branch eh zero
    generate_tests_t1: for i1 in 4 to 30 loop
    if (i1 mod 2) = 0 then
        s_addrIR <= converte(i1, addrSize);
        s_addrIW <= converte((i1+1)*2, addrSize);
        s_addrBW <= converte(i1*10+1, addrSize);
        branch_result     <= '1'; -- EXECUTE: resultado do branch para atualizar
    else
        s_addrIR <= converte(i1*2, addrSize);
        s_addrIW <= converte(i1*2, addrSize);
        s_addrBW <= (others => '0');
        branch_result     <= '0'; -- EXECUTE: resultado do branch para atualizar
    end if;
        instruction_addrR <= s_addrIR; -- FETCH - end da inst atual
        branch_instruction<= '1'; -- EXECUTE:  age como um enable de escrita
        instruction_addrW <= s_addrIW; -- EXECUTE: end da inst atual
        branch_addrW      <= s_addrBW; -- end EXECUTE: para o qual desviar
        wait_test(5 ns);
    end loop generate_tests_t1;




-- test end
    test_end <= '1';
    wait for 5000 ns;
end process;

end stimuli;
