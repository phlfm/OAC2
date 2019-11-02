--

library ieee;
use ieee.numeric_bit.all;

entity UC is
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
end entity UC;

architecture UC of UC is   
														   
    signal temp_AluOP: 		bit_vector(1 downto 0);	--EX	 								

	component ALUControl is
		port (
			ULAOp: in bit_vector(1 downto 0);
			instruction31to21: in bit_vector(10 downto 0);
			
			aluCtl: out bit_vector(3 downto 0)
		);
	end component ALUControl;
	
	component control is
		port (	
			clock : in bit;
			reset: in bit;
		
		    instruction31to21: in bit_vector(10 downto 0);
			 
			AluSrc: out bit;		      		--EX
		    AluOP: out bit_vector(1 downto 0);	--EX
		    
			branch: out bit;					--MEM
			MemRead: out bit;					--MEM
		    MemWrite: out bit; 					--MEM
			
		    RegWrite: out bit;					--WB
		    MemToReg: out bit					--WB
		);
	end component control;
	
begin
	  
	
	Control_Unit : control
		port map (	  
			clock => clock,
			reset => reset,
		    instruction31to21 => instruction31to21,
			AluSrc => AluSrc,		--EX
		    AluOP => temp_AluOP,	--EX
			branch => branch,		--MEM
			MemRead => MemRead,		--MEM
		    MemWrite => MemWrite, 	--MEM
		    RegWrite => RegWrite,	--WB
		    MemToReg => MemToReg	--WB
		);
			  
	ALU_Control: ALUControl port map (temp_AluOp, instruction31to21, AluCtl);
		
		--clock: in bit;
		--reset: in bit;
	
	    --instruction31to21: in bit_vector(10 downto 0);
		--AluOp: in bit_vector(1 downto 0);
		 	   
	    --branch: out bit;
		--MemRead: out bit;
	    --MemWrite: out bit;
	    --RegWrite: out bit;
	    --MemToReg: out bit	
		
end architecture UC;
