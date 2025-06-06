----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:12:11 04/04/2014 
-- Design Name: 
-- Module Name:    memoriaRAM - Behavioral 
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
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;
-- Memoria RAM de 128 oalabras de 32 bits
entity RAM_64_32 is port (
			CLK : in std_logic;
			ADDR : in std_logic_vector (31 downto 0); --Dir 
			Din : in std_logic_vector (31 downto 0);--entrada de datos para el puerto de escritura
			WE : in std_logic;		-- write enable	
			RE : in std_logic;		-- read enable		  
			enable: in std_logic; --solo se lee o escribe si enable est� activado
			Dout : out std_logic_vector (31 downto 0));
end RAM_64_32;

architecture Behavioral of RAM_64_32 is
type RamType is array(0 to 63) of std_logic_vector(31 downto 0);
signal RAM : RamType := (   		X"00000001", X"00000001", X"00000002", X"00000003", X"00000004", X"00000005", X"00000006", X"00000007", -- posiciones 0,1,2,3,4,5,6,7
									X"00000008", X"00000009", X"0000000A", X"0000000B", X"0000000C", X"0000000D", X"0000000E", X"0000000F", --posicones 8,9,...
									X"00000010", X"00000011", X"00000012", X"00000013", X"00000014", X"00000015", X"00000016", X"00000017",
									X"00000018", X"00000019", X"0000001A", X"0000001B", X"0000001C", X"0000001D", X"0000001E", X"0000001F",
									X"00000020", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000",
									X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000",
									X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000",
									X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000");
signal dir_7:  std_logic_vector(6 downto 0); 
begin
 
 dir_7 <= ADDR(8 downto 2); -- como la memoria es de 128 plalabras no usamos la direcci�n completa sino s�lo 7 bits. Como se direccionan los bytes, pero damos palabras no usamos los 2 bits menos significativos
 process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (WE = '1') and (enable = '1')then -- s�lo se escribe si WE vale 1
                RAM(conv_integer(dir_7)) <= Din;
				report "Simulation time : " & time'IMAGE(now) & ".  Data written: " & integer'image(to_integer(unsigned(Din))) & ", in MD_Scratch in ADDR = " & integer'image(to_integer(unsigned(ADDR)));
            end if;
        end if;
    end process;

    Dout <= RAM(conv_integer(dir_7)) when ((RE='1') and (enable = '1')) else "00000000000000000000000000000000"; --s�lo se lee si RE vale 1

end Behavioral;

