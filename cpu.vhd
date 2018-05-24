library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;
use work.States.all;

entity cpu is 
   port(
    reset :	 in   STD_LOGIC; 
    sw0 :	 in   STD_LOGIC;
   	start :	 in   STD_LOGIC;
	clk :	 in   STD_LOGIC;
	output1: out STd_logic_vector(6 downto 0);
	output2: out STd_logic_vector(6 downto 0);
	output3: out STd_logic_vector(6 downto 0);
	output4: out STd_logic_vector(6 downto 0);
	output5: out STd_logic_vector(6 downto 0);
	output6: out STd_logic_vector(6 downto 0);
	test0: out STd_logic;
	test1: out STd_logic;
	Z: out STd_logic
       );
end cpu;

architecture behavioral of cpu is

function convSEG (N : std_logic_vector(3 downto 0) ) return std_logic_vector is
variable ans:std_logic_vector(6 downto 0);
begin
Case N is
when "0000" => ans:="1000000";
when "0001" => ans:="1111001";
when "0010" => ans:="0100100";
when "0011" => ans:="0110000";
when "0100" => ans:="0011001";
when "0101" => ans:="0010010";
when "0110" => ans:="0000010";
when "0111" => ans:="1111000";
when "1000" => ans:="0000000";
when "1001" => ans:="0010000";
when "1010" => ans:="0001000";
when "1011" => ans:="0000011";
when "1100" => ans:="1000110";
when "1101" => ans:="0100001";
when "1110" => ans:="0000110";
when "1111" => ans:="0001110";
when others=> ans:="1111111";
end case;
return ans;
end function convSEG;

type MEMtype is array (0 to 2**16-1) of std_logic_vector(7 downto 0);
constant ROM : MEMtype := (
"00001011",
"00000001",
"00000000",
"00100000",
"00000011",
"00000001",
"00000000",
"00100001",
"00001000",
"00000111",
"00000000",
"00010000",
"00001100",
"00000101",
"00000000",
"00010010",
"00001001",
"00000000",
"00000000",
"00000000",
"00000000",
"00000000",
"00000000",
"00000000",
"00000000",
"00000000",
"00000000",
"00000000",
"00000000",
"00000000",
"00000000",
"00000000",
"00000101",
"00001010",
others => "00000000" );

signal P_S : myState;  
signal N_S : myState;
signal AR_REGISTER  :STd_logic_vector(15 downto 0);
signal AC_REGISTER  :STd_logic_vector(7 downto 0);
signal IR_REGISTER  :STd_logic_vector(7 downto 0);
signal PC_REGISTER  :STd_logic_vector(15 downto 0);
signal R_REGISTER  :STd_logic_vector(7 downto 0);
signal TR_REGISTER  :STd_logic_vector(7 downto 0);
signal Z_FLAG  :STd_logic;
signal DR_REGISTER  :STd_logic_vector(7 downto 0);
signal RAM  :MEMtype;
signal Delay_count : integer := 0;
signal en : STd_logic := '0';
signal temp : STd_logic_vector(1 downto 0);
signal Mem_count : integer := 0;

