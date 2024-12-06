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
        done : out STD_LOGIC
    );
end AES_Encryption;

architecture Behavioral of AES_Encryption is
    signal state, next_state : state_array;
    signal round : integer range 0 to 10;
    signal sub_bytes_out : state_array;
    signal shift_rows_out : state_array;
    signal mix_columns_out : state_array;
    signal add_round_key_out : state_array;
    signal round_keys : STD_LOGIC_VECTOR(1407 downto 0);
    signal current_round_key : STD_LOGIC_VECTOR(127 downto 0);
    signal done_i : STD_LOGIC; -- Internal done signal
    signal final_round : STD_LOGIC;
    signal ark_input : state_array;  -- New signal for AddRoundKey input selection
    
    -- Add monitoring signals
    signal monitor_state : state_array;
    signal monitor_key : std_logic_vector(127 downto 0);
    
    -- Add debug signals
    signal monitor_sub_bytes : state_array;
    signal monitor_shift_rows : state_array;
    signal monitor_mix_cols : state_array;

    -- Debug signals
    signal debug_state : STD_LOGIC_VECTOR(127 downto 0);
    signal debug_key : STD_LOGIC_VECTOR(127 downto 0);

    -- Components declarations
    component sub_bytes
        Port (
            byte_in : in STD_LOGIC_VECTOR(7 downto 0);
            byte_out : out STD_LOGIC_VECTOR(7 downto 0)
        );
    end component;
    
    component shift_rows
        Port (
            state_in : in state_array;
            state_out : out state_array
        );
    end component;
    
    component mix_columns
        Port (
            state_in : in state_array;
            state_out : out state_array
        );
    end component;
    
    component add_round_key
        Port (
            state_in : in state_array;
            round_key : in STD_LOGIC_VECTOR(127 downto 0);
            state_out : out state_array
        );
    end component;

    component key_expansion
        Port (
            key : in STD_LOGIC_VECTOR(127 downto 0);
            round_keys : out STD_LOGIC_VECTOR(1407 downto 0)
        );
    end component;

    -- Convert input to state array
    function input_to_state(input: STD_LOGIC_VECTOR(127 downto 0)) 
    return state_array is
        variable state_tmp : state_array;
    begin
        for i in 0 to 3 loop
            for j in 0 to 3 loop
                state_tmp(i,j) := input(127-8*(4*i+j) downto 120-8*(4*i+j));
            end loop;
        end loop;
        return state_tmp;
    end function;

    -- Convert state array to output
    function state_to_output(state: state_array) 
    return STD_LOGIC_VECTOR is
        variable output : STD_LOGIC_VECTOR(127 downto 0);
    begin
        for i in 0 to 3 loop
            for j in 0 to 3 loop
                output(127-8*(4*i+j) downto 120-8*(4*i+j)) := state(i,j);
            end loop;
        end loop;
        return output;
    end function;

    -- Add function to convert state array to hex string
    function state_to_hex_string(state: state_array) return string is
        variable result : string(1 to 32);
        variable byte_val : std_logic_vector(7 downto 0);
    begin
        for i in 0 to 3 loop
            for j in 0 to 3 loop
                byte_val := state(i,j);
                for k in 0 to 1 loop
                    case byte_val((7-4*k) downto (4-4*k)) is
                        when "0000" => result(8*i+2*j+k+1) := '0';
                        when "0001" => result(8*i+2*j+k+1) := '1';
                        when "0010" => result(8*i+2*j+k+1) := '2';
                        when "0011" => result(8*i+2*j+k+1) := '3';
                        when "0100" => result(8*i+2*j+k+1) := '4';
                        when "0101" => result(8*i+2*j+k+1) := '5';
                        when "0110" => result(8*i+2*j+k+1) := '6';
                        when "0111" => result(8*i+2*j+k+1) := '7';
                        when "1000" => result(8*i+2*j+k+1) := '8';
                        when "1001" => result(8*i+2*j+k+1) := '9';
                        when "1010" => result(8*i+2*j+k+1) := 'A';
                        when "1011" => result(8*i+2*j+k+1) := 'B';
                        when "1100" => result(8*i+2*j+k+1) := 'C';
                        when "1101" => result(8*i+2*j+k+1) := 'D';
                        when "1110" => result(8*i+2*j+k+1) := 'E';
                        when "1111" => result(8*i+2*j+k+1) := 'F';
                        when others => result(8*i+2*j+k+1) := 'X';
                    end case;
                end loop;
            end loop;
        end loop;
        return result;
    end function;

