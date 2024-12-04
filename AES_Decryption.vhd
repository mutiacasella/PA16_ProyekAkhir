LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY AES_Decryption IS
    PORT (
        clk : IN STD_LOGIC;
        reset : IN STD_LOGIC;
        start : IN STD_LOGIC;
        ciphertext : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
        key : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
        plaintext : OUT STD_LOGIC_VECTOR(127 DOWNTO 0);
        done : OUT STD_LOGIC;
        round_active : IN STD_LOGIC; -- Sinyal dari FSM
        round_count : IN STD_LOGIC_VECTOR(3 DOWNTO 0) -- Ronde saat ini
    );
END AES_Decryption;

ARCHITECTURE Behavioral OF AES_Decryption IS
    SIGNAL current_state : STD_LOGIC_VECTOR(127 DOWNTO 0);
    SIGNAL round_key : STD_LOGIC_VECTOR(127 DOWNTO 0);
    SIGNAL addroundkey_out : STD_LOGIC_VECTOR(127 DOWNTO 0);
    SIGNAL inv_shiftrows_out : STD_LOGIC_VECTOR(127 DOWNTO 0);
    SIGNAL inv_subbytes_out : STD_LOGIC_VECTOR(127 DOWNTO 0);
    SIGNAL inv_mixcolumns_out : STD_LOGIC_VECTOR(127 DOWNTO 0);

    -- Key Expansion Instance
    SIGNAL round_keys : STD_LOGIC_VECTOR(1407 DOWNTO 0); -- 44 x 32-bit keys (11 x 128-bit keys)
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
        round_key <= round_keys((10 - round_count + 1) * 128 - 1 DOWNTO (10 - round_count) * 128);
    END PROCESS;

    -- Tahap 1: AddRoundKey
    addroundkey_instance : ENTITY work.AddRoundKey
        PORT MAP(
            data_in => ciphertext,
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

    -- Tahap 2: Inv_ShiftRows
    inv_shiftrows_instance : ENTITY work.Inv_ShiftRows
        PORT MAP(
            data_in => current_state,
            data_out => inv_shiftrows_out
        );

    -- Tahap 3: Inv_SubBytes
    inv_subbytes_instance : ENTITY work.Inv_SubBytes
        PORT MAP(
            data_in => inv_shiftrows_out,
            data_out => inv_subbytes_out
        );

    -- Tahap 4: Inv_MixColumns (untuk ronde 1 hingga 9)
    inv_mixcolumns_instance : ENTITY work.Inv_MixColumns
        PORT MAP(
            data_in => inv_subbytes_out,
            data_out => inv_mixcolumns_out
        );

    -- Update Current State
    PROCESS (clk, reset)
    BEGIN
        IF reset = '1' THEN
            current_state <= (OTHERS => '0');
        ELSIF rising_edge(clk) THEN
            IF round_active = '1' THEN
                IF round_count /= "1010" THEN -- Untuk ronde 1 hingga 9
                    current_state <= inv_mixcolumns_out XOR round_key;
                ELSE -- Untuk ronde ke-10
                    current_state <= inv_subbytes_out XOR round_key;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    -- Output plaintext
    PROCESS (clk, reset)
    BEGIN
        IF reset = '1' THEN
            plaintext <= (OTHERS => '0');
        ELSIF rising_edge(clk) THEN
            IF done = '1' THEN
                plaintext <= current_state;
            END IF;
        END IF;
    END PROCESS;
END Behavioral;