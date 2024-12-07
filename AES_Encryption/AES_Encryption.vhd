library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.aes_package.all;

entity AES_Encryption is
    Port ( 
        clk : in STD_LOGIC;
        rst : in STD_LOGIC;
        data_in : in STD_LOGIC_VECTOR(127 downto 0);
        key : in STD_LOGIC_VECTOR(127 downto 0);
        data_out : out STD_LOGIC_VECTOR(127 downto 0);
        done : out STD_LOGIC;
        -- Debug ports
        debug_state_out : out state_array;
        debug_sub_bytes_out : out state_array;
        debug_shift_rows_out : out state_array;
        debug_mix_cols_out : out state_array;
        debug_round_key_out : out STD_LOGIC_VECTOR(127 downto 0)
    );
end AES_Encryption;

architecture Behavioral of AES_Encryption is
    -- State signals
    signal state : state_array;
    signal round : integer range 0 to 10;
    signal done_i : STD_LOGIC;
    signal round_keys : STD_LOGIC_VECTOR(1407 downto 0);
    signal current_round_key : STD_LOGIC_VECTOR(127 downto 0);
    signal key_expanded : STD_LOGIC := '0';
    signal initial_state_loaded : STD_LOGIC := '0';

    -- S-box and round constants
    type sbox_array is array (0 to 255) of STD_LOGIC_VECTOR(7 downto 0);
    constant SBOX : sbox_array := (
        X"63", X"7c", X"77", X"7b", X"f2", X"6b", X"6f", X"c5", X"30", X"01", X"67", X"2b", X"fe", X"d7", X"ab", X"76",
        X"ca", X"82", X"c9", X"7d", X"fa", X"59", X"47", X"f0", X"ad", X"d4", X"a2", X"af", X"9c", X"a4", X"72", X"c0",
        X"b7", X"fd", X"93", X"26", X"36", X"3f", X"f7", X"cc", X"34", X"a5", X"e5", X"f1", X"71", X"d8", X"31", X"15",
        X"04", X"c7", X"23", X"c3", X"18", X"96", X"05", X"9a", X"07", X"12", X"80", X"e2", X"eb", X"27", X"b2", X"75",
        X"09", X"83", X"2c", X"1a", X"1b", X"6e", X"5a", X"a0", X"52", X"3b", X"d6", X"b3", X"29", X"e3", X"2f", X"84",
        X"53", X"d1", X"00", X"ed", X"20", X"fc", X"b1", X"5b", X"6a", X"cb", X"be", X"39", X"4a", X"4c", X"58", X"cf",
        X"d0", X"ef", X"aa", X"fb", X"43", X"4d", X"33", X"85", X"45", X"f9", X"02", X"7f", X"50", X"3c", X"9f", X"a8",
        X"51", X"a3", X"40", X"8f", X"92", X"9d", X"38", X"f5", X"bc", X"b6", X"da", X"21", X"10", X"ff", X"f3", X"d2",
        X"cd", X"0c", X"13", X"ec", X"5f", X"97", X"44", X"17", X"c4", X"a7", X"7e", X"3d", X"64", X"5d", X"19", X"73",
        X"60", X"81", X"4f", X"dc", X"22", X"2a", X"90", X"88", X"46", X"ee", X"b8", X"14", X"de", X"5e", X"0b", X"db",
        X"e0", X"32", X"3a", X"0a", X"49", X"06", X"24", X"5c", X"c2", X"d3", X"ac", X"62", X"91", X"95", X"e4", X"79",
        X"e7", X"c8", X"37", X"6d", X"8d", X"d5", X"4e", X"a9", X"6c", X"56", X"f4", X"ea", X"65", X"7a", X"ae", X"08",
        X"ba", X"78", X"25", X"2e", X"1c", X"a6", X"b4", X"c6", X"e8", X"dd", X"74", X"1f", X"4b", X"bd", X"8b", X"8a",
        X"70", X"3e", X"b5", X"66", X"48", X"03", X"f6", X"0e", X"61", X"35", X"57", X"b9", X"86", X"c1", X"1d", X"9e",
        X"e1", X"f8", X"98", X"11", X"69", X"d9", X"8e", X"94", X"9b", X"1e", X"87", X"e9", X"ce", X"55", X"28", X"df",
        X"8c", X"a1", X"89", X"0d", X"bf", X"e6", X"42", X"68", X"41", X"99", X"2d", X"0f", X"b0", X"54", X"bb", X"16"
    );

    type rcon_array is array (1 to 10) of STD_LOGIC_VECTOR(7 downto 0);
    constant rcon : rcon_array := (
        X"01", X"02", X"04", X"08", X"10", X"20", X"40", X"80", X"1B", X"36"
    );

    function state_to_output(state_in: state_array) return STD_LOGIC_VECTOR is
        variable result : STD_LOGIC_VECTOR(127 downto 0);
    begin
        for i in 0 to 3 loop
            for j in 0 to 3 loop
                result(127-8*(4*i+j) downto 120-8*(4*i+j)) := state_in(j,i);
            end loop;
        end loop;
        return result;
    end function;

    function to_hstring(slv: std_logic_vector) return string is
        variable result : string(1 to slv'length/4);
        variable nibble : std_logic_vector(3 downto 0);
    begin
        for i in result'range loop
            nibble := slv(slv'length-i*4-1 downto slv'length-i*4-4);
            case to_integer(unsigned(nibble)) is
                when  0 => result(i) := '0';
                when  1 => result(i) := '1';
                when  2 => result(i) := '2';
                when  3 => result(i) := '3';
                when  4 => result(i) := '4';
                when  5 => result(i) := '5';
                when  6 => result(i) := '6';
                when  7 => result(i) := '7';
                when  8 => result(i) := '8';
                when  9 => result(i) := '9';
                when 10 => result(i) := 'a';
                when 11 => result(i) := 'b';
                when 12 => result(i) := 'c';
                when 13 => result(i) := 'd';
                when 14 => result(i) := 'e';
                when 15 => result(i) := 'f';
                when others => result(i) := 'x';
            end case;
        end loop;
        return result;
    end function;

    -- SubBytes transformation
    function sub_bytes(state_in: state_array) return state_array is
        variable result : state_array;
    begin
        for i in 0 to 3 loop
            for j in 0 to 3 loop
                result(i,j) := SBOX(to_integer(unsigned(state_in(i,j))));
            end loop;
        end loop;
        return result;
    end function;

    -- ShiftRows transformation  
    function shift_rows(state_in: state_array) return state_array is
        variable result : state_array;
    begin
        -- Row 0: no shift
        result(0,0) := state_in(0,0);
        result(0,1) := state_in(0,1);
        result(0,2) := state_in(0,2);
        result(0,3) := state_in(0,3);
        
        -- Row 1: shift left by 1
        result(1,0) := state_in(1,1);
        result(1,1) := state_in(1,2);
        result(1,2) := state_in(1,3);
        result(1,3) := state_in(1,0);
        
        -- Row 2: shift left by 2
        result(2,0) := state_in(2,2);
        result(2,1) := state_in(2,3);
        result(2,2) := state_in(2,0);
        result(2,3) := state_in(2,1);
        
        -- Row 3: shift left by 3
        result(3,0) := state_in(3,3);
        result(3,1) := state_in(3,0);
        result(3,2) := state_in(3,1);
        result(3,3) := state_in(3,2);
        
        return result;
    end function;

    -- GF(2^8) multiplication
    function gf_mult(a, b: STD_LOGIC_VECTOR(7 downto 0)) return STD_LOGIC_VECTOR is
        variable p : STD_LOGIC_VECTOR(7 downto 0);
        variable hi_bit : STD_LOGIC;
        variable temp : STD_LOGIC_VECTOR(7 downto 0);
    begin
        p := (others => '0');
        temp := a;
        
        for i in 0 to 7 loop
            if (b(i) = '1') then
                p := p xor temp;
            end if;
            hi_bit := temp(7);
            temp := temp(6 downto 0) & '0';
            if (hi_bit = '1') then
                temp := temp xor X"1B";  -- Reduction polynomial
            end if;
        end loop;
        return p;
    end function;

    -- MixColumns transformation
    function mix_columns(state_in: state_array) return state_array is
        variable result : state_array;
    begin
        for col in 0 to 3 loop
            result(0,col) := gf_mult(X"02", state_in(0,col)) xor 
                            gf_mult(X"03", state_in(1,col)) xor 
                            state_in(2,col) xor 
                            state_in(3,col);
            
            result(1,col) := state_in(0,col) xor 
                            gf_mult(X"02", state_in(1,col)) xor 
                            gf_mult(X"03", state_in(2,col)) xor 
                            state_in(3,col);
            
            result(2,col) := state_in(0,col) xor 
                            state_in(1,col) xor 
                            gf_mult(X"02", state_in(2,col)) xor 
                            gf_mult(X"03", state_in(3,col));
            
            result(3,col) := gf_mult(X"03", state_in(0,col)) xor 
                            state_in(1,col) xor 
                            state_in(2,col) xor 
                            gf_mult(X"02", state_in(3,col));
        end loop;
        return result;
    end function;

begin
    -- Key expansion process
    process(clk, rst)
        type word_array is array (0 to 43) of STD_LOGIC_VECTOR(31 downto 0);
        variable w : word_array;
        variable temp : STD_LOGIC_VECTOR(31 downto 0);
    begin
        if rst = '1' then
            key_expanded <= '0';
            round_keys <= (others => '0');
        elsif rising_edge(clk) then
            if not key_expanded then
                -- Store original key as first round key
                round_keys(1407 downto 1280) <= key;
                
                -- Initialize w with key
                w(0) := key(127 downto 96);
                w(1) := key(95 downto 64);
                w(2) := key(63 downto 32);
                w(3) := key(31 downto 0);
                
                -- Generate remaining words
                for i in 4 to 43 loop
                    temp := w(i-1);
                    if (i mod 4 = 0) then
                        -- RotWord
                        temp := temp(23 downto 0) & temp(31 downto 24);
                        -- SubWord
                        for j in 0 to 3 loop
                            temp(31-8*j downto 24-8*j) := 
                                SBOX(to_integer(unsigned(temp(31-8*j downto 24-8*j))));
                        end loop;
                        -- XOR with Rcon
                        temp := temp xor (rcon(i/4) & X"000000");
                    end if;
                    w(i) := w(i-4) xor temp;
                    
                    -- Pack round keys as they are generated
                    if (i mod 4 = 3) and (i > 3) then
                        round_keys(1407-128*(i/4) downto 1280-128*(i/4)) <= 
                            w(i-3) & w(i-2) & w(i-1) & w(i);
                    end if;
                end loop;
                
                key_expanded <= '1';
            end if;
        end if;
    end process;

    -- Main encryption process
    main_proc: process(clk, rst)
        variable next_state : state_array;
    begin
        if rst = '1' then
            round <= 0;
            done_i <= '0';
            state <= (others => (others => (others => '0')));
        elsif rising_edge(clk) then
            if key_expanded = '1' then  -- Wait for key expansion
                case round is
                    when 0 =>
                        -- Initial state loading and AddRoundKey
                        for col in 0 to 3 loop
                            for row in 0 to 3 loop
                                state(row,col) <= data_in(127-8*(4*col+row) downto 120-8*(4*col+row)) xor 
                                                    key(127-8*(4*col+row) downto 120-8*(4*col+row));
                            end loop;
                        end loop;
                        
                        -- Prepare key for next round
                        current_round_key <= round_keys(1279 downto 1152);
                        round <= round + 1;
                        initial_state_loaded <= '1';

                    when 1 to 9 =>
                        -- Apply transformations in sequence
                        next_state := sub_bytes(state);
                        next_state := shift_rows(next_state);
                        next_state := mix_columns(next_state);
                        
                        -- AddRoundKey with proper key selection
                        for col in 0 to 3 loop
                            for row in 0 to 3 loop
                                state(row,col) <= next_state(row,col) xor 
                                                    current_round_key(127-8*(4*col+row) downto 120-8*(4*col+row));
                            end loop;
                        end loop;
                        
                        -- Update round key untuk round berikutnya
                        current_round_key <= round_keys(1279-128*round downto 1152-128*round);
                        round <= round + 1;

                    when 10 =>
                        if not done_i then
                            next_state := sub_bytes(state);
                            next_state := shift_rows(next_state);
                            
                            -- Final AddRoundKey
                            for i in 0 to 3 loop
                                for j in 0 to 3 loop
                                    state(j,i) <= next_state(j,i) xor 
                                                    current_round_key(127-8*(4*i+j) downto 120-8*(4*i+j));
                                end loop;
                            end loop;
                            done_i <= '1';
                        end if;

                    when others => null;
                end case;
            end if;
        end if;
    end process;

    -- Debug process
    debug_proc: process(clk)
    begin
        if rising_edge(clk) then
            -- Update debug signals
            debug_state_out <= state;
            debug_round_key_out <= current_round_key when round > 0 else key;
            
            -- Show transformations only after initial state loaded
            if initial_state_loaded = '1' or round > 0 then
                debug_sub_bytes_out <= sub_bytes(state);
                debug_shift_rows_out <= shift_rows(sub_bytes(state));
                debug_mix_cols_out <= mix_columns(shift_rows(sub_bytes(state)));
            end if;
        end if;
    end process;

    -- Output assignment
    done <= done_i;
    
    -- Convert state to output
    output_process: process(state)
        variable temp : STD_LOGIC_VECTOR(127 downto 0);
    begin
        for col in 0 to 3 loop
            for row in 0 to 3 loop
                temp(127-8*(4*col+row) downto 120-8*(4*col+row)) := state(row,col);
            end loop;
        end loop;
        data_out <= temp;
    end process;

end Behavioral;