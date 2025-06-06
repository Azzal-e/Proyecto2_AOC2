----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:38:16 04/08/2014 
-- Design Name: 
-- Module Name:    
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: La memoria cache est� compuesta de 8 bloques de 4 datos con: asociatividad 2, escritura directa, y la politica convencional en fallo de escritura (fetch on write miss). 
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
use ieee.numeric_std.all; -- se usa para convertir std_logic a enteros


entity MC_datos is port (
			CLK : in std_logic;
			reset : in  STD_LOGIC;
			-- MIPS interface
			-- inputs
			ADDR : in std_logic_vector (31 downto 0); --@ 
			Din : in std_logic_vector (31 downto 0);
			RE : in std_logic;		-- read enable		
			WE : in  STD_LOGIC; 
			 -- NEW: signal for fetch_inc
		  	Fetch_inc: in std_logic;
			-- outputs
			ready : out  std_logic;  -- indicates whether we can perform the requested operation in the current cycle
			Dout : out std_logic_vector (31 downto 0); -- dato output
			-- Nueva se�al de error
			Mem_ERROR: out std_logic; -- Activated if the slave did not respond to your address during the last transfer.
			-- bus interface
			-- inputs
			MC_Bus_Din : in std_logic_vector (31 downto 0);-- to read bus data
			Bus_TRDY : in  STD_LOGIC; -- indicates that the slave (the data memory) can perform the requested operation in this cycle.
			Bus_DevSel: in  STD_LOGIC; -- indicates that the memory has recognized that the address is within its range.
			MC_Bus_Grant: in  STD_LOGIC; -- indicates that the referee allows the MC to use the bus;
			--salidas
			MC_send_addr_ctrl : out  STD_LOGIC; -- send address and control signals to the bus
			MC_send_data : out  STD_LOGIC; -- send data
			MC_frame : out  STD_LOGIC; -- indicates that the operation has not been completed
			MC_Bus_ADDR : out std_logic_vector (31 downto 0); -- @ 
			MC_Bus_data_out : out std_logic_vector (31 downto 0);-- to send data over the bus
			MC_bus_Read : out  STD_LOGIC; -- to request the bus in read access
			MC_bus_Write : out  STD_LOGIC; --  to request the bus in write access
			MC_bus_Fetch_inc : out  STD_LOGIC; --  to request the bus for a Fetch_inc
			MC_Bus_Req: out  STD_LOGIC; -- indicates that the MC wants to use the bus;
			MC_last_word : out  STD_LOGIC --indicates that is the last transfer
			 );
end MC_datos;

architecture Behavioral of MC_datos is

