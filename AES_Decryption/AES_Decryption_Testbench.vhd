-- AES_Decryption_Testbench.vhd
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use work.aes_package.all;
use std.env.all;

entity AES_Decryption_Testbench is
end AES_Decryption_Testbench;

architecture Behavioral of AES_Decryption_Testbench is
    -- Component declaration
    component AES_Decryption
        Port ( 
            clk : in STD_LOGIC;
            rst : in STD_LOGIC;
            data_in : in STD_LOGIC_VECTOR(127 downto 0);
            key : in STD_LOGIC_VECTOR(127 downto 0);
            data_out : out STD_LOGIC_VECTOR(127 downto 0);
            done : out STD_LOGIC;
            debug_state_out : out state_array;
            debug_sub_bytes_out : out state_array;
            debug_shift_rows_out : out state_array;
            debug_mix_cols_out : out state_array;
            debug_round_key_out : out STD_LOGIC_VECTOR(127 downto 0)
        );
    end component;

    -- Test signals
    signal clk : STD_LOGIC := '0';
    signal rst : STD_LOGIC := '1';
    signal data_in : STD_LOGIC_VECTOR(127 downto 0);
    signal key : STD_LOGIC_VECTOR(127 downto 0);
    signal data_out : STD_LOGIC_VECTOR(127 downto 0);
    signal done : STD_LOGIC;

    -- Add debug signals
    signal debug_state : state_array;
    signal debug_sub_bytes : state_array;
    signal debug_shift_rows : state_array;
    signal debug_mix_cols : state_array;
    signal debug_round_key : STD_LOGIC_VECTOR(127 downto 0);

    -- Clock period
    constant clk_period : time := 10 ns;

    -- State machine signals
    type test_state_type is (INIT, RUNNING, TEST_DONE);
    signal test_state : test_state_type := INIT;
    signal current_round : integer range 0 to 10 := 0;

    -- Helper functions
    function hex_to_slv(hex: string) return std_logic_vector is
        variable result : std_logic_vector(127 downto 0);
        variable nibble : std_logic_vector(3 downto 0);
    begin
        for i in 0 to 31 loop
            case hex(i+1) is
                when '0' => nibble := "0000";
                when '1' => nibble := "0001";
                when '2' => nibble := "0010";
                when '3' => nibble := "0011";
                when '4' => nibble := "0100";
                when '5' => nibble := "0101";
                when '6' => nibble := "0110";
                when '7' => nibble := "0111";
                when '8' => nibble := "1000";
                when '9' => nibble := "1001";
                when 'a'|'A' => nibble := "1010";
                when 'b'|'B' => nibble := "1011";
                when 'c'|'C' => nibble := "1100";
                when 'd'|'D' => nibble := "1101";
                when 'e'|'E' => nibble := "1110";
                when 'f'|'F' => nibble := "1111";
                when others => nibble := "0000";
            end case;
            result(127-4*i downto 124-4*i) := nibble;
        end loop;
        return result;
    end function;
    
    function slv_to_hex(slv: std_logic_vector(127 downto 0)) return string is
        variable result : string(1 to 32);
        variable nibble : std_logic_vector(3 downto 0);
    begin
        for i in 0 to 31 loop
            nibble := slv(127-4*i downto 124-4*i);
            case to_integer(unsigned(nibble)) is
                when  0 => result(i+1) := '0';
                when  1 => result(i+1) := '1';
                when  2 => result(i+1) := '2';
                when  3 => result(i+1) := '3';
                when  4 => result(i+1) := '4';
                when  5 => result(i+1) := '5';
                when  6 => result(i+1) := '6';
                when  7 => result(i+1) := '7';
                when  8 => result(i+1) := '8';
                when  9 => result(i+1) := '9';
                when 10 => result(i+1) := 'a';
                when 11 => result(i+1) := 'b';
                when 12 => result(i+1) := 'c';
                when 13 => result(i+1) := 'd';
                when 14 => result(i+1) := 'e';
                when 15 => result(i+1) := 'f';
                when others => result(i+1) := 'x';
            end case;
        end loop;
        return result;
    end function;

    -- Add state array to hex string function
    function state_to_hex(state: state_array) return string is
        variable result : string(1 to 32);
        variable byte_val : std_logic_vector(7 downto 0);
        variable idx : integer;
    begin
        idx := 1;
        for i in 0 to 3 loop
            for j in 0 to 3 loop
                byte_val := state(i, j);
                for k in 0 to 1 loop
                    case to_integer(unsigned(byte_val((7-4*k) downto (4-4*k)))) is
                        when 0 to 9 => 
                            result(idx) := character'val(character'pos('0') + 
                                            to_integer(unsigned(byte_val((7-4*k) downto (4-4*k)))));
                        when 10 to 15 => 
                            result(idx) := character'val(character'pos('a') + 
                                            to_integer(unsigned(byte_val((7-4*k) downto (4-4*k)))) - 10);
                        when others => result(idx) := 'x';
                    end case;
                    idx := idx + 1;
                end loop;
            end loop;
        end loop;
        return result;
    end function;
    
    -- Add before begin
    function is_x(s: string) return boolean is
    begin
        for i in s'range loop
            if s(i) = 'x' then
                return true;
            end if;
        end loop;
        return false;
    end function;
    
