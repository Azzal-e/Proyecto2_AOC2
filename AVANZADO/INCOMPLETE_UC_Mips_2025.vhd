----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:14:28 04/07/2014 
-- Design Name: 
-- Module Name:    UC - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity UC is
    Port ( 	valid_I_ID : in  STD_LOGIC; --valid bit
			IR_op_code : in  STD_LOGIC_VECTOR (5 downto 0);
         	Branch : out  STD_LOGIC;
           	RegDst : out  STD_LOGIC;
           	ALUSrc : out  STD_LOGIC;
		   	MemWrite : out  STD_LOGIC;
           	MemRead : out  STD_LOGIC;
           	MemtoReg : out  STD_LOGIC_VECTOR (1 downto 0);  -- SE MODIFICA RESPECTO A LA VERSIÓN ANTERIOR PARA INCLUIR DIRECTAMENTE EL CASO DEL JAL
           	RegWrite : out  STD_LOGIC;
          	jal : out  STD_LOGIC; --jal instruction 
        	ret : out  STD_LOGIC; --ret instruction
			undef: out STD_LOGIC; --indicates that the operation code does not belong to a known instruction. In this processor, it is used only for debugging.
           	 -- New signals
		   	RTE	: out  STD_LOGIC; -- RTE instruction 
			f_inc: out  STD_LOGIC -- fetch_inc instruction
			  -- END New signals
			);  
end UC;

architecture Behavioral of UC is
-- to improve readability
CONSTANT NOP_opcode : STD_LOGIC_VECTOR (5 downto 0) 	:= "000000";
CONSTANT ARIT_opcode : STD_LOGIC_VECTOR (5 downto 0) 	:= "000001";
CONSTANT LW_opcode : STD_LOGIC_VECTOR (5 downto 0) 		:= "000010";
CONSTANT SW_opcode : STD_LOGIC_VECTOR (5 downto 0) 		:= "000011";
CONSTANT BEQ_opcode : STD_LOGIC_VECTOR (5 downto 0) 	:= "000100";
CONSTANT JAL_opcode : STD_LOGIC_VECTOR (5 downto 0) 	:= "000101";
CONSTANT RET_opcode : STD_LOGIC_VECTOR (5 downto 0)		:= "000110";
CONSTANT RTE_opcode : STD_LOGIC_VECTOR (5 downto 0) 	:= "001000";
CONSTANT FI_opcode : STD_LOGIC_VECTOR (5 downto 0) 		:= "010000";
begin

UC_mux : process (IR_op_code, valid_I_ID)
begin 
	-- By default we set all signals to 0 which is the value that guarantees that we do not alter anything.
	Branch <= '0'; RegDst <= '0'; ALUSrc <= '0'; MemWrite <= '0'; MemRead <= '0'; MemtoReg <= "00"; RegWrite <= '0'; UNDEF <= '0';
	jal <= '0'; ret <= '0'; RTE <= '0'; f_inc <= '0';
	IF valid_I_ID = '1' then --if the instruction is valid we analyse its operation code
		CASE IR_op_code IS
		--NOP 

			WHEN  NOP_opcode  	=>  
			--ARIT
			WHEN  ARIT_opcode  	=> 	RegDst <= '1'; RegWrite <= '1'; 
			--LW
			WHEN  LW_opcode  	=>  ALUSrc <= '1'; MemRead <= '1'; MemtoReg <= "01"; RegWrite <= '1'; 
			--SW
			WHEN  SW_opcode  	=>  ALUSrc <= '1'; MemWrite <= '1'; 
			--BEQ
			WHEN  BEQ_opcode  	=>  Branch <= '1'; 
			------------------------------------------------
			-- COMPLETE

			------------------------------------------------
			-- JAL

			WHEN  jal_opcode  	=>  jal <= '1';  -- Any more signals?
									MemtoReg <= "10"; 
									RegDst <= '0';
									RegWrite <= '1';
			-- RET
			WHEN  RET_opcode  	=>  ret <= '1'; -- Any more signals?
			--RTE
			WHEN  RTE_opcode  	=>  RTE <= '1'; -- Any more signals?
			--Fetch_inc

			WHEN  FI_opcode  	=>  f_inc <= '1';
									ALuSrc <= '1';
									RegDst <= '0'; -- Queremos RT.
									-- No hay que tocar nada para la ALU porque ALUCtrl está por defecto
									-- a "000"
									MemtoReg <= "01";
									RegWrite <= '1';
									MemRead <= '1';
									MemWrite <= '1';
			-- OP code undefined1
			WHEN  OTHERS 	  	=> UNDEF <= '1';
		  END CASE;
	END IF;
end process;
end Behavioral;

