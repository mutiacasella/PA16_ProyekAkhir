LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE work.aes_package.ALL;

ENTITY AES_Decryption IS
    PORT (
        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC;
        data_in : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
        key : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
        data_out : OUT STD_LOGIC_VECTOR(127 DOWNTO 0);
        done : OUT STD_LOGIC;
        -- Debug ports
        debug_state_out : OUT state_array;
        debug_inv_sub_bytes_out : OUT state_array;
        debug_inv_shift_rows_out : OUT state_array;
        debug_inv_mix_cols_out : OUT state_array;
        debug_round_key_out : OUT STD_LOGIC_VECTOR(127 DOWNTO 0)
    );
END AES_Decryption;

ARCHITECTURE Behavioral OF AES_Decryption IS
    -- State signals
    SIGNAL state : state_array;
    SIGNAL round : INTEGER RANGE 0 TO 10;
    SIGNAL done_i : STD_LOGIC;
    SIGNAL round_keys : STD_LOGIC_VECTOR(1407 DOWNTO 0);
    SIGNAL current_round_key : STD_LOGIC_VECTOR(127 DOWNTO 0);
    SIGNAL key_expanded : STD_LOGIC := '0';
    SIGNAL initial_state_loaded : STD_LOGIC := '0';

    -- S-box dan round constants
    TYPE sbox_array IS ARRAY (0 TO 255) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
    CONSTANT SBOX : sbox_array := (
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

    TYPE rcon_array IS ARRAY (1 TO 10) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
    CONSTANT rcon : rcon_array := (
        X"01", X"02", X"04", X"08", X"10", X"20", X"40", X"80", X"1B", X"36"
    );

    FUNCTION state_to_output(state_in : state_array) RETURN STD_LOGIC_VECTOR IS
        VARIABLE result : STD_LOGIC_VECTOR(127 DOWNTO 0);
    BEGIN
        FOR i IN 0 TO 3 LOOP
            FOR j IN 0 TO 3 LOOP
                result(127 - 8 * (4 * i + j) DOWNTO 120 - 8 * (4 * i + j)) := state_in(j, i);
            END LOOP;
        END LOOP;
        RETURN result;
    END FUNCTION;

    FUNCTION to_hstring(slv : STD_LOGIC_VECTOR) RETURN STRING IS
        VARIABLE result : STRING(1 TO slv'length/4);
        VARIABLE nibble : STD_LOGIC_VECTOR(3 DOWNTO 0);
    BEGIN
        FOR i IN result'RANGE LOOP
            nibble := slv(slv'length - i * 4 - 1 DOWNTO slv'length - i * 4 - 4);
            CASE to_integer(unsigned(nibble)) IS
                WHEN 0 => result(i) := '0';
                WHEN 1 => result(i) := '1';
                WHEN 2 => result(i) := '2';
                WHEN 3 => result(i) := '3';
                WHEN 4 => result(i) := '4';
                WHEN 5 => result(i) := '5';
                WHEN 6 => result(i) := '6';
                WHEN 7 => result(i) := '7';
                WHEN 8 => result(i) := '8';
                WHEN 9 => result(i) := '9';
                WHEN 10 => result(i) := 'a';
                WHEN 11 => result(i) := 'b';
                WHEN 12 => result(i) := 'c';
                WHEN 13 => result(i) := 'd';
                WHEN 14 => result(i) := 'e';
                WHEN 15 => result(i) := 'f';
                WHEN OTHERS => result(i) := 'x';
            END CASE;
        END LOOP;
        RETURN result;
    END FUNCTION;

    -- Inverse SubBytes transformation
    FUNCTION inv_sub_bytes(state_in : state_array) RETURN state_array IS
        VARIABLE result : state_array;
    BEGIN
        FOR i IN 0 TO 3 LOOP
            FOR j IN 0 TO 3 LOOP
                result(i, j) := SBOX(to_integer(unsigned(state_in(i, j))));
            END LOOP;
        END LOOP;
        RETURN result;
    END FUNCTION;

    -- Inverse ShiftRows transformation
    FUNCTION inv_shift_rows(state_in : state_array) RETURN state_array IS
        VARIABLE result : state_array;
    BEGIN
        -- Row 0: no shift
        result(0, 0) := state_in(0, 0);
        result(0, 1) := state_in(0, 1);
        result(0, 2) := state_in(0, 2);
        result(0, 3) := state_in(0, 3);

        -- Row 1: shift right by 1
        result(1, 0) := state_in(1, 3);
        result(1, 1) := state_in(1, 0);
        result(1, 2) := state_in(1, 1);
        result(1, 3) := state_in(1, 2);

        -- Row 2: shift right by 2
        result(2, 0) := state_in(2, 2);
        result(2, 1) := state_in(2, 3);
        result(2, 2) := state_in(2, 0);
        result(2, 3) := state_in(2, 1);

        -- Row 3: shift right by 3
        result(3, 0) := state_in(3, 1);
        result(3, 1) := state_in(3, 2);
        result(3, 2) := state_in(3, 3);
        result(3, 3) := state_in(3, 0);

        RETURN result;
    END FUNCTION;

    -- Inverse MixColumns transformation
    FUNCTION inv_mix_columns(state_in : state_array) RETURN state_array IS
        VARIABLE result : state_array;
    BEGIN
        FOR col IN 0 TO 3 LOOP
            result(0, col) := gf_mult(X"0e", state_in(0, col)) XOR
            gf_mult(X"0b", state_in(1, col)) XOR
            gf_mult(X"0d", state_in(2, col)) XOR
            gf_mult(X"09", state_in(3, col));

            result(1, col) := gf_mult(X"09", state_in(0, col)) XOR
            gf_mult(X"0e", state_in(1, col)) XOR
            gf_mult(X"0b", state_in(2, col)) XOR
            gf_mult(X"0d", state_in(3, col));

            result(2, col) := gf_mult(X"0d", state_in(0, col)) XOR
            gf_mult(X"09", state_in(1, col)) XOR
            gf_mult(X"0e", state_in(2, col)) XOR
            gf_mult(X"0b", state_in(3, col));

            result(3, col) := gf_mult(X"0b", state_in(0, col)) XOR
            gf_mult(X"0d", state_in(1, col)) XOR
            gf_mult(X"09", state_in(2, col)) XOR
            gf_mult(X" 0e", state_in(3, col));
        END LOOP;
        RETURN result;
    END FUNCTION;

BEGIN
    -- Key expansion process
    PROCESS (clk, rst)
        TYPE word_array IS ARRAY (0 TO 43) OF STD_LOGIC_VECTOR(31 DOWNTO 0);
        VARIABLE w : word_array;
        VARIABLE temp : STD_LOGIC_VECTOR(31 DOWNTO 0);
    BEGIN
        IF rst = '1' THEN
            key_expanded <= '0';
            round_keys <= (OTHERS => '0');
        ELSIF rising_edge(clk) THEN
            IF NOT key_expanded THEN
                -- Store original key as first round key
                round_keys(1407 DOWNTO 1280) <= key;

                -- Initialize w with key
                w(0) := key(127 DOWNTO 96);
                w(1) := key(95 DOWNTO 64);
                w(2) := key(63 DOWNTO 32);
                w(3) := key(31 DOWNTO 0);

                -- Generate remaining words
                FOR i IN 4 TO 43 LOOP
                    temp := w(i - 1);
                    IF (i MOD 4 = 0) THEN
                        -- RotWord
                        temp := temp(23 DOWNTO 0) & temp(31 DOWNTO 24);
                        -- SubWord
                        FOR j IN 0 TO 3 LOOP
                            temp(31 - 8 * j DOWNTO 24 - 8 * j) :=
                            SBOX(to_integer(unsigned(temp(31 - 8 * j DOWNTO 24 - 8 * j))));
                        END LOOP;
                        -- XOR with Rcon
                        temp := temp XOR (rcon(i/4) & X"000000");
                    END IF;
                    w(i) := w(i - 4) XOR temp;

                    -- Pack round keys as they are generated
                    IF (i MOD 4 = 3) AND (i > 3) THEN
                        round_keys(1407 - 128 * (i/4) DOWNTO 1280 - 128 * (i/4)) <=
                        w(i - 3) & w(i - 2) & w(i - 1) & w(i);
                    END IF;
                END LOOP;

                key_expanded <= '1';
            END IF;
        END IF;
    END PROCESS;

    -- Main decryption process
    main_proc : PROCESS (clk, rst)
        VARIABLE next_state : state_array;
    BEGIN
        IF rst = '1' THEN
            round <= 0;
            done_i <= '0';
            state <= (OTHERS => (OTHERS => (OTHERS => '0')));
        ELSIF rising_edge(clk) THEN
            IF key_expanded = '1' THEN -- Wait for key expansion
                CASE round IS
                    WHEN 0 =>
                        -- Initial state loading and AddRoundKey
                        FOR col IN 0 TO 3 LOOP
                            FOR row IN 0 TO 3 LOOP
                                state(row, col) <= data_in(127 - 8 * (4 * col + row) DOWNTO 120 - 8 * (4 * col + row)) XOR
                                key(127 - 8 * (4 * col + row) DOWNTO 120 - 8 * (4 * col + row));
                            END LOOP;
                        END LOOP;

                        -- Prepare key for next round
                        current_round_key <= round_keys(1279 DOWNTO 1152);
                        round <= round + 1;
                        initial_state_loaded <= '1';

                    WHEN 1 TO 9 =>
                        -- Apply transformations in sequence
                        next_state := inv_sub_bytes(state);
                        next_state := inv_shift_rows(next_state);
                        next_state := inv_mix_columns(next_state);

                        -- AddRoundKey with proper key selection
                        FOR col IN 0 TO 3 LOOP
                            FOR row IN 0 TO 3 LOOP
                                state(row, col) <= next_state(row, col) XOR
                                current_round_key(127 - 8 * (4 * col + row) DOWNTO 120 - 8 * (4 * col + row));
                            END LOOP;
                        END LOOP;

                        -- Update round key untuk round berikutnya
                        current_round_key <= round_keys(1279 - 128 * round DOWNTO 1152 - 128 * round);
                        round <= round + 1;

                    WHEN 10 =>
                        IF NOT done_i THEN
                            next_state := inv_sub_bytes(state);
                            next_state := inv_shift_rows(next_state);

                            -- Final AddRoundKey
                            FOR i IN 0 TO 3 LOOP
                                FOR j IN 0 TO 3 LOOP
                                    state(j, i) <= next_state(j, i) XOR
                                    current_round_key(127 - 8 * (4 * i + j) DOWNTO 120 - 8 * (4 * i + j));
                                END LOOP;
                            END LOOP;
                            done_i <= '1';
                        END IF;

                    WHEN OTHERS => NULL;
                END CASE;
            END IF;
        END IF;
    END PROCESS;

    -- Debug process
    debug_proc : PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            -- Update debug signals
            debug_state_out <= state;
            debug_inv_sub_bytes_out <= inv_sub_bytes(state);
            debug_inv_shift_rows_out <= inv_shift_rows(inv_sub_bytes(state));
            debug_inv_mix_cols_out <= inv_mix_columns(inv_shift_rows(inv_sub_bytes(state)));
            debug_round_key_out <= current_round_key WHEN round > 0 ELSE
                key;

            -- Show transformations only after initial state loaded
            IF initial_state_loaded = '1' OR round > 0 THEN
                debug_inv_sub_bytes_out <= inv_sub_bytes(state);
                debug_inv_shift_rows_out <= inv_shift_rows(inv_sub_bytes(state));
                debug_inv_mix_cols_out <= inv_mix_columns(inv_shift_rows(inv_sub_bytes(state)));
            END IF;
        END IF;
    END PROCESS;

    -- Output assignment
    done <= done_i;

    -- Convert state to output
    output_process : PROCESS (state)
        VARIABLE temp : STD_LOGIC_VECTOR(127 DOWNTO 0);
    BEGIN
        FOR col IN 0 TO 3 LOOP
            FOR row IN 0 TO 3 LOOP
                temp(127 - 8 * (4 * col + row) DOWNTO 120 - 8 * (4 * col + row)) := state(row, col);
            END LOOP;
        END LOOP;
        data_out <= temp;
    END PROCESS;

END Behavioral;