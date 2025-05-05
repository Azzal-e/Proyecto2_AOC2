----------------------------------------------------------------------------------
-- Company: 
-- Engineer: JR
-- 
-- Create Date:    14:12:11 04/04/2025 
-- Design Name: 
-- Module Name:    MD_cont
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
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;


entity MD_cont is port (
		  CLK : in std_logic;
		  reset: in std_logic;
		  Bus_Frame: in std_logic; -- indicates that the manager wants more data
		  bus_last_word : in  STD_LOGIC; -- indicates that it is the last data of the transfer.
		  bus_Read: in std_logic;
		  bus_Write: in std_logic;
		  Bus_Fetch_inc: in std_logic;
		  Bus_Addr : in std_logic_vector (31 downto 0); --@
		  Bus_Data : in std_logic_vector (31 downto 0); --Data  
		  MD_Bus_DEVsel: out std_logic; -- to notify that the address has been recognized as belonging to this module
		  MD_Bus_TRDY: out std_logic; -- to signal that the requested operation is to be performed in the current cycle
		  MD_send_data: out std_logic; -- to send the data to the bus
          MD_Dout : out std_logic_vector (31 downto 0)		  -- data output
		  );
end MD_cont;

architecture Behavioral of MD_cont is

component counter is
 	generic (   size : integer := 10);
	Port ( clk : in  STD_LOGIC;
       reset : in  STD_LOGIC;
       count_enable : in  STD_LOGIC;
       count : out  STD_LOGIC_VECTOR (size-1 downto 0));
end component;

-- same componenet as in the previous project
component RAM_128_32 is port (
		  CLK : in std_logic;
		  Reset : in std_logic;
		  enable: in std_logic; -- only read or write if enable is activated
		  ADDR : in std_logic_vector (31 downto 0); --@ 
          Din : in std_logic_vector (31 downto 0);--Data in
          WE : in std_logic;		-- write enable	
		  RE : in std_logic;		-- read enable		  
		  Fetch_inc: in std_logic;	--  NEW: signal indicating that an atomic FETCH_inc must be performed using the in-memory processing paradigm 
		  Mem_ready: out std_logic; -- indicates whether the requested operation can be performed in the current cycle
		  Dout : out std_logic_vector (31 downto 0));
end component;

component reg is
    generic (size: natural := 32);  -- by default are 32-bit, but any size can be used.
	Port ( Din : in  STD_LOGIC_VECTOR (size -1 downto 0);
           clk : in  STD_LOGIC;
		   reset : in  STD_LOGIC;
           load : in  STD_LOGIC;
           Dout : out  STD_LOGIC_VECTOR (size -1 downto 0));
end component;


signal BUS_RE, BUS_WE, MEM_WE, contar_palabras, reset_cuenta, reset_cont_retardos, MD_enable, initial_delay, contar_retardos, direccion_distinta, reset_retardo, load_addr, Addr_in_range: std_logic;
signal addr_frame, last_addr:  STD_LOGIC_VECTOR (6 downto 0);
signal cuenta_palabras, cuenta_retardos:  STD_LOGIC_VECTOR (7 downto 0);
signal MD_addr: STD_LOGIC_VECTOR (31 downto 0);
type state_type is (Espera, Transferencia, Detectado); 
signal state, next_state : state_type; 
signal last_addr_valid_vector: std_logic_vector (0 downto 0);-- Indicates if the last_addr register has a valid address and not a 0 coming from a reset
signal load_control, Internal_read, Internal_write, Internal_fetch_inc, last_addr_valid, mem_ready: std_logic; --signals to store inputs bus_read, and bus_write
begin
---------------------------------------------------------------------------
-- Decoder: identifies when the address belongs to the MD: (X"00000000"-X"000001FF")
---------------------------------------------------------------------------
-- It is activated when the bus wants to perform an operation (bus_read or bus_write = '1') and the address belongs to the asigned @ range
Addr_in_range <= '1' when (Bus_Addr(31 downto 9) = "00000000000000000000000") AND ((bus_Read ='1')or (bus_Write = '1') or (bus_Fetch_inc = '1')) else '0'; 

---------------------------------------------------------------------------
-- Register that stores the bus control signals.
---------------------------------------------------------------------------

