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
-- Memoria RAM de 128 palabras de 32 bits
entity RAM_128_32 is port (
		CLK : in std_logic;
		Reset : in std_logic;
		ADDR : in std_logic_vector (31 downto 0); --Dir 
        Din : in std_logic_vector (31 downto 0);--entrada de datos para el puerto de escritura
        enable: in std_logic; -- If enable is 0 WE and RE are ignored
        WE : in std_logic;		-- write enable	
		RE : in std_logic;		-- read enable		
		Fetch_inc: in std_logic;		-- NUEVO: se�al que indica que hay que hacer una FETCH_inc at�mica usando el paradigma in-memory processing  
		Mem_ready: out std_logic; -- indica si puede hacer la operaci�n solicitada en el ciclo actual
		Dout : out std_logic_vector (31 downto 0));
end RAM_128_32;

architecture Behavioral of RAM_128_32 is

	component reg is
	    generic (size: natural := 32);  -- por defecto son de 32 bits, pero se puede usar cualquier tama�o
		Port ( Din : in  STD_LOGIC_VECTOR (size -1 downto 0);
	           clk : in  STD_LOGIC;
		   reset : in  STD_LOGIC;
	           load : in  STD_LOGIC;
	           Dout : out  STD_LOGIC_VECTOR (size -1 downto 0));
		end component;	

	component counter is
	 	generic (   size : integer := 10);
		Port ( 	clk : in  STD_LOGIC;
	       		reset : in  STD_LOGIC;
	       		count_enable : in  STD_LOGIC;
	       		count : out  STD_LOGIC_VECTOR (size-1 downto 0));
	end component;
	
	type RamType is array(0 to 127) of std_logic_vector(31 downto 0);
	--RAM PARA TESTBENCH ERROR
	signal RAM : RamType := (       X"00000001", X"10000000", X"00000AB0", X"01000000", X"0BAD0C0D", X"00000000", X"00000000", X"00000000", -- word 0,1,2,3,4,5,6,7
	 								X"00000001", X"00000000", X"00000000", X"00000000", X"00000001", X"00000000", X"00000000", X"00000000", --word 8,...
	 								X"00000001", X"00000000", X"00000000", X"00000000", X"00000001", X"00000000", X"00000000", X"00000000",--word 16,...
	 								X"00000001", X"00000000", X"00000000", X"00000000", X"00000001", X"00000000", X"00000000", X"00000000",--word 24,...
	 								X"00000010", X"00000000", X"00000000", X"00000000", X"00000010", X"00000000", X"00000000", X"00000000",--word 32,...
	 								X"00000010", X"00000000", X"00000000", X"00000000", X"00000010", X"00000000", X"00000000", X"00000000",--word 40,...
	 								X"00000010", X"00000000", X"00000000", X"00000000", X"00000010", X"00000000", X"00000000", X"00000000",--word 48,...
	 								X"00000010", X"00000000", X"00000000", X"00000000", X"00000010", X"00000000", X"00000000", X"00000000",--word 56,...
	 								X"10000000", X"00000AB0", X"01000000", X"0BAD0C0D", X"00000100", X"00000000", X"00000000", X"00000000",--word 64,...
	 								X"00000100", X"00000000", X"00000000", X"00000000", X"00000100", X"00000000", X"00000000", X"00000000",--word 72,...
	 								X"00000100", X"00000000", X"00000000", X"00000000", X"00000100", X"00000000", X"00000000", X"00000000",--word 80,...
	 								X"00000100", X"00000000", X"00000000", X"00000000", X"00000100", X"00000000", X"00000000", X"00000000",--word 88,...
	 								X"00001000", X"00000000", X"00000000", X"00000000", X"00001000", X"00000000", X"00000000", X"00000000",--word 96,...
	 								X"00001000", X"00000000", X"00000000", X"00000000", X"00001000", X"00000000", X"00000000", X"00000000",--word 104,...
	 								X"00001000", X"00000000", X"00000000", X"00000000", X"00001000", X"00000000", X"00000000", X"00000000",--word 112,...
	 								X"00001000", X"00000000", X"00000000", X"00000000", X"00001000", X"00000000", X"00000000", X"00000004");--word 120,...

	-- RAM PARA HUGE UNIT TEST 1
	-- signal RAM : RamType := (       X"00000000", X"00000001", X"00000002", X"00000003", X"00000004", X"00000005", X"00000006", X"00000007", -- word 0,1,2,3,4,5,6,7
    --                             X"00000008", X"00000009", X"0000000A", X"0000000B", X"0000000C", X"0000000D", X"0000000E", X"0000000F", --word 8,...
    --                             X"00000010", X"00000011", X"00000012", X"00000013", X"00000014", X"00000015", X"00000016", X"00000017", --word 16,...
    --                             X"00000018", X"00000019", X"0000001A", X"0000001B", X"0000001C", X"0000001D", X"0000001E", X"0000001F", --word 24,...
    --                             X"00000020", X"00000021", X"00000022", X"00000023", X"00000024", X"00000025", X"00000026", X"00000027", --word 32,...
    --                             X"00000028", X"00000029", X"0000002A", X"0000002B", X"0000002C", X"0000002D", X"0000002E", X"0000002F", --word 40,...
    --                             X"00000030", X"00000031", X"00000032", X"00000033", X"00000034", X"00000035", X"00000036", X"00000037", --word 48,...
    --                             X"00000038", X"00000039", X"0000003A", X"0000003B", X"0000003C", X"0000003D", X"0000003E", X"0000003F", --word 56,...
    --                             X"00000040", X"00000041", X"00000042", X"00000043", X"00000044", X"00000045", X"00000046", X"00000047", --word 64,...
    --                             X"00000048", X"00000049", X"0000004A", X"0000004B", X"0000004C", X"0000004D", X"0000004E", X"0000004F", --word 72,...
    --                             X"00000050", X"00000051", X"00000052", X"00000053", X"00000054", X"00000055", X"00000056", X"00000057", --word 80,...
    --                             X"00000058", X"00000059", X"0000005A", X"0000005B", X"0000005C", X"0000005D", X"0000005E", X"0000005F", --word 88,...
    --                             X"00000060", X"00000061", X"00000062", X"00000063", X"00000064", X"00000065", X"00000066", X"00000067", --word 96,...
    --                             X"00000068", X"00000069", X"0000006A", X"0000006B", X"0000006C", X"0000006D", X"0000006E", X"0000006F", --word 104,...
    --                             X"00000070", X"00000071", X"00000072", X"00000073", X"00000074", X"00000075", X"00000076", X"00000077", --word 112,...
    --                             X"00000078", X"00000079", X"0000007A", X"0000007B", X"0000007C", X"0000007D", X"0000007E", X"0000007F"); --word 120,...		
	-- RAM PARA MD_SCRATCH
	--signal RAM : RamType := (       X"10000000", X"00000001", X"00000002", X"00000003", X"00000004", X"00000005", X"00000006", X"00000007", -- word 0,1,2,3,4,5,6,7
    --                            X"00000008", X"00000009", X"0000000A", X"0000000B", X"0000000C", X"0000000D", X"0000000E", X"0000000F", --word 8,...
      --                          X"00000010", X"00000011", X"00000012", X"00000013", X"00000014", X"00000015", X"00000016", X"00000017", --word 16,...
        --                        X"00000018", X"00000019", X"0000001A", X"0000001B", X"0000001C", X"0000001D", X"0000001E", X"0000001F", --word 24,...
          --                      X"00000020", X"00000021", X"00000022", X"00000023", X"00000024", X"00000025", X"00000026", X"00000027", --word 32,...
            --                    X"00000028", X"00000029", X"0000002A", X"0000002B", X"0000002C", X"0000002D", X"0000002E", X"0000002F", --word 40,...
              --                  X"00000030", X"00000031", X"00000032", X"00000033", X"00000034", X"00000035", X"00000036", X"00000037", --word 48,...
                --                X"00000038", X"00000039", X"0000003A", X"0000003B", X"0000003C", X"0000003D", X"0000003E", X"0000003F", --word 56,...
                  --              X"00000040", X"00000041", X"00000042", X"00000043", X"00000044", X"00000045", X"00000046", X"00000047", --word 64,...
                    --            X"00000048", X"00000049", X"0000004A", X"0000004B", X"0000004C", X"0000004D", X"0000004E", X"0000004F", --word 72,...
                     --           X"00000050", X"00000051", X"00000052", X"00000053", X"00000054", X"00000055", X"00000056", X"00000057", --word 80,...
                         --       X"00000058", X"00000059", X"0000005A", X"0000005B", X"0000005C", X"0000005D", X"0000005E", X"0000005F", --word 88,...
                       --         X"00000060", X"00000061", X"00000062", X"00000063", X"00000064", X"00000065", X"00000066", X"00000067", --word 96,...
                           --     X"00000068", X"00000069", X"0000006A", X"0000006B", X"0000006C", X"0000006D", X"0000006E", X"0000006F", --word 104,...
                             --   X"00000070", X"00000071", X"00000072", X"00000073", X"00000074", X"00000075", X"00000076", X"00000077", --word 112,...
                               -- X"00000078", X"00000079", X"0000007A", X"0000007B", X"0000007C", X"0000007D", X"0000007E", X"0000007F"); --word 120,...		 
	signal dir_7:  std_logic_vector(6 downto 0); 
	signal internal_WE, internal_RE, internal_reg_load, State_Machine_enable, fetch_inc_ready, fetch_inc_we, fetch_inc_re, RAM_Din_Dout_control: std_logic;
	signal RAM_Din, RAM_Dout, Fetch_inc_data:  std_logic_vector(31 downto 0); 
	signal fetch_in_state:  std_logic_vector(0 downto 0); 	
	
	begin
	 
	 dir_7 <= ADDR(8 downto 2); -- como la memoria es de 128 plalabras no usamos la direcci�n completa sino s�lo 7 bits. Como se direccionan los bytes, pero damos palabras no usamos los 2 bits menos significativos
	 process (CLK)
	    begin
	        if (CLK'event and CLK = '1') then
	            if (internal_WE = '1') and (enable = '1')then -- s�lo se escribe si WE vale 1
	                RAM(conv_integer(dir_7)) <= RAM_Din;
					--report works as a printf
	                report "Simulation time : " & time'IMAGE(now) & ".  Data written: " & integer'image(to_integer(unsigned(Din))) & ", in ADDR = " & integer'image(to_integer(unsigned(ADDR)));
	            end if;
	        end if;
	    end process;
	
	    RAM_Dout <= RAM(conv_integer(dir_7)) when ((internal_RE='1') and (enable = '1')) else x"00000000"; 
--------------------------------------------------------------------------------------------------
--	Gesti�n para la instrucci�n at�mica lw_inc con el paradigma de in-memory processing
-- 
-- 	Mem_Reg: Almacena el valor le�do en Mem para usarlo al ciclo siguiente.
-- 	Fetch_inc_counter: implementa la m�quina de dos estados que gestiona el fetch_inc. 
--	En el primer ciclo se cargar� el dato en el registro y se pondr� mem_ready a 0
-- 	En el segundo se sumar� 1 al valor le�do, se actualizar� la memoria, y se env�ar� el valor original al MIPS
--------------------------------------------------------------------------------------------------
	Mem_Reg: reg generic map (size => 32)
					port map (	Din => RAM_Dout, clk => clk, reset => reset, load => internal_reg_load, Dout => Fetch_inc_data);	 
	State_Machine_enable <= Fetch_inc and enable; -- The State machine counts only for fetch_inc instrucctions when the memory is enable
	Fetch_inc_counter: counter 	generic map (size => 1)	port map (clk => clk, reset => reset, count_enable => State_Machine_enable, count => fetch_in_state);  
-- Combinational logic for the fetch_in_control unit
	OUTPUT_DECODE: process (fetch_in_state, State_Machine_enable)
	begin
		--Default values
		fetch_inc_WE <= '0'; --Activates the memory WE during the fetch_in operation
		fetch_inc_RE <= '0'; --Activates the memory RE during the fetch_in operation
		RAM_Din_Dout_control <= '0'; -- It is used to select the input from the increment to write in the RAm, and to send the data stored in the register (i.e. before the increment) in the Dout signal
		fetch_inc_ready <= '0';	--It indicates that it is a fetch_inc operation, and the memory enable is active   
		internal_reg_load <= '0';-- It is used to store the read data in the internal register
		case fetch_in_state is
		     when "0" => --we have to use "0" instead of '0' becouse this signal was defined as a vector of size 1
		         If (State_Machine_enable='1') then
		         	internal_reg_load <= '1';
						fetch_inc_RE <= '1';
		         end if;
		     when others =>
		     	 If (State_Machine_enable='1') then --theoretically this should always happend
		     	 	fetch_inc_WE <= '1'; --Indicates that the inc. value must be written in the RAM
		     	 	RAM_Din_Dout_control <= '1';
		     	 	fetch_inc_ready <= '1';
		     	 end if;
		 end case;
	end process;
-- WE
	internal_WE <= WE or fetch_inc_WE;
	internal_RE <= RE or fetch_inc_RE;
-- Increment logic
	RAM_Din <= 	Din when (RAM_Din_Dout_control='0') else (Fetch_inc_data + X"00000001");
-- Output logic
	Dout <= RAM_Dout when (RAM_Din_Dout_control='0') else Fetch_inc_data;
	Mem_ready <= '0' when ((Fetch_inc='1')and(enable='1')and(fetch_inc_ready='0')) else enable; --In this memory, the only operation that demands more than one cycle is the Fetch-inc
end Behavioral;