begin
    -- Instantiate AES_Decryption
    UUT: AES_Decryption port map (
        clk => clk,
        rst => rst,
        data_in => data_in,
        key => key,
        data_out => data_out,
        done => done,
        debug_state_out => debug_state,
        debug_sub_bytes_out => debug_sub_bytes,
        debug_shift_rows_out => debug_shift_rows,
        debug_mix_cols_out => debug_mix_cols,
        debug_round_key_out => debug_round_key
    );

    -- Clock generation
    clk_process: process
    begin
        clk <= '0';
        wait for clk_period / 2;
        clk <= '1';
        wait for clk_period / 2;
    end process;

    -- Single process for state management and stimulus
    stim_proc: process
        file input_file : text;
        file output_file : text;
        variable input_line : line;
        variable output_line : line;
        variable ciphertext_str : string(1 to 32);
        variable key_str : string(1 to 32);
        variable expected_str : string(1 to 32);
        variable space : character;
    begin
        -- Open files
        file_open(input_file, "aes_test_vectors.txt", read_mode);
        file_open(output_file, "aes_test_results.txt", write_mode);

        -- Read test vector
        readline(input_file, input_line);
        read(input_line, ciphertext_str);
        read(input_line, space);
        read(input_line, key_str);
        read(input_line, space);
        read(input_line, expected_str);

        -- Write test setup info
        write(output_line, string'("=== AES Decryption Test ==="));
        writeline(output_file, output_line);
        write(output_line, string'("Ciphertext: ") & ciphertext_str);
        writeline(output_file, output_line);
        write(output_line, string'("Key        : ") & key_str);
        writeline(output_file, output_line);
        write(output_line, string'("Expected   : ") & expected_str);
        writeline(output_file, output_line);
        writeline(output_file, output_line);

        -- Initial setup
        test_state <= INIT;
        current_round <= 10; -- Start from the last round

        -- Reset sequence
        rst <= '1';
        wait for clk_period*2;
        rst <= '0';
        
        -- Apply inputs
        data_in <= hex_to_slv(ciphertext_str);
        key <= hex_to_slv(key_str);
        test_state <= RUNNING;

        -- Wait for key expansion
        wait for clk_period*2;

        -- Monitor decryption process
        while test_state /= TEST_DONE loop
            -- Debug headers
            write(output_line, string'("----------------------------------------"));
            writeline(output_file, output_line);
            write(output_line, string'("Round ") & integer'image(current_round));
            writeline(output_file, output_line);

            -- Debug state values
            write(output_line, string'("Current state: "));
            writeline(output_file, output_line);
            write(output_line, string'("  State     : ") & state_to_hex(debug_state));
            writeline(output_file, output_line);
            write(output_line, string'("  SubBytes  : ") & state_to_hex(debug_sub_bytes));
            writeline(output_file, output_line);
            write(output_line, string'("  ShiftRows : ") & state_to_hex(debug_shift_rows));
            writeline(output_file, output_line);
            write(output_line, string'("  MixCols   : ") & state_to_hex(debug_mix_cols));
            writeline(output_file, output_line);
            write(output_line, string'("  RoundKey  : ") & slv_to_hex(debug_round_key));
            writeline(output_file, output_line);
            writeline(output_file, output_line);

            -- Update state and wait
            if done = '1' then
                test_state <= TEST_DONE;
                write(output_line, string'("========== Decryption Complete =========="));
                writeline(output_file, output_line);
            elsif current_round > 0 then
                current_round <= current_round - 1;
            end if;

            wait for clk_period;
        end loop;

        -- Write final results
        write(output_line, string'("Final Results:"));
        writeline(output_file, output_line);
        write(output_line, string'("Output   : ") & slv_to_hex(data_out));
        writeline(output_file, output_line);
        write(output_line, string'("Expected : ") & expected_str);
        writeline(output_file, output_line);
        
        if data_out = hex_to_slv(expected_str) then
            write(output_line, string'("Status: PASS"));
        else
            write(output_line, string'("Status: FAIL"));
        end if;
        writeline(output_file, output_line);

        -- Cleanup and end
        file_close(input_file);
        file_close(output_file);
        report "Simulation complete";
        std.env.stop(0);
        wait;
    end process;

end Behavioral;