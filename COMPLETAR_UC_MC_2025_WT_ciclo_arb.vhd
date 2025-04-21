---------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:38:18 05/15/2014 
-- Design Name: 
-- Module Name:    UC_slave - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: la UC incluye un contador de 2 bits para llevar la cuenta de las transferencias de bloque y una m�quina de estados
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

entity UC_MC is
    Port ( 	
        clk : in  STD_LOGIC;
		reset : in  STD_LOGIC;
		
		-- MIPS instructions
		RE : in  STD_LOGIC; 
		WE : in  STD_LOGIC;
		
		-- NEW: signal for fetch_inc
		Fetch_inc: in std_logic;
		invalidate_bit: out std_logic;
		
		-- Response to MIPS
		ready : out  STD_LOGIC; -- indicates whether we can process the current MIPS instruction in this cycle. Otherwise, the MIPS will have to be stalled.
		
		-- Signals from the Cache Memory (MC)
		hit0 : in  STD_LOGIC; -- activated if there is a hit in way 0
		hit1 : in  STD_LOGIC; -- activated if there is a hit in way 1
		via_2_rpl :  in  STD_LOGIC; -- indicates which way will be replaced
		addr_non_cacheable: in STD_LOGIC; -- indicates that the address should not be stored in the cache (e.g., belongs to scratchpad)
		internal_addr: in STD_LOGIC; -- indicates that the requested address refers to an internal MC register

		MC_WE0 : out  STD_LOGIC;
        MC_WE1 : out  STD_LOGIC;
        
        -- Signals to indicate the operation to be performed on the bus
        MC_bus_Read : out  STD_LOGIC; -- to request the bus for a read access
		MC_bus_Write : out  STD_LOGIC; -- to request the bus for a write access
		MC_bus_Fetch_inc : out  STD_LOGIC; -- to request the bus for a Fetch_inc operation
		MC_tags_WE : out  STD_LOGIC; -- to write the tag into the tag memory

        palabra : out  STD_LOGIC_VECTOR (1 downto 0); -- indicates the current word within a block transfer (1st, 2nd, etc.)

        mux_origen: out STD_LOGIC; -- used to select whether the source of the address and data is the MIPS (when 0) or the controller and bus (when 1)
		block_addr : out  STD_LOGIC; -- indicates whether the address to send is a block address (rm) or a word address (w)
		mux_output: out  std_logic_vector(1 downto 0); -- to select whether to send the output from the cache (value 0), the data on the bus (value 1), or an internal register (value 2)

		-- Performance counters for the Cache Memory
		inc_m : out STD_LOGIC; -- indicates a miss occurred in cache
		inc_w : out STD_LOGIC; -- indicates a write occurred in cache
		inc_r : out STD_LOGIC; -- indicates a read occurred in cache
		inc_inv :out STD_LOGIC; -- indica que ha habido una invalidaci�n

		-- Error management
		unaligned: in STD_LOGIC; -- indicates the address requested by MIPS is not aligned
		Mem_ERROR: out std_logic; -- activated if in the last transfer the slave did not respond to its address
		load_addr_error: out std_logic; -- used to record the address that caused an error

		-- Bus transfer management
		bus_TRDY : in  STD_LOGIC; -- indicates that the memory can perform the requested operation in this cycle
		Bus_DevSel: in  STD_LOGIC; -- indicates that the memory has acknowledged the address as within its range
		Bus_grant :  in  STD_LOGIC; -- indicates bus usage has been granted
		MC_send_addr_ctrl : out  STD_LOGIC; -- commands sending the address and control signals to the bus
        MC_send_data : out  STD_LOGIC; -- commands sending data
        Frame : out  STD_LOGIC; -- indicates that the operation is not yet complete
        last_word : out  STD_LOGIC; -- indicates that this is the last data of the transfer
        Bus_req :  out  STD_LOGIC -- indicates a bus request to the arbiter
	);
end UC_MC;


architecture Behavioral of UC_MC is
 
