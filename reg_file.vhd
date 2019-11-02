-- Pedro H. L. F. de Mendonca - 2.2019
-- para desabilitar o write, manda escrever no ultimo registrador write_reg <= '11111' que nada sera feito

library ieee;
use ieee.numeric_bit.all;

entity reg_file is
    generic(wordSize: natural :=64);
    port(
        clock : in bit;
        reset : in bit;
        read_reg1 : in bit_vector(4 downto 0);
        read_reg2 : in bit_vector(4 downto 0);
        write_reg : in bit_vector(4 downto 0);
        write_data : in bit_vector(wordSize-1 downto 0);
        read_data1 : out    bit_vector(wordSize-1 downto 0);
        read_data2 : out    bit_vector(wordSize-1 downto 0)
    );
end entity reg_file;

architecture arch of reg_file is

    component reg is
        generic(wordSize: natural :=4);
        port(
            clock:    in    bit; --! entrada de clock
            reset:    in    bit; --! clear assíncrono
            load:     in    bit; --! write enable (carga paralela)
            d:              in  bit_vector(wordSize-1 downto 0); --! entrada
            q:              out bit_vector(wordSize-1 downto 0) --! saída
        );
    end component;

    signal saiReg : bit_vector(wordSize*31-1 downto 0);
    signal entraReg : bit_vector(wordSize*32-1 downto 0); -- entraReg ocupa 32 pois o ultimo eh usado para desabilitar write
    signal loadReg : bit_vector(32-1 downto 0);
    signal clkReg: bit_vector(32-1 downto 0);

begin

-- gera os registradores de 0 a 30. O reg 31 eh constante igual a zero
geraRegs: FOR I in 0 TO 30 GENERATE
    regi: reg generic map (wordSize=>wordSize) port map(clock=>clkReg(I),
          reset=>reset, load=>loadReg(I), d=>entraReg((I+1)*wordSize-1 downto I*wordSize),
          q=>saiReg((I+1)*wordSize-1 downto I*wordSize));
END generate geraRegs;

-- "MUX" para selecionar as saidas e entradas
MUXr: process(clock, read_reg1, read_reg2, write_reg)
  variable r1, r2, w1 : unsigned(4 downto 0) := "00000";
begin
  r1 := unsigned(read_reg1);
  r2 := unsigned(read_reg2);
  w1 := unsigned(write_reg);

-- enable dos registradores (loadReg nas leituras e clock nas R/W)
    loadReg <= (others => '0');
    loadReg(to_integer(r1)) <= '1'; loadReg(to_integer(r2)) <= '1';

    clkReg <= (others => '0');
    clkReg(to_integer(r1)) <= clock; clkReg(to_integer(r2)) <= clock; clkReg(to_integer(w1)) <= clock;
-- fim dos enables

-- MUX dos registradores de leitura
    if (r1 = 31) then
      read_data1 <= (others => '0');
    else
      read_data1 <= saiReg((to_integer(r1)+1)*wordSize-1 downto to_integer(r1)*wordSize);
    end if; -- r1

    if (r2 = 31) then
      read_data2 <= (others => '0');
    else
      read_data2 <= saiReg((to_integer(r2)+1)*wordSize-1 downto to_integer(r2)*wordSize);
    end if; -- r2
-- fim dos MUX de leitura
-- MUX do registrador de escrita
        -- Aqui nao precisa do IF pois ao tentar escrever no ultimo registrador, que eh sempre zero,
        -- eh como se desabilitasse o write.
      entraReg((to_integer(w1)+1)*wordSize-1 downto to_integer(w1)*wordSize) <= write_data;
-- Fim do MUX do registrador de escrita

end process MUXr;
end architecture arch;