begin
	--FSM structure process
	process(clk , reset)
	begin 
		if (reset = '0') then
			P_S <= RESET1;
		elsif (rising_edge(clk)) then
			P_S <= N_S;
		end if;
	end process;
	
	--FSM transport process
	process(P_S , IR_REGISTER, Z_FLAG, start, en, Mem_count)
	begin
		N_S <= P_S;
		case P_S is
			when RESET1 =>
				N_S <= MEM_INIT;
				temp  <= "00";
			when MEM_INIT =>
				if (Mem_count = 2**16-1) then
					N_S <= FINISH; 
			 	end if;
				temp  <= "01";
			when FINISH =>
				if (start = '0') then
				N_S <= FETCH1;
				end if;
				temp  <= "10";
			when FETCH1 =>
				if( en = '1' )then
				N_S <= FETCH2;	
				end if;
				temp  <= "11";
			when FETCH2 =>
				if( en = '1' )then
				N_S <= FETCH3;			
				end if;
				temp  <= "00";
			when FETCH3 =>
				if( en = '1' )then
				if (IR_REGISTER="00000000") then
					N_S <= NOP1;
				elsif (IR_REGISTER="00000001") then
					N_S <= LDAC1;
				elsif (IR_REGISTER="00000010") then
					N_S <= STAC1;
				elsif (IR_REGISTER="00000011") then
					N_S <= MVAC1;
				elsif (IR_REGISTER="00000100") then
					N_S <= MOVR1;
				elsif (IR_REGISTER="00000101") then
					N_S <= JUMP1;
				elsif (IR_REGISTER="00000110" AND Z_FLAG='1') then
					N_S <= JMPZY1;
				elsif (IR_REGISTER="00000110" AND Z_FLAG='0') then
					N_S <= JMPZN1;
				elsif (IR_REGISTER="00000111" AND Z_FLAG='0') then
					N_S <= JPNZY1;
				elsif (IR_REGISTER="00000111" AND Z_FLAG='1') then
					N_S <= JPNZN1;
				elsif (IR_REGISTER="00001000") then
					N_S <= ADD1;
				elsif (IR_REGISTER="00001001") then
					N_S <= SUB1;
				elsif (IR_REGISTER="00001010") then
					N_S <= INAC1;
				elsif (IR_REGISTER="00001011") then
					N_S <= CLAC1;
				elsif (IR_REGISTER="00001100") then
					N_S <= AND1;
				elsif (IR_REGISTER="00001101") then
					N_S <= OR1;
				elsif (IR_REGISTER="00001110") then
					N_S <= XOR1;
				elsif (IR_REGISTER="00001111") then
					N_S <= NOT1;
				end if;
				end if;
						
			when NOP1  =>
				if( en = '1' )then
				N_S <= FETCH1;
				end if;
			when LDAC1  =>
				if( en = '1' )then
				N_S <= LDAC2;
				end if;
			when LDAC2  =>
				if( en = '1' )then
				N_S <= LDAC3;
				end if;
			when LDAC3  =>
				if( en = '1' )then
				N_S <= LDAC4;
				end if;
			when LDAC4  =>
				if( en = '1' )then
				N_S <= LDAC5;
				end if;
			when LDAC5  =>
				if( en = '1' )then
				N_S <= FETCH1;
				end if;
			when STAC1  =>
				if( en = '1' )then
				N_S <= STAC2;
				end if;
			when STAC2  =>
				if( en = '1' )then
				N_S <= STAC3;
				end if;
			when STAC3  =>
				if( en = '1' )then
				N_S <= STAC4;
				end if;
			when STAC4  =>
				if( en = '1' )then
				N_S <= STAC5;
				end if;
			when STAC5  =>
				if( en = '1' )then
				N_S <= FETCH1;
				end if;
			when MVAC1  =>
				if( en = '1' )then
				N_S <= FETCH1;
				end if;
			when MOVR1  =>
				if( en = '1' )then
				N_S <= FETCH1;
				end if;
			when JUMP1  =>
				if( en = '1' )then
				N_S <= JUMP2;
				end if;
			when JUMP2  =>
				if( en = '1' )then
				N_S <= JUMP3;
				end if;
			when JUMP3  =>
				if( en = '1' )then
				N_S <= FETCH1;
				end if;
			when JMPZY1  =>
				if( en = '1' )then
				N_S <= JMPZY2;
				end if;
			when JMPZY2  =>
				if( en = '1' )then
				N_S <= JMPZY3;
				end if;
			when JMPZY3  =>
				if( en = '1' )then
				N_S <= FETCH1;
				end if;
			when JMPZN1  =>
				if( en = '1' )then
				N_S <= JMPZN2;
				end if;
			when JMPZN2  =>
				if( en = '1' )then
				N_S <= FETCH1;
				end if;
			when JPNZY1  =>
				if( en = '1' )then
				N_S <= JPNZY2;
				end if;
			when JPNZY2  =>
				if( en = '1' )then
				N_S <= JPNZY3;
				end if;
			when JPNZY3  =>
				if( en = '1' )then
				N_S <= FETCH1;
				end if;
			when JPNZN1  =>
				if( en = '1' )then
				N_S <= JPNZN2;
				end if;
			when JPNZN2  =>
				if( en = '1' )then
				N_S <= FETCH1;
				end if;
			when ADD1  =>
				if( en = '1' )then
				N_S <= FETCH1;
				end if;
			when SUB1  =>
				if( en = '1' )then
				N_S <= FETCH1;
				end if;
			when INAC1  =>
				if( en = '1' )then
				N_S <= FETCH1;
				end if;
			when CLAC1  =>
				if( en = '1' )then
				N_S <= FETCH1;
				end if;
			when AND1  =>
				if( en = '1' )then
				N_S <= FETCH1;
				end if;
			when OR1  =>
				if( en = '1' )then
				N_S <= FETCH1;
				end if;
			when XOR1  =>
				if( en = '1' )then
				N_S <= FETCH1;
				end if;
			when NOT1  =>
				if( en = '1' )then
				N_S <= FETCH1;
				end if;
		end case;
	end process;
	
	--manage AC_REGISTER 
	process(clk, reset)
	begin
		if(reset = '0')then
			AC_REGISTER  <= (others => '0');
		elsif (falling_edge(clk) and en = '1')then
			AC_REGISTER  <= AC_REGISTER ;
			case P_S is							
			when MEM_INIT =>
				AC_REGISTER(7 downto 4) <= "0011";
				AC_REGISTER(3 downto 0) <= "0011";
			when LDAC5  =>
				AC_REGISTER  <= DR_REGISTER ;
			when MOVR1  =>
				AC_REGISTER  <= R_REGISTER ;
			when ADD1  =>
				AC_REGISTER  <= std_logic_vector(unsigned(AC_REGISTER) + unsigned(R_REGISTER));
			when SUB1  =>
				AC_REGISTER  <= std_logic_vector(unsigned(AC_REGISTER) - unsigned(R_REGISTER));
			when INAC1  =>
				AC_REGISTER  <= std_logic_vector(unsigned(AC_REGISTER) + 1);
			when CLAC1  =>
				AC_REGISTER  <= (others => '0');
			when AND1  =>
				AC_REGISTER  <= AC_REGISTER  AND R_REGISTER ;
			when OR1  =>
				AC_REGISTER  <= AC_REGISTER  OR R_REGISTER ;
			when XOR1  =>
				AC_REGISTER  <= AC_REGISTER  XOR R_REGISTER ;
			when NOT1  =>
				AC_REGISTER  <= NOT AC_REGISTER ;
			when others =>
		end case;
		end if;		
	end process;
	
	--manage PC_REGISTER 
	process(clk, reset)
	begin
		if(reset = '0')then
			PC_REGISTER  <= (others => '0');
		elsif (falling_edge(clk) and en = '1')then
			PC_REGISTER  <= PC_REGISTER ;
			
			case P_S is
			when FETCH2 =>
				PC_REGISTER  <= std_logic_vector(unsigned(PC_REGISTER) +1);
			when LDAC1  =>
				PC_REGISTER  <= std_logic_vector(unsigned(PC_REGISTER) +1);
			when LDAC2  =>
				PC_REGISTER  <= std_logic_vector(unsigned(PC_REGISTER) +1);
			when STAC1  =>
				PC_REGISTER  <= std_logic_vector(unsigned(PC_REGISTER) +1);
			when STAC2  =>
				PC_REGISTER  <= std_logic_vector(unsigned(PC_REGISTER) +1);
			when JUMP3  =>
				PC_REGISTER(15 downto 8) <= TR_REGISTER;
				PC_REGISTER(7 downto 0) <= DR_REGISTER;
			when JMPZY3  =>
				PC_REGISTER(15 downto 8) <= TR_REGISTER;
				PC_REGISTER(7 downto 0) <= DR_REGISTER;
			when JMPZN1  =>
				PC_REGISTER  <= std_logic_vector(unsigned(PC_REGISTER) +1);
			when JMPZN2  =>
				PC_REGISTER  <= std_logic_vector(unsigned(PC_REGISTER) +1);
			when JPNZY3  =>
				PC_REGISTER(15 downto 8) <= TR_REGISTER;
				PC_REGISTER(7 downto 0) <= DR_REGISTER;
			when JPNZN1  =>
				PC_REGISTER  <= std_logic_vector(unsigned(PC_REGISTER) +1);
			when JPNZN2  =>
				PC_REGISTER  <= std_logic_vector(unsigned(PC_REGISTER) +1);
			when others =>
		end case;
		end if;		
	end process;
	
	--manage AR_REGISTER 
	process(clk, reset)
	begin
		if(reset = '0')then
			AR_REGISTER  <= (others => '0');
		elsif (falling_edge(clk) and en = '1')then
			AR_REGISTER  <= AR_REGISTER ;
			
			case P_S is
			when FETCH1 =>
				AR_REGISTER  <= PC_REGISTER ;
			when FETCH3 =>
				AR_REGISTER  <= PC_REGISTER ;
			when LDAC1  =>
				AR_REGISTER  <= std_logic_vector(unsigned(AR_REGISTER) +1);
			when LDAC3  =>
				AR_REGISTER(15 downto 8) <= TR_REGISTER;
				AR_REGISTER(7 downto 0) <= DR_REGISTER;
			when STAC1  =>
				AR_REGISTER  <= std_logic_vector(unsigned(AR_REGISTER) +1);
			when STAC3  =>
				AR_REGISTER(15 downto 8) <= TR_REGISTER;
				AR_REGISTER(7 downto 0) <= DR_REGISTER;
			when JUMP1  =>
				AR_REGISTER  <= std_logic_vector(unsigned(AR_REGISTER) +1);
			when JMPZY1  =>
				AR_REGISTER  <= std_logic_vector(unsigned(AR_REGISTER) +1);
			when JPNZY1  =>
				AR_REGISTER  <= std_logic_vector(unsigned(AR_REGISTER) +1);
			when others =>
		end case;
		end if;		
	end process;
	
	--manage DR_REGISTER 
	
	process(clk, reset)
	begin
		if(reset = '0')then
			DR_REGISTER  <= (others => '0');
		elsif (falling_edge(clk))then
			DR_REGISTER  <= DR_REGISTER ;
			
			case P_S is
			when FETCH2 =>
				DR_REGISTER  <= RAM(to_integer(unsigned(AR_REGISTER)));
			when LDAC1  =>
				DR_REGISTER  <= RAM(to_integer(unsigned(AR_REGISTER)));
			when LDAC2  =>
				DR_REGISTER  <= RAM(to_integer(unsigned(AR_REGISTER)));
			when LDAC4  =>
				DR_REGISTER  <= RAM(to_integer(unsigned(AR_REGISTER)));
			when STAC1  =>
				DR_REGISTER  <= RAM(to_integer(unsigned(AR_REGISTER)));
			when STAC2  =>
				DR_REGISTER  <= RAM(to_integer(unsigned(AR_REGISTER)));
			when STAC4  =>
				DR_REGISTER  <= AC_REGISTER ;
			when JUMP1  =>
				DR_REGISTER  <= RAM(to_integer(unsigned(AR_REGISTER)));
			when JUMP2  =>
				DR_REGISTER  <= RAM(to_integer(unsigned(AR_REGISTER)));
			when JMPZY1  =>
				DR_REGISTER  <= RAM(to_integer(unsigned(AR_REGISTER)));
			when JMPZY2  =>
				DR_REGISTER  <= RAM(to_integer(unsigned(AR_REGISTER)));
			when JPNZY1  =>
				DR_REGISTER  <= RAM(to_integer(unsigned(AR_REGISTER)));
			when JPNZY2  =>
				DR_REGISTER  <= RAM(to_integer(unsigned(AR_REGISTER)));
			when others =>
		end case;
		end if;		
	end process;
	
	--manage TR_REGISTER 
	process(clk, reset)
	begin
		if(reset = '0')then
			TR_REGISTER  <= (others => '0');
		elsif (falling_edge(clk))then
			TR_REGISTER  <= TR_REGISTER ;
			
			case P_S is
			when LDAC2  =>
				TR_REGISTER  <= DR_REGISTER ;
			when STAC2  =>
				TR_REGISTER  <= DR_REGISTER ;
			when JUMP2  =>
				TR_REGISTER  <= DR_REGISTER ;
			when JMPZY2  =>
				TR_REGISTER  <= DR_REGISTER ;
			when JPNZY2  =>
				TR_REGISTER  <= DR_REGISTER ;
			when others =>
		end case;
		end if;		
	end process;
	
	--manage IR_REGISTER 
	process(clk, reset)
	begin
		if(reset = '0')then
			IR_REGISTER  <= (others => '0');
		elsif (falling_edge(clk))then
			IR_REGISTER  <= IR_REGISTER ;
			
			case P_S is
			when FETCH3 =>
				IR_REGISTER  <= DR_REGISTER ;
			when others =>
		end case;
		end if;		
	end process;
	
	--manage R_REGISTER 
	process(clk, reset)
	begin
		if(reset = '0')then
			R_REGISTER  <= (others => '0');
		elsif (falling_edge(clk))then
			R_REGISTER  <= R_REGISTER ;
			
			case P_S is
			when MEM_INIT =>
				R_REGISTER(7 downto 4) <= "0000";
				R_REGISTER(3 downto 0) <= "0010";
			when MVAC1  =>
				R_REGISTER  <= AC_REGISTER ;
			when others =>
		end case;
		end if;		
	end process;
	
	--manage Z_FLAG 
	process(clk, reset)
	begin
		if(reset = '0')then
			Z_FLAG  <= '0';
		elsif (rising_edge(clk))then
			if (AC_REGISTER  = "00000000" ) then
					Z_FLAG <= '1';
				else
					Z_FLAG <= '0';
				end if;
		end if;		
	end process;
	
	--manage memory
	process(clk)
	begin	
		if (falling_edge(clk))then
			case P_S is			
			when MEM_INIT =>
				RAM(Mem_count) <= ROM(Mem_count);
				Mem_count <= Mem_count + 1;
			
			when STAC5  =>
				RAM(to_integer(unsigned(AR_REGISTER))) <= DR_REGISTER ;
			when others =>
		end case;
		end if;		
	end process;
	
	--Send value of register to output
	process(clk)
	variable tmp: STd_logic_vector(7 downto 0);
	begin
		tmp := RAM(to_integer(unsigned(AR_REGISTER)));
		if(sw0 = '0')then
			output1 <= convSEG(AC_REGISTER(3 downto 0));
			output2 <= convSEG(AC_REGISTER(7 downto 4));
			output3 <= convSEG(R_REGISTER(3 downto 0));
			output4 <= convSEG(R_REGISTER(7 downto 4));
			output5 <= convSEG(tmp(3 downto 0));
			output6 <= convSEG(tmp(7 downto 4));
		else
			output1 <= convSEG(DR_REGISTER(3 downto 0));
			output2 <= convSEG(DR_REGISTER(7 downto 4));
			output3 <= convSEG(AR_REGISTER(3 downto 0));
			output4 <= convSEG(AR_REGISTER(7 downto 4));
			output5 <= convSEG(PC_REGISTER(3 downto 0));
			output6 <= convSEG(PC_REGISTER(7 downto 4));
		end if;
	end process;
	
	process(clk)
	begin
	
	if (falling_edge(clk))then
	if(Delay_count = 100000000)then
		en <= '1';
		Delay_count <= 0;
	else
		en <= '0';
		Delay_count <= Delay_count + 1;
	end if;
	end if;
	
	end process;
	
	test0 <= temp(0);
	test1 <= temp(1);
	Z <= Z_FLAG;
	
end behavioral;