component counter is 
	generic (
	   size : integer := 10
	);
	Port ( clk : in  STD_LOGIC;
	       reset : in  STD_LOGIC;
	       count_enable : in  STD_LOGIC;
	       count : out  STD_LOGIC_VECTOR (size-1 downto 0)
					  );
end component;		           
-- Examples of state names. Name your states with descriptive names, either one of these, or others. This makes debugging easier. Remove unused names
type state_type is (Inicio, single_word_transfer_addr, read_block, fetch_inc_transfer, single_word_transfer_data, block_transfer_addr, block_transfer_data, Send_Addr, fallo, bring_block_data, send_single_word_data, bring_single_word_data); 
type error_type is (memory_error, No_error); 
signal state, next_state : state_type; 
signal error_state, next_error_state : error_type; 
signal last_word_block: STD_LOGIC; -- is activated when the last word of a block is being requested.
signal count_enable: STD_LOGIC; -- Increments the word counter. It is activated when a new word has been received
signal hit: std_logic;
signal palabra_UC : STD_LOGIC_VECTOR (1 downto 0);
begin

hit <= hit0 or hit1;	
 
-- The counter reports how many words have been received. It is used to know when the block transfer is finished and to generate the address of the word in which the data read from the bus is written in the MC.
word_counter: counter 	generic map (size => 2)
						port map (clk, reset, count_enable, palabra_UC); -- indicates the current word within a block transfer (1st, 2nd...)

last_word_block <= '1' when palabra_UC="11" else '0';-- is activated when we are asking for the last transfer

