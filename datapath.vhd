
library ieee;
use ieee.numeric_bit.all; 
use ieee.std_logic_1164.ALL;

entity datapath is
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
end entity datapath;

architecture datapath of datapath is

	component Fetch is
		port (
			clock: in bit;
	        reset: in bit;	
	        
			PCSrc: in bit;
			BranchAddress: in bit_vector(doubleword-1 downto 0);
			
			PCout: out bit_vector(doubleword-1 downto 0);
			instruction: out bit_vector(word-1 downto 0);
			
			
			--LÓGICA DA PREVISÃO DE DESVIO 
			branch_prediction_in: in bit;
			branch_prediction_out: out bit
		);
		
	end component;

	component Decode is
		port (
			clock: in bit;
			reset: in bit;
		   
			PC: in bit_vector(doubleword-1 downto 0);
			instruction: in bit_vector(word-1 downto 0);
			RegWriteWB: in bit;
			WriteReg: in bit_vector(4 downto 0);
			WriteData:in bit_vector(doubleword-1 downto 0);
	
			PCOut: out bit_vector(doubleword-1 downto 0);
			instruction64: out bit_vector(doubleword-1 downto 0);
			OPCode: out bit_vector(10 downto 0);
			instruction4to0: out bit_vector(4 downto 0);
			ReadData1: out bit_vector(doubleword-1 downto 0);
			ReadData2: out bit_vector(doubleword-1 downto 0);  
			
			--LÓGICA DA PREVISÃO DE DESVIO 
			branch_prediction_in: in bit;
			branch_prediction_out: out bit;
			branch_address: out bit_vector(63 downto 0)
		);
			
	end component;
	
	component Execute is
		port (	
			clock: in bit;
			reset: in bit;
			
			AluSrc: in bit;						 --CONTROL
			AluCtl: in bit_vector(3 downto 0);	 --CONTROL
														   
			PC: in bit_vector(doubleword-1 downto 0);
			ReadData1: in bit_vector(doubleword-1 downto 0);
			ReadData2: in bit_vector(doubleword-1 downto 0);
			instruction64: in bit_vector(doubleword-1 downto 0);  -- SÓ É USADO NO MUX. O ENDEREÇO JÁ FOI CALCULADO NO DECODE
			OPCode: in bit_vector(10 downto 0);
			instruction4to0: in bit_vector(4 downto 0);
			
			
			AluResult: out bit_vector(doubleword-1 downto 0);
			AddResult: out bit_vector(doubleword-1 downto 0);  -- EQUIVALENTE AO branch_adress, QUE FOI CALCULADO NO DECODE
			Zero: out bit;
			ReadData2Out: out bit_vector(doubleword-1 downto 0);
			Instruction4to0Out: out bit_vector(4 downto 0);
			
			--LÓGICA DA PREVISÃO DE DESVIO 
			branch_prediction_in: in bit;
			branch_prediction_out: out bit;
			
			branch_address: in bit_vector(63 downto 0) --O branch_address continua no pipeline pelo AddResult
		);
			
	end component;
	
	component MemAccess is
		port (	
			clock: in bit;
	        reset: in bit;
			
	        branch: in bit;	    --CONTROL
			MemRead: in bit;	--CONTROL
			MemWrite: in bit;	--CONTROL
	        
			Address: in bit_vector(doubleWord-1 downto 0);
			AddResult: in bit_vector(doubleWord-1 downto 0);
			WriteData: in bit_vector(doubleWord-1 downto 0);
	        instruction4to0: in bit_vector(4 downto 0);
	        zero: in bit;  
		
			AddressOut: out bit_vector(doubleWord-1 downto 0);
			ReadData: out bit_vector(doubleWord-1 downto 0);
			Instruction4to0Out: out bit_vector(4 downto 0);
			PCSrc: out bit;
			BranchAddress: out bit_vector(doubleWord-1 downto 0);
			
			--LÓGICA DA PREVISÃO DE DESVIO 
			branch_prediction_in: in bit;
			prediction_out: out bit
		);
	end component;
	
	component WriteBack is
		port (		
			clock: in bit;
	      	reset: in bit;		
			
			MemToReg: in bit;   --CONTROL
	        
			Address: in bit_vector(doubleword-1 downto 0);
			ReadData: in bit_vector(doubleword-1 downto 0);	 	
									 
			WriteData: out bit_vector(doubleword-1 downto 0)
		);
	end component;

	signal IF_PC : bit_vector(doubleword-1 downto 0);
	signal IF_instruction : bit_vector(word-1 downto 0);
	
	signal ID_AluSrc, ID_branch, ID_MemRead, ID_MemWrite, ID_RegWrite, ID_MemToReg : bit;
	signal ID_PC : bit_vector(doubleword-1 downto 0);
	signal ID_instruction64 : bit_vector(doubleword-1 downto 0);
	signal ID_OPCode : bit_vector(10 downto 0);
	signal ID_instruction4to0 : bit_vector(4 downto 0);
	signal ID_ReadData1, ID_ReadData2 : bit_vector(doubleword-1 downto 0);
	
	signal EX_branch, EX_MemRead, EX_MemWrite, EX_RegWrite, EX_MemToReg : bit;
	signal EX_AluResult : bit_vector(doubleword-1 downto 0);
	signal EX_AddResult : bit_vector(doubleword-1 downto 0);
	signal EX_Zero : bit;
	signal EX_ReadData2 : bit_vector(doubleword-1 downto 0);
	signal EX_Instruction4to0 : bit_vector(4 downto 0);

	signal MEM_RegWrite, MEM_MemToReg : bit;
	signal MEM_PCSrc : bit;
	signal MEM_Address : bit_vector(doubleword-1 downto 0);
	signal MEM_ReadData : bit_vector(doubleword-1 downto 0);
	signal MEM_Instruction4to0 : bit_Vector(4 downto 0);
	signal MEM_BranchAddress : bit_vector(doubleword-1 downto 0);

	signal WB_RegWrite : bit;
	signal WB_WriteData : bit_vector(doubleword-1 downto 0);
	signal WB_WriteReg : bit_vector(4 downto 0);
	
	--LÓGICA DA PREVISÃO DE DESVIO 
	signal IF_branch_prediction_out: bit;
	signal ID_branch_prediction_out: bit; 
	signal ID_branch_address: bit_vector(63 downto 0); 
	signal EX_branch_prediction_out: bit;
	signal MEM_prediction_out: bit;

	