component UC_MC is
    Port ( 	clk : in  STD_LOGIC;
		reset : in  STD_LOGIC;
		-- MIPS requests
		RE : in  STD_LOGIC; 
		WE : in  STD_LOGIC;
		-- NEW: signal for fetch_inc
		Fetch_inc: in std_logic;
		invalidate_bit: out std_logic;
		-- Output for MIPS
		ready : out  STD_LOGIC; -- indicates whether we can perform the requested operation in the current cycle
		-- MC signals
		hit0 : in  STD_LOGIC; -- hit in way (via) 0
		hit1 : in  STD_LOGIC; -- hit in way (via) 1
		via_2_rpl :  in  STD_LOGIC; -- indicates the way (via) to replace
		addr_non_cacheable: in STD_LOGIC; -- indicates that it should not stored in MC
		internal_addr: in STD_LOGIC; -- indicates that it is an internal register and not a memory @
		MC_WE0 : out  STD_LOGIC;
        MC_WE1 : out  STD_LOGIC;
        -- Signals to indicate the operation to be performed on the bus
        MC_bus_Read : out  STD_LOGIC; -- to request the bus in read access
		MC_bus_Write : out  STD_LOGIC; --  to request the bus in write access
		MC_bus_Fetch_inc : out  STD_LOGIC; --  to request a Fetch_inc
		MC_tags_WE : out  STD_LOGIC; -- to update the tags memory 
        palabra : out  STD_LOGIC_VECTOR (1 downto 0);--indicates the current word in a block transfer (first, second...)
        mux_origen: out STD_LOGIC; -- Used to choose whether the origin of the word address and the data is the Mips (when 0) or the Control Unit (UC) or the bus (when 1).
		block_addr : out  STD_LOGIC; -- indicates whether the address to be sent is the block address or the word address 
		mux_output: out  std_logic_vector(1 downto 0); -- to choose whether to send to the processor the MC output (value 0), the data on the bus (value 1), or an internal register (value 2).
		-- MC Profiling counters
		inc_m : out STD_LOGIC; -- increment number of MC misses (only for cacheable @)
		inc_w : out STD_LOGIC; -- increment number of MC writes
		inc_r : out STD_LOGIC; -- increment number of MC reads
		-- New
		inc_inv :out STD_LOGIC; -- increment number of invalidations
		-- ETHICAL HACKING
		inc_rm : out STD_LOGIC; -- increment number of read misses
		inc_accMd : out STD_LOGIC; -- increment number of accesses to MD with MC disabled
		
		-- Error management
		unaligned: in STD_LOGIC; -- indicates that the address requested by the MIPS is not aligned.
		Mem_ERROR: out std_logic; -- Activated if the server did not respond to your address during the last transfer.
		load_addr_error: out std_logic; -- to store the @ that generated an error
		-- To manage transfers through the bus
		bus_TRDY : in  STD_LOGIC; -- indicates that the memory can perform the requested operation in this cycle
		Bus_DevSel: in  STD_LOGIC; -- indicates that the memory has recognized that the address is within its range.
		Bus_grant :  in  STD_LOGIC; -- indicates the grant of the use of the bus
		MC_send_addr_ctrl : out  STD_LOGIC; -- commands address and control signals to be sent to the bus 
        MC_send_data : out  STD_LOGIC; -- orders to send the data
        Frame : out  STD_LOGIC; -- indicates that the operation has not been completed 
        last_word : out  STD_LOGIC; -- indicates that it is the last data of the transfer.
        Bus_req :  out  STD_LOGIC; -- indicates a request to use the bus
		-- NUEVA PARA ETHICAL HACKING
		MC_desactivada: in std_logic -- Se activa cuando la memoria caché está desactivada
		);
end component;

component reg is
    generic (size: natural := 32);  -- by default are 32-bit, but any size can be used.
	Port ( Din : in  STD_LOGIC_VECTOR (size -1 downto 0);
           clk : in  STD_LOGIC;
		   reset : in  STD_LOGIC;
           load : in  STD_LOGIC;
           Dout : out  STD_LOGIC_VECTOR (size -1 downto 0));
end component;	

component counter is
 	generic (   size : integer := 10);
	Port ( clk : in  STD_LOGIC;
       reset : in  STD_LOGIC;
       count_enable : in  STD_LOGIC;
       count : out  STD_LOGIC_VECTOR (size-1 downto 0));
end component;


component Via is 
 	generic ( num_via: integer); -- is used for messages. The correct number must be entered when instantiating it.
 	port (	CLK : in std_logic;
			reset : in  STD_LOGIC;
 			Dir_word: in std_logic_vector(1 downto 0); -- is used to choose the word to be accessed in a data cache set. 
 			Dir_cjto: in std_logic_vector(1 downto 0); -- is used to choose the set
 			Tag: in std_logic_vector(25 downto 0);
 			Din : in std_logic_vector (31 downto 0);
			WE : in  STD_LOGIC; 	-- write enable	
			Tags_WE : in  STD_LOGIC; 	-- write enable for tag memory
			-- NEW: signal for fetch_inc
		  	Fetch_inc: in std_logic;
		  	invalidate_bit: in std_logic;
			hit : out STD_LOGIC; 
			Dout : out std_logic_vector (31 downto 0);			
			-- NEW: Señal para ethical hacking
			invalidar_all: in std_logic -- Se activa cuando se quiere invalidar todos los conjuntos de la cache
			) ;
end component;

component FIFO_reg is
port (
        clk : in std_logic;
		reset : in std_logic;
        cjto : in std_logic_vector (1 downto 0); --replaced set address
        new_block : in std_logic;		-- Indicates that a replacement has been done	        
        via_2_rpl : out std_logic
            );
end component;