Read_Write_register: process (clk)
   begin
      if (clk'event and clk = '1') then
         if (reset = '1') then
            Internal_read <= '0';
			Internal_write <= '0';
			Internal_fetch_inc <= '0';
         elsif load_control = '1' then 
            Internal_read <= bus_Read;
			Internal_write <= bus_write;
			Internal_fetch_inc <= Bus_Fetch_inc;
         end if;        
      end if;
   end process;

BUS_RE <= Internal_read;

BUS_WE <= Internal_write;

---------------------------------------------------------------------------
-- Code to introduce artificial delays
-- With a counter and a simple state machine we artificially introduce an initial delay into the memory. 
-- When an address is requested it takes six cycles to find the address of the first word
-- If the same address is accessed twice, the second time there is no initial delay.
---------------------------------------------------------------------------
reset_cont_retardos <= reset or reset_retardo;
cont_retardos: counter 		generic map (size => 8)	port map (clk => clk, reset => reset_cont_retardos, count_enable => contar_retardos, count => cuenta_retardos);

-- This register stores the last address accessed. Each time the address changes, the delay counter is reset.
-- The idea is to simulate that when you access a new address it takes longer. If you always access the same address it will not introduce additional delays.
reg_last_addr: reg 	generic map (size => 7)
					PORT MAP(Din => Bus_Addr(8 downto 2), CLK => CLK, reset => reset, load => load_addr, Dout => last_addr);
reg_last_addr_valid: reg 	generic map (size => 1)
							PORT MAP(Din => "1", CLK => CLK, reset => reset, load => load_addr, Dout => last_addr_valid_vector);
last_addr_valid <= 	last_addr_valid_vector(0); -- type conversion						
direccion_distinta <= '0' when ((last_addr= Bus_Addr(8 downto 2)) and (last_addr_valid='1')) else '1';
-- We artificially introduce a delay in the memory. Send the first word in the sixth cycle
-- But if the accesses are to repeated addresses, the initial delay disappears.
-- 
initial_delay <= '1' when (cuenta_retardos < "00000101") else '0';
---------------------------------------------------------------------------
-- State machine for managing transfers and introducing delays
---------------------------------------------------------------------------

SYNC_PROC: process (clk)
   begin
      if (clk'event and clk = '1') then
         if (reset = '1') then
            state <= Espera;
         else
            state <= next_state;
         end if;        
      end if;
   end process;


   
 --MEALY State-Machine - Outputs based on state and inputs
   OUTPUT_DECODE: process (state, direccion_distinta, Addr_in_range, initial_delay, Bus_Frame, reset_cuenta, Internal_Fetch_inc, mem_ready)
   begin
		-- default values, if no other value is assigned in a state they will be worth what is assigned here
		contar_retardos <= '0';
		reset_retardo <= '0';
		load_addr <= '0';
		load_control <= '0';
		next_state <= Espera;
		MD_Bus_DEVsel <= '0';
		MD_Bus_TRDY <= '0'; 
		MD_send_data <= '0';
		MEM_WE <= '0';
		MD_enable <= '0';
		contar_palabras <= '0';
		
		  
		case state is
			-- Initial state: Espera (wait state)
			when Espera =>   
				If (Addr_in_range= '0') or (Bus_Frame = '0') then -- if they do not ask for anything, we do nothing. We only read the address if Bus_frame is activated.
					next_state <= Espera;
				else  -- if we detect that there is a transfer and the address belongs to us we go to the transfer status
					next_state <= Detectado;
					MD_Bus_DEVsel <= '1'; -- we report that the address is ours.
					load_control <= '1'; -- To load control signals
					IF (direccion_distinta ='1') then
						reset_retardo <= '1'; -- if the address is repeated we do not enter the initial delays
						load_addr <= '1'; -- Address load
					end if;	
				end if;	
   	    -- Detectado: is used to inform that we have seen that the address is ours and that we are going to start reading/writing data. 
      		when Detectado => --Detectado: address detected state   
				If (Bus_Frame = '1') then
					next_state <= Transferencia;
					MD_Bus_DEVsel <= '1'; -- we report that the address is ours.
				  -- We did not start reading/writing
				else 	-- When Bus_Frame is 0 we are done. It should not happen because we have not done anything yet
					next_state <= Espera;
				end if;
		  -- Transferencia: transfer state
			when Transferencia =>   
				if (Bus_Frame = '1') then -- if we are in a transfer we keep sending/receiving data until the master says he doesn't want any more
					MD_Bus_DEVsel <= '1'; -- we report that the address is ours.
					MD_enable <= not(initial_delay); -- If we are in the initial delay, we do nothing but increassing the delay count.
					contar_retardos <= initial_delay; 
					MD_Bus_TRDY <= mem_ready; -- If we are in the delay period the enable will be set to '1' and will not be activated.
					contar_palabras <= mem_ready; -- each time a word is sent the counter is incremented
					MEM_WE <= Bus_WE; -- we avoid writing several times because in the initial delays enable is set to '0'.
					MD_send_data <= (Bus_RE or Internal_Fetch_inc)and mem_ready; -- if the address is in range and it is a read or a fetch_inc the MD data is loaded on the bus when the memory is ready
					if ((bus_last_word='1')and(mem_ready = '1')) then --if we are sending the last word we are finished
						next_state <= Espera;
						reset_retardo <= '1';
					else
						next_state <= Transferencia;
					end if;
				else  -- it should not happen. If it happens, it means that the frame has been deactivated without setting last_word.
					next_state <= Transferencia;
					next_state <= Espera;
				end if;	
		end case;
	end process;

---------------------------------------------------------------------------
-- @ calculation
-- the counter counts as long as the frame is active, the address belongs to the memory and the memory is ready to perform the current operation. 
---------------------------------------------------------------------------

-- For this scheme to work, it is necessary to notify when the last word is requested. Sending it resets the burst count, so the next burst will start from the initial address.
reset_cuenta <= '1' when ((reset='1') or ((bus_last_word='1') and (mem_ready = '1'))) else '0';
cont_palabras: counter 		generic map (size => 8) port map (clk => clk, reset => reset_cuenta, count_enable => contar_palabras, count => cuenta_palabras);
-- The address is calculated by adding the word count to the initial address stored in the last_addr register.
addr_Frame <= 	last_addr + cuenta_palabras(6 downto 0);
-- we only assign the bits that are used. The rest remain at 0.
MD_addr(8 downto 2) <= 	addr_Frame; 
MD_addr(1 downto 0) <= "00";
MD_addr(31 downto 9) <= "00000000000000000000000";

---------------------------------------------------------------------------
-- Data Memory
---------------------------------------------------------------------------


MD: RAM_128_32 PORT MAP (CLK => CLK, reset => reset, enable => MD_enable, ADDR => MD_addr, Din => Bus_Data, WE =>  MEM_WE, RE => Bus_RE, Fetch_inc => Internal_Fetch_inc, mem_ready => mem_ready, Dout => MD_Dout);


end Behavioral;

