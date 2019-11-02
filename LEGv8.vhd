
library ieee;
use ieee.numeric_bit.all;

entity LEGv8 is
	port(
		clock : in bit;	
		reset : in bit;

		op_code : out bit_vector(10 downto 0);
		zero: out bit
	);
		 
end entity LEGv8;

architecture LEGv8 of LEGv8 is
	component UC is
		port (
			clock: in bit;
			reset: in bit;
		    instruction31to21: in bit_vector(10 downto 0);
			
			AluSrc:	out bit;
			AluCtl: out bit_vector(3 downto 0); 	   
		    branch: out bit;
			MemRead: out bit;
		    MemWrite: out bit;
		    RegWrite: out bit;
		    MemToReg: out bit
		);
	end component UC;
	
	component datapath is
		generic(doubleWord: natural := 64;
				  word: natural := 32;
				  halfWord: natural := 16);
		port (
			clock : in bit;	
		    reset : in bit;
		
		    AluSrc: in bit;						 	--EX
			AluCtl: in bit_vector(3 downto 0);		--EX
		    
			branch:   in bit;						--MEM
			MemRead:  in bit;						--MEM
		    MemWrite: in bit; 						--MEM
			
		    RegWrite: in bit;					 	--WB
		    MemToReg: in bit;						--WB
			 
			AluOpOut : out bit_vector(1 downto 0);
		    instruction31to21: out bit_vector(10 downto 0);
		    zero: out bit
		 );
	end component datapath;
	
	
	signal instruction31to21: bit_vector(10 downto 0);
	signal reg2loc: bit;
	signal uncondBranch: bit;
	signal branch: bit;
	signal memRead: bit;
	signal memToReg: bit;
	signal AluOp1, AluOp2 : bit_vector(1 downto 0);
	signal AluCtl: bit_vector(3 downto 0);
	signal memWrite: bit;
	signal aluSrc: bit;
	signal regWrite: bit;
	
begin

	Control_Unit : UC
	port map (			   
		clock => clock,
		reset => reset,
		instruction31to21 => instruction31to21, 
						  
		AluSrc => AluSrc,	  	--EX
		AluCtl => AluCtl,	  	--EX
		branch => branch,	 	--MEM
		MemRead => MemRead,   	--MEM
		MemWrite => MemWrite,	--MEM
		RegWrite => RegWrite,	--WB
		MemToReg => MemToReg	--WB
	);	
		
		
	Data_Path : datapath
	  port map (
			 clock => clock,
			 reset => reset,
						  
			 AluSrc => AluSrc,	  	--EX
			 AluCtl => AluCtl,		--EX
			 
			 branch => branch,		--MEM
			 MemRead => MemRead, 	--MEM
			 MemWrite => MemWrite, 	--MEM
			 
			 RegWrite => MemWrite,	--WB
			 MemToReg => MemToReg,	--WB
			 
			 AluOpOut => AluOp2,
			 instruction31to21 => instruction31to21,
			 zero => zero
		 );	  	 
		
	op_code <= instruction31to21;
	
end architecture LEGv8;




