----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    22:25:11 04/07/2014 
-- Design Name: 
-- Module Name:    Banco_WB - Behavioral 
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

entity Banco_WB is
Port ( 	ALU_out_MEM : in  STD_LOGIC_VECTOR (31 downto 0); 
		ALU_out_WB : out  STD_LOGIC_VECTOR (31 downto 0); 
		MEM_out : in  STD_LOGIC_VECTOR (31 downto 0); 
		MDR : out  STD_LOGIC_VECTOR (31 downto 0); --memory data register
        clk : in  STD_LOGIC;
		reset : in  STD_LOGIC;
        load : in  STD_LOGIC;
		MemtoReg_MEM : in  STD_LOGIC_VECTOR (1 downto 0);
        RegWrite_MEM : in  STD_LOGIC;
		MemtoReg_WB : out  STD_LOGIC_VECTOR (1 downto 0);
        RegWrite_WB : out  STD_LOGIC;
        RW_MEM : in  STD_LOGIC_VECTOR (4 downto 0); -- registro destino de la escritura
        RW_WB : out  STD_LOGIC_VECTOR (4 downto 0); -- PC+4 en la etapa IDend Banco_WB;
        --bits de validez
        valid_I_WB_in: in STD_LOGIC;
        valid_I_WB: out STD_LOGIC;
        -- Puertos para a�adir se�ales
		-- Estos puertos se utilizan para a�adir funcionalidades al MIPS que requieran enviar informaci�n de una etapa a las etapas siguientes
		-- El banco permite enviar dos se�ales de un bit (ext_signal_1 y 2) y dos palabras de 32 bits ext_word_1 y 2)
		ext_signal_1_MEM: in  STD_LOGIC;
		ext_signal_1_WB: out  STD_LOGIC;
		ext_signal_2_MEM: in  STD_LOGIC;
		ext_signal_2_WB: out  STD_LOGIC;
		ext_word_1_MEM:  IN  STD_LOGIC_VECTOR (31 downto 0);
		ext_word_1_WB:  OUT  STD_LOGIC_VECTOR (31 downto 0);
		ext_word_2_MEM:  IN  STD_LOGIC_VECTOR (31 downto 0);
		ext_word_2_WB:  OUT  STD_LOGIC_VECTOR (31 downto 0)
		--fin puertos extensi�n
		);
end Banco_WB;
architecture Behavioral of Banco_WB is

begin
SYNC_PROC: process (clk)
   begin
      if (clk'event and clk = '1') then
         if (reset = '1') then
            ALU_out_WB <= "00000000000000000000000000000000";
				MDR <= "00000000000000000000000000000000";
				RW_WB <= "00000";
				MemtoReg_WB <= "00";
				RegWrite_WB <= '0';
				valid_I_WB <= '0';
				--Puertos extensi�n
				ext_word_1_WB <= x"00000000";
				ext_word_2_WB <= x"00000000";
				ext_signal_1_WB <= '0';
				ext_signal_2_WB <= '0';
         else
            if (load='1') then 
					ALU_out_WB <= ALU_out_MEM;
					MDR <= Mem_out;
					RW_WB <= RW_MEM;
					MemtoReg_WB <= MemtoReg_MEM;
					RegWrite_WB <= RegWrite_MEM;
					valid_I_WB <= valid_I_WB_in;
					--Puertos extensi�n
					ext_word_1_WB <= ext_word_1_MEM;
					ext_word_2_WB <= ext_word_2_MEM;
					ext_signal_1_WB <= ext_signal_1_MEM;
					ext_signal_2_WB <= ext_signal_2_MEM;
				end if;	
         end if;        
      end if;
   end process;

end Behavioral;