signal dir_cjto: std_logic_vector(1 downto 0); -- to select the set
signal dir_word: std_logic_vector(1 downto 0); -- to select the word
signal mux_origen, MC_Tags_WE, block_addr, new_block: std_logic;
signal via_2_rpl, Tags_WE_via0, Tags_WE_via1,hit0, hit1, WE_via0, WE_via1: std_logic;
signal palabra_UC: std_logic_vector(1 downto 0); --  is used when bringing a new block to the MC (it changes value to bring all words).
signal MC_Din, MC_Dout, Dout_via1, Dout_via0, Addr_Error, Internal_MC_Bus_ADDR: std_logic_vector (31 downto 0);
signal Tag: std_logic_vector(25 downto 0); 
signal m_count, w_count, r_count, inv_count, rm_count, mPer_count, accMD_count,  m_count_mirror, w_count_mirror, r_count_mirror, inv_count_mirror : std_logic_vector(7 downto 0); -- MODIFICADO CON SEÑALES DE CONTADORES PARA ETHICAL HACKING
signal inc_m, inc_w, inc_r, inc_inv, inc_rm, inc_accMd : std_logic;
signal addr_non_cacheable, internal_addr, load_addr_error, unaligned, Mem_ready : std_logic;
signal mux_output: std_logic_vector(1 downto 0); 
signal invalidate_bit: STD_LOGIC; -- To invalidate the block after a fetch_inc
signal mayor_25, accMd_mayor_15: std_logic; -- To indicate that the number of read misses is greater than 25.
signal mc_ineficiente: std_logic_VECTOR(0 downto 0); -- Para indicar cache ineficiente
signal reset_mPer, reset_cont_accMd: std_logic; -- Para reseteos tras cambios de estado
signal cambiar_Estado_cache: std_logic; -- Para indicar que se debe cambiar el estado de la cache (ACTIVADA o DESACTIVADA)
signal MC_desactivada: std_logic_vector(0 downto 0); -- Para indicar que la cache esta desactivada
signal invalidar_all: std_logic; -- Se activa cuando se quiere invalidar todos los conjuntos de la cache
signal MC_desactivada_logical: std_logic; -- Para indicar que la cache esta desactivada
signal enable_cont_m, enable_cont_w, enable_cont_r, enable_cont_inv: std_logic; -- Se activan cuando la cache esta activada y se quiere contar los accesos a MD
begin
 -------------------------------------------------------------------------------------------------- 
 -- MC_data: RAM memory that stores 8 blocks of 4 data 
 -- dir palabra: can come from the input (when searching for data requested by the Mips) or from the Control Unit, CU, (when a new block is being written).  
 -------------------------------------------------------------------------------------------------- 
 -- the region beginning with �00010000000000000000000� is defined as non-cacheable.
 -- Addresses in that region are sent to the MD_scratch and when it responds the result is forwarded to the processor. 
 -- Never store anything from that interval in MC
 
 addr_non_cacheable <= '1' when Addr(31 downto 8) = x"100000" else '0';
 unaligned <= '1' when Addr(1 downto 0) /= "00" else '0';
 tag <= ADDR(31 downto 6); 
 dir_word <= ADDR(3 downto 2) when (mux_origen='0') else palabra_UC;
 dir_cjto <= ADDR(5 downto 4); -- associative placement (two-ways)
 -- MC data input can come from the Mips (normal access) or from the bus (MC miss).
 MC_Din <= Din when (mux_origen='0') else MC_bus_Din;

Via_0: Via generic map (num_via => 0)PORT MAP(clk => clk, reset => reset, WE => WE_via0, Tags_WE => Tags_WE_via0, hit => hit0, Dir_cjto => Dir_cjto, Dir_word => Dir_word, Tag => Tag, Din => MC_Din, Dout => Dout_via0,
											  Fetch_inc => Fetch_inc, invalidate_bit => invalidate_bit, invalidar_all => invalidar_all);

Via_1: Via generic map (num_via => 1)PORT MAP(clk => clk, reset => reset, WE => WE_via1, Tags_WE => Tags_WE_via1, hit => hit1, Dir_cjto => Dir_cjto, Dir_word => Dir_word, Tag => Tag, Din => MC_Din, Dout => Dout_via1,
											  Fetch_inc => Fetch_inc, invalidate_bit => invalidate_bit, invalidar_all => invalidar_all);

-- We choose between the output of the two ways. We choose the output of the way 1 if there is a hit in way 1, else, way 0 is selected
MC_Dout <= Dout_via1 when (hit1='1')  else Dout_via0;

new_block <= MC_Tags_WE; -- The info for fifo is updated every time a new tag is written

Info_FIFO: FIFO_reg PORT MAP(clk => clk, reset => reset, cjto => dir_cjto, new_block => new_block, via_2_rpl => via_2_rpl);