begin
    done <= done_i;

    -- Add debug assignments
    debug_state <= state_to_output(state);
    debug_key <= current_round_key;

    -- Main encryption process
    process(clk, rst)
        variable temp_state : state_array;
    begin
        if rst = '1' then
            round <= 0;
            done_i <= '0';
            final_round <= '0';
            state <= (others => (others => (others => '0')));
        elsif rising_edge(clk) then
            case round is
                when 0 =>
                    -- Initial round
                    state <= input_to_state(data_in);
                    current_round_key <= round_keys(1407 downto 1280);
                    round <= round + 1;
                    report "Round 0 input: " & to_hstring(data_in);
                
                when 1 to 9 =>
                    -- Main rounds
                    state <= add_round_key_out;
                    current_round_key <= round_keys(1407-128*round downto 1280-128*round);
                    
                    -- Debug reports
                    report "Round " & integer'image(round);
                    report "After SubBytes: " & to_hstring(state_to_output(sub_bytes_out));
                    report "After ShiftRows: " & to_hstring(state_to_output(shift_rows_out));
                    report "After MixCols: " & to_hstring(state_to_output(mix_columns_out));
                    report "Round Key: " & to_hstring(current_round_key);
                    
                    if round = 9 then
                        final_round <= '1';
                    end if;
                    round <= round + 1;
                
                when 10 =>
                    if not done_i then
                        state <= add_round_key_out;
                        current_round_key <= round_keys(127 downto 0);
                        done_i <= '1';
                        report "Final round output: " & to_hstring(state_to_output(state));
                    end if;
                
                when others => null;
            end case;
        end if;
    end process;

    -- Update state transformation chain
    -- SubBytes
    sub_bytes_matrix: for i in 0 to 3 generate
        sub_bytes_row: for j in 0 to 3 generate
            sb: sub_bytes port map (
                byte_in => state(i,j),
                byte_out => sub_bytes_out(i,j)
            );
        end generate;
    end generate;

    -- ShiftRows
    sr: shift_rows port map (
        state_in => sub_bytes_out,
        state_out => shift_rows_out
    );

    -- MixColumns
    mc: mix_columns port map (
        state_in => shift_rows_out,
        state_out => mix_columns_out
    );

    -- AddRoundKey input selection
    ark_input <= shift_rows_out when final_round = '1' else mix_columns_out;

    -- AddRoundKey
    ark: add_round_key port map (
        state_in => ark_input,
        round_key => current_round_key,
        state_out => add_round_key_out
    );

    -- Key expansion
    key_exp: key_expansion port map (
        key => key,
        round_keys => round_keys
    );

    -- Output assignment
    data_out <= state_to_output(state);

    -- Monitoring process
    process(clk)
    begin
        if rising_edge(clk) then
            monitor_state <= state;
            monitor_key <= current_round_key;
            if not done_i then
                report "Round " & integer'image(round) & 
                       ": After SubBytes = " & to_hstring(state_to_output(sub_bytes_out)) &
                       ", After ShiftRows = " & to_hstring(state_to_output(shift_rows_out)) &
                       ", After MixCols = " & to_hstring(state_to_output(mix_columns_out));
            end if;
        end if;
    end process;

    -- Add monitoring process
    process(clk)
    begin
        if rising_edge(clk) then
            monitor_sub_bytes <= sub_bytes_out;
            monitor_shift_rows <= shift_rows_out;
            monitor_mix_cols <= mix_columns_out;
            if not done_i then
                report "Round " & integer'image(round) & 
                       " State: " & to_hstring(state_to_output(state));
            end if;
        end if;
    end process;

end Behavioral;