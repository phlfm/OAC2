
library ieee;
use ieee.numeric_bit.all;

entity WriteBack is

	generic(
		doubleWord: natural := 64;
		word: natural := 32;
		halfWord: natural := 16
	);
	port (
		clock: in bit;
      	reset: in bit;		
		
		MemToReg: in bit;   --CONTROL
        
		Address: in bit_vector(doubleword-1 downto 0);
		ReadData: in bit_vector(doubleword-1 downto 0);	 	
								 
		WriteData: out bit_vector(doubleword-1 downto 0)	 
	);
		
end entity WriteBack;	 

	

architecture WriteBack of WriteBack is	   

	component mux2to1 is
	generic(ws: natural := 4); -- word size
	port(
		s:      in  bit; -- selection: 0=a, 1=b
		a, b:   in	bit_vector(ws-1 downto 0); -- inputs
		o:  	out	bit_vector(ws-1 downto 0)  -- output
	); 
	end component;		   
	
begin
	
	WB_mux : mux2to1 generic map (doubleWord) port map (
		s => MemToReg,
		a => Address,
		b => ReadData,
		o => WriteData	 
    );
    							 

end architecture WriteBack;
