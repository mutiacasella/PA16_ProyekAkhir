-- AES_Encryption_Testbench.vhd
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use work.aes_package.all;

entity AES_Encryption_Testbench is
end AES_Encryption_Testbench;

architecture Behavioral of AES_Encryption_Testbench is
    -- Component declaration
    component AES_Encryption
        Port ( 
            clk : in STD_LOGIC;
            rst : in STD_LOGIC;
            data_in : in STD_LOGIC_VECTOR(127 downto 0);
            key : in STD_LOGIC_VECTOR(127 downto 0);
            data_out : out STD_LOGIC_VECTOR(127 downto 0);
            done : out STD_LOGIC
        );
    end component;

    -- Test signals
    signal clk : STD_LOGIC := '0';
    signal rst : STD_LOGIC := '1';
    signal data_in : STD_LOGIC_VECTOR(127 downto 0);
    signal key : STD_LOGIC_VECTOR(127 downto 0);
    signal data_out : STD_LOGIC_VECTOR(127 downto 0);
    signal done : STD_LOGIC;
    
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

    function state_to_slv(state: state_array) return std_logic_vector is
        variable result: std_logic_vector(127 downto 0);
    begin
        for i in 0 to 3 loop
            for j in 0 to 3 loop
                result(127-32*i-8*j downto 120-32*i-8*j) := state(i,j);
            end loop;
        end loop;
        return result;
    end function;
    
    -- Modified write_state_array procedure
    procedure write_state_array(
        file f: text;
        state_name: in string;
        state_val: in state_array) is
        variable l: line;
    begin
        write(l, state_name & ":");
        writeline(f, l);
        for i in 0 to 3 loop
            for j in 0 to 3 loop
                write(l, string'("  "));
                hwrite(l, state_val(i,j));
            end loop;
            writeline(f, l);
        end loop;
    end procedure;

    -- Add signals for monitoring intermediate states
    signal sub_bytes_out : state_array;
    signal shift_rows_out : state_array;
    signal mix_columns_out : state_array;
    signal add_round_key_out : state_array;
    signal round_keys : std_logic_vector(1407 downto 0);

    -- Add function to format hex output
    function format_hex(slv: std_logic_vector(127 downto 0)) return string is
        variable result: string(1 to 32);
        variable nibble: std_logic_vector(3 downto 0);
    begin
        for i in 31 downto 0 loop
            nibble := slv(127-4*i downto 124-4*i);
            case to_integer(unsigned(nibble)) is
                when  0 => result(32-i) := '0';
                when  1 => result(32-i) := '1';
                when  2 => result(32-i) := '2';
                when  3 => result(32-i) := '3';
                when  4 => result(32-i) := '4';
                when  5 => result(32-i) := '5';
                when  6 => result(32-i) := '6';
                when  7 => result(32-i) := '7';
                when  8 => result(32-i) := '8';
                when  9 => result(32-i) := '9';
                when 10 => result(32-i) := 'A';
                when 11 => result(32-i) := 'B';
                when 12 => result(32-i) := 'C';
                when 13 => result(32-i) := 'D';
                when 14 => result(32-i) := 'E';
                when 15 => result(32-i) := 'F';
                when others => result(32-i) := 'X';
            end case;
        end loop;
        return result;
    end function;

    -- Add monitoring signals
    signal monitor_state : state_array;
    signal monitor_key : std_logic_vector(127 downto 0);
    signal monitor_round : integer range 0 to 10;

begin
    -- Instantiate AES_Encryption
    UUT: AES_Encryption port map (
        clk => clk,
        rst => rst,
        data_in => data_in,
        key => key,
        data_out => data_out,
        done => done
    );

    -- Clock generation
    clk_process: process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    -- Single process for state management and stimulus
    stim_proc: process
        file input_file : text;
        file output_file : text;
        variable input_line : line;
        variable output_line : line;
        variable plaintext_str : string(1 to 32);
        variable key_str : string(1 to 32);
        variable expected_str : string(1 to 32);
        variable space : character;
    begin
        -- Initial state
        test_state <= INIT;
        current_round <= 0;
        
        -- File operations
        file_open(input_file, "aes_test_vectors.txt", read_mode);
        file_open(output_file, "aes_debug.txt", write_mode);

        -- Write header and read input
        readline(input_file, input_line);
        read(input_line, plaintext_str);
        read(input_line, space);
        read(input_line, key_str);
        read(input_line, space);
        read(input_line, expected_str);

        -- Write test header
        write(output_line, string'("=== AES Encryption Test ==="));
        writeline(output_file, output_line);
        write(output_line, string'("Input : ") & plaintext_str);
        writeline(output_file, output_line);
        write(output_line, string'("Key   : ") & key_str);
        writeline(output_file, output_line);
        writeline(output_file, output_line);

        -- Start encryption
        rst <= '1';
        wait for clk_period*2;
        rst <= '0';
        
        data_in <= hex_to_slv(plaintext_str);
        key <= hex_to_slv(key_str);
        test_state <= RUNNING;

        -- Monitor rounds
        while test_state /= TEST_DONE loop
            wait for clk_period;
            
            -- Write round information
            write(output_line, string'("Round ") & integer'image(current_round));
            writeline(output_file, output_line);
            
            -- Write state information using write_state_array
            write_state_array(output_file, "State", sub_bytes_out);
            write_state_array(output_file, "After SubBytes", sub_bytes_out);
            write_state_array(output_file, "After ShiftRows", shift_rows_out);
            
            if current_round /= 10 then
                write_state_array(output_file, "After MixColumns", mix_columns_out);
            end if;
            
            -- Write round key
            write(output_line, string'("Round Key: "));
            write(output_line, format_hex(round_keys(1407-128*current_round downto 1280-128*current_round)));
            writeline(output_file, output_line);
            writeline(output_file, output_line);  -- blank line
            
            if done = '1' then
                test_state <= TEST_DONE;
            elsif current_round < 10 then
                current_round <= current_round + 1;
            end if;
            
            wait for clk_period;
        end loop;

        -- Write results
        write(output_line, string'("=== Final Results ==="));
        writeline(output_file, output_line);
        write(output_line, string'("Result  : ") & format_hex(data_out));
        writeline(output_file, output_line);
        write(output_line, string'("Expected: ") & expected_str);
        writeline(output_file, output_line);
        
        if data_out = hex_to_slv(expected_str) then
            write(output_line, string'("TEST PASSED"));
        else
            write(output_line, string'("TEST FAILED"));
        end if;
        writeline(output_file, output_line);

        file_close(input_file);
        file_close(output_file);
        wait;
    end process;

end Behavioral;