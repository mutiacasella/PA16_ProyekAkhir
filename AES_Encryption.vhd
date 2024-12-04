LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY AES_Encryption IS
    PORT (
        clk : IN STD_LOGIC;
        reset : IN STD_LOGIC;
        start : IN STD_LOGIC;
        plaintext : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
        key : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
        ciphertext : OUT STD_LOGIC_VECTOR(127 DOWNTO 0);
        done : OUT STD_LOGIC;
        round_active : IN STD_LOGIC; -- Sinyal dari FSM
        round_count : IN STD_LOGIC_VECTOR(3 DOWNTO 0)
    );
END AES_Encryption;

ARCHITECTURE Behavioral OF AES_Encryption IS
    SIGNAL current_state : STD_LOGIC_VECTOR(127 DOWNTO 0);
    SIGNAL round_key : STD_LOGIC_VECTOR(127 DOWNTO 0);
    SIGNAL addroundkey_out : STD_LOGIC_VECTOR(127 DOWNTO 0);
    SIGNAL subbytes_out : STD_LOGIC_VECTOR(127 DOWNTO 0);
    SIGNAL shiftrows_out : STD_LOGIC_VECTOR(127 DOWNTO 0);
    SIGNAL mixcolumns_out : STD_LOGIC_VECTOR(127 DOWNTO 0);

    -- Key Expansion Instance
    SIGNAL round_keys : STD_LOGIC_VECTOR(1407 DOWNTO 0); -- 44 x 32-bit keys (11 x 128-bit keys)
    SIGNAL done_internal : STD_LOGIC := '0';
BEGIN
    -- Key Expansion Instance
    key_expansion_instance : ENTITY work.KeyExpansion
        PORT MAP(
            key_in => key,
            round_keys => round_keys
        );

    -- Round Key Selector
    PROCESS (round_count)
    BEGIN
        round_key <= round_keys((to_integer(unsigned(round_count)) + 1) * 128 - 1 DOWNTO to_integer(unsigned(round_count)) * 128);
    END PROCESS;

    -- Tahap 1: AddRoundKey
    addroundkey_instance : ENTITY work.AddRoundKey
        PORT MAP(
            data_in => plaintext,
            round_key => round_key,
            data_out => addroundkey_out
        );

    PROCESS (clk, reset)
    BEGIN
        IF reset = '1' THEN
            current_state <= (OTHERS => '0');
        ELSIF rising_edge(clk) THEN
            IF round_active = '1' AND round_count = "0000" THEN
                current_state <= addroundkey_out;
            END IF;
        END IF;
    END PROCESS;

    -- Tahap 2: SubBytes
    subbytes_instance : ENTITY work.SubBytes
        PORT MAP(
            data_in => current_state,
            data_out => subbytes_out
        );

    -- Tahap 3: ShiftRows
    shiftrows_instance : ENTITY work.ShiftRows
        PORT MAP(
            data_in => subbytes_out,
            data_out => shiftrows_out
        );

    -- Tahap 4: MixColumns (untuk ronde 1 hingga 9)
    mixcolumns_instance : ENTITY work.MixColumns
        PORT MAP(
            data_in => shiftrows_out,
            data_out => mixcolumns_out
        );

    -- Update Current State
    PROCESS (clk, reset)
    BEGIN
        IF reset = '1' THEN
            current_state <= (OTHERS => '0');
        ELSIF rising_edge(clk) THEN
            IF round_active = '1' THEN
                IF round_count /= "1010" THEN -- Untuk ronde 1 hingga 9
                    current_state <= mixcolumns_out XOR round_key;
                ELSE -- Untuk ronde ke-10
                    current_state <= shiftrows_out XOR round_key;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    -- Output ciphertext
    PROCESS (clk, reset)
    BEGIN
        IF reset = '1' THEN
            ciphertext <= (OTHERS => '0');
        ELSIF rising_edge(clk) THEN
            IF done_internal = '1' THEN
                ciphertext <= current_state;
            END IF;
        END IF;
    END PROCESS;

    done <= done_internal;
END Behavioral;