-- choose on which way to write the new tag as indicated by via_2_rpl
Tags_WE_via0 <= MC_Tags_WE and not(via_2_rpl);
Tags_WE_via1 <= MC_Tags_WE and via_2_rpl;

-------------------------------------------------------------------------------------------------- 
-----MC_UC: control unit
-------------------------------------------------------------------------------------------------- 
Unidad_Control: UC_MC port map (	clk => clk, reset=> reset, RE => RE, WE => WE, hit0 => hit0, hit1 => hit1, bus_TRDY => bus_TRDY, 
									bus_DevSel => bus_DevSel, MC_WE0 => WE_via0, MC_WE1 => WE_via1, 
									MC_bus_Read => MC_bus_Read, MC_bus_Write => MC_bus_Write, MC_bus_Fetch_inc => MC_bus_Fetch_inc, 
									MC_tags_WE=> MC_tags_WE, palabra => palabra_UC, mux_origen => mux_origen, ready => Mem_ready, MC_send_addr_ctrl=> MC_send_addr_ctrl, 
									block_addr => block_addr, MC_send_data => MC_send_data, Frame => MC_Frame, via_2_rpl => via_2_rpl, last_word => MC_last_word,
									addr_non_cacheable => addr_non_cacheable, mux_output=> mux_output, Bus_grant => MC_Bus_grant, Bus_req => MC_Bus_req,
									internal_addr => internal_addr, unaligned => unaligned, Mem_ERROR => Mem_ERROR, inc_m => inc_m, inc_w => inc_w, 
									inc_r => inc_r, inc_inv => inc_inv, inc_rm => inc_rm,inc_accMd =>inc_accMd, load_addr_error => load_addr_error, Fetch_inc => Fetch_inc, invalidate_bit => invalidate_bit, MC_desactivada => MC_desactivada_logical);  
--------------------------------------------------------------------------------------------------
----------- Event counters
-------------------------------------------------------------------------------------------------- 
cont_m: counter generic map (size => 8)
		port map (clk => clk, reset => reset, count_enable => enable_cont_m, count => m_count);
enable_cont_m <= '1' when (MC_desactivada = "0" and inc_m = '1') else '0'; -- Se activan los contadores cuando la cache esta activada
cont_w: counter generic map (size => 8)
		port map (clk => clk, reset => reset, count_enable => enable_cont_w, count => w_count);
enable_cont_w <= '1' when (MC_desactivada = "0" and inc_w = '1') else '0'; -- Se activan los contadores cuando la cache esta activada
cont_r: counter generic map (size => 8)
		port map (clk => clk, reset => reset, count_enable => enable_cont_r, count => r_count);
enable_cont_r <= '1' when (MC_desactivada = "0" and inc_r = '1') else '0'; -- Se activan los contadores cuando la cache esta activada
cont_inv: counter generic map (size => 8)
		port map (clk => clk, reset => reset, count_enable => enable_cont_inv, count => inv_count);
enable_cont_inv <= '1' when (MC_desactivada = "0" and inc_inv = '1') else '0'; -- Se activan los contadores cuando la cache esta activada

--------------------------------------------------------------------------------------------------
-- ELEMENTOS ADICIONALES PARA ETHICAL HACKING
-------------------------------------------------------------------------------------------------- 
-- Contadores "mirrors" para contar siempre. Los contadores originales sirven para conteo "oficial" (solo con cache activada)
cont_m_mirror: counter generic map (size => 8)
		port map (clk => clk, reset => reset, count_enable => inc_m, count => m_count_mirror);
cont_w_mirror: counter generic map (size => 8)
		port map (clk => clk, reset => reset, count_enable => inc_w, count => w_count_mirror);
cont_r_mirror: counter generic map (size => 8)
		port map (clk => clk, reset => reset, count_enable => inc_r, count => r_count_mirror);
cont_inv_mirror: counter generic map (size => 8)
		port map (clk => clk, reset => reset, count_enable => inc_inv, count => inv_count_mirror);



cont_readMisses: counter generic map (size => 8) -- Cuenta fallos en lectura
		port map (clk => clk, reset => reset, count_enable => inc_rm, count => rm_count);
-- Señal que se activa cuando  el número de misses es mayor que 25 desde que se accedió a este estado es mayor que 25.

mayor_25 <= '1' when (mPer_count > x"19") else '0'; 

