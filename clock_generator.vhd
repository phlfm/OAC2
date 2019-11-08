-- Escola Politecnica da Universidade de Sao Paulo
-- PCS3422 - Organizacao e Arquitetura de Computadores II
-- 2019 - Autor: Pedro H L F de Mendonca

library IEEE;
use ieee.numeric_bit.all;

entity clock_generator is
	generic (CLOCK_PERIOD: time := 10 ns);
    port (
        clk: out  bit
    );
end clock_generator;

architecture behavior of clock_generator is
begin
    clk_generation: process
    begin
        clk <= '1';
        wait FOR CLOCK_PERIOD / 2;
        clk <= '0';
        wait FOR CLOCK_PERIOD / 2;

    end process clk_generation;

end architecture behavior;