palabra <= palabra_UC;

   State_reg: process (clk)
   begin
      if (clk'event and clk = '1') then
         if (reset = '1') then
            state <= Inicio;
         else
            state <= next_state;
         end if;        
      end if;
   end process;
 
---------------------------------------------------------------------------
-- State machine for the error bit
---------------------------------------------------------------------------

error_reg: process (clk)
   begin
      if (clk'event and clk = '1') then
         if (reset = '1') then           
            error_state <= No_error;
        else
            error_state <= next_error_state;
         end if;   
      end if;
   end process;
   
--Mem Error output
Mem_ERROR <= '1' when (error_state = memory_error) else '0';

--Mealy State-Machine - Outputs based on state and inputs
   
   --MEALY State-Machine - Outputs based on state and inputs
   -- Important: check that the signals used as inputs are included in the sensitivity list
   OUTPUT_DECODE: process (state, error_state, RE, WE, Fetch_inc, unaligned, internal_addr, Bus_grant, hit, addr_non_cacheable, Bus_DevSel, hit0, hit1, bus_TRDY, via_2_rpl, last_word_block)
   begin
			  -- default values, if no other value is assigned in a state these are the defaut values
	MC_WE0 <= '0';
	MC_WE1 <= '0';
	MC_bus_Read <= '0';
	MC_bus_Write <= '0';
	MC_bus_Fetch_inc <= '0';
	MC_tags_WE <= '0';
    ready <= '0';
    mux_origen <= '0';
    MC_send_addr_ctrl <= '0';
    MC_send_data <= '0';
    next_state <= state;  
	count_enable <= '0';
	Frame <= '0';
	block_addr <= '0';
	inc_m <= '0';
	inc_w <= '0';
	inc_r <= '0';
	inc_inv <= '0';
	Bus_req <= '0';
	mux_output <= "00";
	last_word <= '0';
	next_error_state <= error_state; 
	load_addr_error <= '0';
	invalidate_bit <= '0';
				
        -- Inicio state          
    CASE state is 
		when Inicio => 
			If (RE = '0' and WE = '0' and Fetch_inc = '0') then -- if Mips ask for nothing, we do nothing
				next_state <= Inicio;
				ready <= '1';
			elsif ((RE = '1') or (WE = '1') or (Fetch_inc = '1')) and  (unaligned ='1') then -- if the processor wants to read an unaligned address
				-- The error is processed and the request is ignored.
				next_state <= Inicio;
				ready <= '1';
				next_error_state <= memory_error; -- last address incorrect (not aligned)
				load_addr_error <= '1';
			elsif (RE= '1' and  internal_addr ='1') then -- if Mips wants to read an MC internal register
				next_state <= Inicio;
				ready <= '1';
				mux_output <= "10"; -- The output is an internal MC record
				next_error_state <= No_error; -- When the internal register is read, the controller removes the error signal.
			elsif (((WE = '1') or (Fetch_inc = '1')) and  internal_addr ='1') then -- if you want to write or fetch_inc to the internal MC register, an error is generated because it is read-only.
				next_state <= Inicio;
				ready <= '1';
				next_error_state <= memory_error; -- Attempt to write a read-only internal register
				load_addr_error <= '1';
			--elsif (Fetch_inc= '1') then -- fetch_inc 
			-- EL MIPS SOLO LEVANTA LA SEÑAL FETCH_INC PARA EL CASO DE LW_INC, NO RE
			-- TODO ZANOS <CASO EN EL QUE VAS A INTERACCIONAR CON EL BUS>
			elsif ((((RE = '1' and hit = '0') or (Fetch_inc = '1') or (WE = '1')) AND addr_non_cacheable = '0') OR (((RE = '1') or (Fetch_inc = '1') or (WE = '1')) and addr_non_cacheable = '1')) then -- si involucra alguna operación que tenga que hacer uso del bus
				Bus_req <= '1'; 
				if(Bus_grant = '1') then -- Bus_grant puede ser levantado en el mismo ciclo
					if ( (RE = '1' or WE = '1') and hit = '0' and addr_non_cacheable = '0'  ) then -- CASO de miss: Se debe traer un BLOQUE (lw_inc tiene tratamiento especial, de ahí que no se incluya)
						next_state <= block_transfer_addr;
					else  -- En otro caso, será una tranferencia de palabra, bien sea con MD_scratch o con MD (y lectura o escritura)
						next_state <= single_word_transfer_addr;
					end if;
				else -- Si el árbitro no ha concedido permiso para emplear el bus, se sigue esperando a que lo haga (nótese que seguirá cumpliendo la misma cláusula inicial al permanecer mem_ready bajado)
					next_state <= Inicio;
				end if;
			elsif (RE= '1' and  hit='1') then -- read hit
				-- ORDER MATTERS: IF THIS OPTION GOES BEFORE fetch_inc if fetch_inc and RE are activated it would be treated as RE. It depends on how the fetch_inc signals are handled, this may or may not happen.
				next_state <= Inicio;
				ready <= '1';
				inc_r <= '1'; -- MC read
				mux_output <= "00"; -- This is the default value. There is no need to set it. The output is a data stored in the MC
			--elsif (WE= '1' and  hit='1') then -- write hit
			---COMPLETE:
				
			--elsif (hit='0') then  -- if the MIPS asks for a well aligned memory @ and it is not a hit or access to a register
				--COMPLETE:
			end if;
	-- COMPLETE  
		when single_word_transfer_addr =>
			Frame <= '1'; -- Ya ha comenzado la transferencia en el bus, debe estar levantado hasta que termine (se vuelva a estado inicial)
			MC_send_addr_control <= '1';
			mux_origen <= '0'; -- El origen del dato es del MIPS
			block_addr <= '0'; -- TRANSFERENCIA DE PALABRA

			-- SEÑAL DE OPERACIÓN
			if (RE = '1' or (lw_inc = '1' and addr_non_cacheable = '0')) then -- El lw_inc no está soportado por la memoria de datos scratch, por lo que se trata como un lw normal
				MC_bus_read <= '1';
			elsif (WE = '1') then -- operacion de escritura
				MC_bus_write <= '1';
			else -- operación lw_inc sobre MD
				MC_bus_Fetch_inc <= '1';
			end if;


			-- RECUÉRDESE QUE  DEVSEL SE LEVANTA COMBINACIONALMENTE, POR LO QUE HAY QUE COMPROBAR EN EL MISMO CICLO
			if (Bus_DevSel = '0') then -- Ningún dispositivo reconoce la dirección -> ERROR
				ready <= '1'; -- Se comunica al mips que puede continuar (es probable que suceda una excepción que termina con la ejecución, pero nótese que las excepciones no pueden darse si el MIPS está completamente parado)
				load_addr_error <= '1'; -- Recoger en ADDR_ERROR_REG la dirección problemática
				next_state <= Inicio;
				next_error_state <= memory_error;
			else -- Dirección reconocida, pasa al estado de enviar o traer una sola palabra
				if (WE = '1' and addr_non_cacheable = '1') then -- Escritura sobre MD_scratch
					next_state <= send_single_word_data;
				elsif (WE = '1' and hit = '1' and addr_non_cacheable = '0') then-- CASO DE ESCRITURA SOBRE MD : WRITE THROUGH
				-- A nivel de transferencia en el bus idéntico a MD_scratch, pero se debe asimismo escribir la palabra en la memoria caché
					next_state <= send_single_word_data;
					inc_w  <= '1'; -- Se escribe sobre memoria cache
					-- Nótese que no estarán ambos activados, tan solo sobre el que se escriba
					MC_WE0 <= hit0;
					MC_WE1 <= hit1;
				elsif ( ((RE = '1' OR Fetch_inc = '1') AND addr_non_cacheable = '1') OR (Fetch_inc = '1' and hit = '0' and addr_non_cacheable = '0')) then -- caso de lectura sobre MD_scratch o lw_inc sobre MD que que no necesita invalidar MC
					next_state <= bring_single_word_data;
				elsif (Fetch_inc = '1' and hit = '1' and addr_non_cacheable = '0') then -- caso de lw_inc sobre MD que da hit en la cache: HAY QUE INVALIDAR
					-- Como el lw_inc invalida el bloque en la cache al modificar internamente el MD y generar una inconsistencia
					-- se decide tratarlo de forma independiente a la cache en caso de miss (no tiene sentido cargar el bloque para posteriormente invalidarlo),
					-- pero en caso de  hit se debe invalidar el bloque para reflejar esta disparidad
					next_state <= bring_single_word_data;
					inc_inv <= '1';
					invalidate_bit <= '1';
				else -- CÓDIGO INALCANZABLE
					next_state <= Inicio;
				end if;
			end if;

		when block_transfer_addr =>
			-- Nótese que en el presente caso una transferencia de bloque siempre corresponderá a una lectura de bloque para cargarlo en la cache -> MISS

			Frame  <= '1';
			MC_send_addr_ctrl <= '1';
			MC_bus_read <= '1'; -- Siempre será operación de lectura de bloque
			block_addr <= '1'; -- TRANSFERENCIA DE BLOQUE

			-- RECUÉRDESE QUE  DEVSEL SE LEVANTA COMBINACIONALMENTE, POR LO QUE HAY QUE COMPROBAR EN EL MISMO CICLO
			if (Bus_DevSel = '0') then -- Ningún dispositivo reconoce la dirección -> ERROR
				ready <= '1'; -- Se comunica al mips que puede continuar (es probable que suceda una excepción que termina con la ejecución, pero nótese que las excepciones no pueden darse si el MIPS está completamente parado)
				load_addr_error <= '1'; -- Recoger en ADDR_ERROR_REG la dirección problemática
				next_state <= Inicio;
				next_error_state <= memory_error;
			else -- Se procede a una transferencia de bloque
				inc_m <= '1'; -- Se incrementa el número de misses
				MC_tags_WE <= '1'; -- Se sobreescribe el tag de la caché con el del nuevo bloque a cargar (indistintamente se puede realizar al final de la operación)
				next_state <= bring_block_data; 
			end if;

		when send_single_word_data =>
			-- Caso de envio de una sola palabra en el bus. Independientemente de que sea sobre la MD o MD_scratch, la propia gestión de la transferencia en el bus es idéntica
			Frame <= '1';
			MC_send_data <= '1'; -- Bus multiplexado. El master debe indicar que se están transfiriendo datos
			mux_origen <= '0'; -- Solo se transfiere una palabra, la cual además siempre viene del MIPS

			-- TODO ZANOS ESTO MIRAR
			last_word <= '1';

			if (bus_TRDY = '0') then -- La MD o MD_scratch no han podido efectuar la escritura de la palabra en el presente ciclo
				next_state <= send_single_word_data;
			else -- Solo había una palabra por transferir, por lo que la transferencia ha terminado
				ready <= '1'; -- Se comunica al procesador que se ha procesado su petición en el siguiente ciclo
				--last_word <= '1'; -- La MD (en su caso) debe saber que esta era la última (además de única) palabra para volver al estado de espera
				next_state <= Inicio;
			end if;

		when bring_single_word_data =>
			-- Caso de traer a MIPS una sola palabra del bus.
			Frame <= '1';

			-- TODO ZANOS ESTO MIRAR
			last_word <= '1';
			
			if (bus_TRDY = '0') then -- La MD o MD_scratch no han podido efectuar la lectura de la palabra en el presente ciclo
				next_state <= bring_single_word_data;
			else -- Solo había una palabra por transferir, por lo que la transferencia ha terminado
				ready <= '1'; -- Se comunica al procesador que se ha procesado su petición en el siguiente ciclo
				--last_word <= '1'; -- La MD (en su caso) debe saber que esta era la última (además de única) palabra para volver al estado de espera
				mux_output  <= "01"; -- Siempre se envía la palabra procedente del bus
				next_state <= Inicio;
			end if;

		when bring_block_data =>
			-- Caso de lectura de bloque por la Cache, siempre de MD
			Frame <= '1';
			mux_origen <= '1'; -- -- La dirección procede de la MC, que es la que itera en el bloque
			last_word <=  last_word_block;

			if (Bus_TRDY = '0') then -- MD no ha podido enviar la palabra requerida en el presente ciclo
				next_state <= bring_block_data;
			elsif (Bus_TRDY = '1' and last_word_block = '0') then -- Se ha recibido una nueva palabra, pero esta no es la última del bloque
				inc_w <= '1'; -- Nueva escritura sobre MC
				count_enable <= '1'; -- Se avanza a nueva palabra de bloque
				next_state <= bring_block_data;
				if (via_2_rpl = '1') then -- Sustituir via 1
					MC_WE1 <= '1';
				else
					MC_WE0 <= '1';
				end if;
			elsif (Bus_TRDY = '1' and last_word_block = '1') then -- Caso en el que se ha traido la última palabra del bloque
				inc_w <= '1'; -- Nueva escritura sobre MC
				count_enable <= '1'; -- Se avanza a nueva palabra de bloque (reseteo)
				ready <= '0'; -- En ningún caso se debe indicar a MIPS que la operación a terminado.
							  -- En caso de RE, se volverá al estado inicial y allí se producirá el hit
							  -- En caso de WE, se procede a llevar a cabo la escritura de palabra WRITE THROUGH

				if (via_2_rpl = '1') then -- Sustituir via 1 
					MC_WE1 <= '1';
				else
					MC_WE0 <= '1';
				end if;

				if (RE = '1') then -- Si es lw, se vuelve al inicio para que se produzca el hit y se devuelva la palabra al MIPS
					next_state <= Inicio;
				else -- En caso de sw, se inicia una nueva transferencia de palabra para el caso write-through (ahora con hit = 1)
					-- Nótese que podría volverse al estado de inicio, pero eso podría generar interferencias con el sistema IO/MD
					next_state <= single_word_transfer_addr; -- Como last_word = 1 y MD ha efectuado el envío de la última palabra, el controlador de la MD la llevará a estado de espera para aceptar una nueva transferencia.
				end if;
			end if;
	WHEN others => 
	end CASE;
		
   end process;
 
   
end Behavioral;