-- Contador de misses periódico (se resetea cada vez que se vuelve a ciclo normal):
cont_mPer: counter generic map (size => 8)
		port map (clk => clk, reset => reset_mPer, count_enable => inc_m, count => mPer_count);

reset_mPer <= '1' when (cambiar_Estado_cache = '1' and MC_desactivada="1") or reset = '1' else '0'; -- Se resetea el contador de misses cada vez que se vuelve a activar la MC

-- Contador de accesos a MD con MC desactivada
cont_accMDBruto: counter generic map (size => 8)
		port map (clk => clk, reset => reset_cont_accMD, count_enable => inc_accMd, count => accMD_count);
accMd_mayor_15 <= '1' when (accMD_count > x"0F") else '0'; -- Se activa cuando el número de accesos a MD con MC invalidada es mayor a 15

reset_cont_accMD <= '1' when (cambiar_Estado_cache = '1' and MC_desactivada="0") or reset = '1' else '0'; -- Se resetea el contador de accesos a MD cada vez que se vuelve a activar la MC
-- Señal que se activa cuando la MC es está por debajo del umbral de eficiencia

mc_ineficiente <= "1" when unsigned(m_count_mirror) > 
    ( (unsigned(r_count_mirror) - unsigned(rm_count)) * 115) / 100 else "0";

-- Señal para gestionar un cambio de estado retardado
cambiar_Estado_cache <= '1' when ((MC_desactivada = "0" and mc_ineficiente = "1" and mayor_25 = '1') or (MC_desactivada = "1" and mc_ineficiente = "0" and accMd_mayor_15 = '1')) and (mem_ready = '1') else '0'; -- Se espera a que el acceso a memoria se termine con mem_ready = '1' para evitar transiciones en medio de transferencias.

-- Registro con el estado de la cache
Estado_cache: reg generic map (size => 1)
					port map (	Din => mc_ineficiente, clk => clk, reset => reset, load => cambiar_Estado_Cache, Dout => MC_desactivada);
MC_desactivada_logical <= MC_desactivada(0); -- Se usa para indicar que la cache esta desactivada
-- Señal para invalidar todos los bloques de la cache mientras cuando vuelva a activarse -> resultado del set duelling
invalidar_all <= '1' when (cambiar_Estado_cache = '1' and MC_desactivada="1") else '0'; -- Se activa cuando se vuelve a activar la MC



--------------------------------------------------------------------------------------------------
----------- Bus outputs
-------------------------------------------------------------------------------------------------- 
-- If it is a write, the address of the word is sent, and if it is a miss, the address of the block that caused the miss.
Internal_MC_Bus_ADDR <= 	ADDR(31 downto 2)&"00" when block_addr ='0' else 
							ADDR(31 downto 4)&"0000"; 
-- the �internal� signal is used to read it, because MC_Bus_ADDR is an output signal and cannot be read.
MC_Bus_ADDR <= Internal_MC_Bus_ADDR;
									 
MC_Bus_data_out <= 	Din when (addr_non_cacheable = '1' or MC_desactivada = "1") else -- NUEVO!! AHORA NO SE PUEDE ESCRIBIR SIEMPRE EN CACHE
					MC_Dout; -- is used to send the data to be written

--------------------------------------------------------------------------------------------------
-- Addr Error register
-- When a memory access error occurs (because the requested address does not correspond to anyone) the address is stored in this register
-- Its associated address is �01000000�
--------------------------------------------------------------------------------------------------
ADDR_Error_Reg: reg generic map (size => 32)
					port map (	Din => Internal_MC_Bus_ADDR, clk => clk, reset => reset, load => load_addr_error, Dout => Addr_Error);
--------------------------------------------------------------------------------------------------
-- Decoder to detect if the signal is internal. That is, if it belongs to an MC register.
Internal_addr <= '1' when (ADDR(31 downto 0) = x"01000000") else '0'; 

--------------------------------------------------------------------------------------------------
----------- Mips outputs
-------------------------------------------------------------------------------------------------- 
Dout <= MC_Dout when mux_output ="00" else 
		MC_bus_Din when mux_output ="01" else -- is used to send the data that has arrived on the bus directly to Mips
		Addr_Error when mux_output ="10" else -- is used to send to the Mips the content of the Addr_Error register
		x"00000000";

ready <= Mem_ready;		
		
end Behavioral;