begin

	Fetch01 : Fetch
		port map (
			clock => clock,
			reset => reset,
			PCSrc => MEM_PCSrc,
			BranchAddress => MEM_BranchAddress,
			
			PCOut => IF_PC,
			instruction => IF_instruction,
			
			--LÓGICA DA PREVISÃO DE DESVIO 
			branch_prediction_in => MEM_prediction_out,
			branch_prediction_out => IF_branch_prediction_out
		);


	Decode01 : Decode
		port map (		
			clock => clock,
			reset => reset,	 
			
			PC => IF_PC,
			instruction => IF_instruction,
			RegWriteWB => WB_RegWrite,
			WriteReg => MEM_Instruction4to0,
			WriteData => WB_WriteData,
			
			PCOut => ID_PC,
			ReadData1 => ID_ReadData1,
			ReadData2 => ID_ReadData2,
			instruction64 => ID_instruction64,
			OPCode => ID_OPCode,
			instruction4to0 => ID_instruction4to0, 
			
			--LÓGICA DA PREVISÃO DE DESVIO 
			branch_prediction_in => IF_branch_prediction_out,
			branch_prediction_out => ID_branch_prediction_out,
			branch_address => ID_branch_address
		);	  

	Execute01 : Execute
		port map (		
			clock => clock,
			reset => reset,
			
			AluSrc => AluSrc,	 --CONTROL
			AluCtl => AluCtl,	 --CONTROL
			
			PC => ID_PC,
			ReadData1 => ID_ReadData1,
			ReadData2 => ID_ReadData2,
			instruction64 => ID_instruction64,
			OPCode => ID_OPCode,
			instruction4to0 => ID_instruction4to0,
			
			AluResult => EX_AluResult,
			AddResult => EX_AddResult,
			Zero => EX_Zero,
			ReadData2Out => EX_ReadData2,
			Instruction4to0Out => EX_Instruction4to0, 
			
			--LÓGICA DA PREVISÃO DE DESVIO 
			branch_prediction_in => ID_branch_prediction_out,
			branch_prediction_out => EX_branch_prediction_out,
			
			branch_address => ID_branch_address --O branch_address continua no pipeline pelo AddResult
		);

	MemAccess01 : MemAccess
		port map (		
			clock => clock,
			reset => reset,
			
			branch => branch,	 	--CONTROL
			MemRead => MemRead,		--CONTROL
			MemWrite => MemWrite,  	--CONTROL
			
			Address => EX_ALUResult, 
			AddResult => EX_AddResult,
			WriteData => Ex_ReadData2,
			Zero => EX_Zero,
			instruction4to0 => EX_instruction4to0,
			
			AddressOut => MEM_Address,
			ReadData => MEM_ReadData,
			Instruction4to0Out => MEM_Instruction4to0,
			PCSrc => MEM_PCSrc,
			BranchAddress => MEM_BranchAddress,	
			
			--LÓGICA DA PREVISÃO DE DESVIO 
			branch_prediction_in => EX_branch_prediction_out,
			prediction_out => MEM_prediction_out
		); 


	WriteBack01 : WriteBack
		port map (
			clock => clock,
			reset => reset,
									  
			MemToReg => MemToReg,
			
			Address => MEM_Address,
			ReadData => MEM_ReadData,	
			
			WriteData => WB_writeData 
		);


end architecture datapath;
 