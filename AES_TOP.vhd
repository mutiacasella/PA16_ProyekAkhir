LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY AES_TOP IS
    PORT (
        clk : IN STD_LOGIC;
        reset : IN STD_LOGIC;
        start : IN STD_LOGIC;
        mode : IN STD_LOGIC; -- '0': encryption, '1': decryption
        data_in : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
        key : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
        data_out : OUT STD_LOGIC_VECTOR(127 DOWNTO 0);
        done : OUT STD_LOGIC
    );
END AES_TOP;

ARCHITECTURE Behavioral OF AES_TOP IS
    SIGNAL ciphertext : STD_LOGIC_VECTOR(127 DOWNTO 0);
    SIGNAL plaintext : STD_LOGIC_VECTOR(127 DOWNTO 0);
    SIGNAL fsm_done : STD_LOGIC := '0';
    SIGNAL enc_done : STD_LOGIC := '0';
    SIGNAL dec_done : STD_LOGIC := '0';
    SIGNAL round_count : STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');
    SIGNAL round_active : STD_LOGIC := '0';

    SIGNAL start_enc : STD_LOGIC := '0';
    SIGNAL start_dec : STD_LOGIC := '0';

BEGIN
    -- Proses untuk start_enc dan start_dec
    PROCESS (mode, start)
    BEGIN
        IF mode = '0' THEN
            start_enc <= start;
            start_dec <= '0';
        ELSE
            start_enc <= '0';
            start_dec <= start;
        END IF;
    END PROCESS;

    -- FSM Instance
    fsm_instance : ENTITY work.FSM
        PORT MAP(
            clk => clk,
            reset => reset,
            start => start,
            done => fsm_done,
            round_count => round_count,
            round_active => round_active
        );

    -- AES Encryption Instance
    encryption_instance : ENTITY work.AES_Encryption
        PORT MAP(
            clk => clk,
            reset => reset,
            start => start_enc,
            plaintext => data_in,
            key => key,
            ciphertext => ciphertext,
            done => enc_done,
            round_active => round_active,
            round_count => round_count
        );

    -- AES Decryption Instance
    decryption_instance : ENTITY work.AES_Decryption
        PORT MAP(
            clk => clk,
            reset => reset,
            start => start_dec,
            ciphertext => data_in,
            key => key,
            plaintext => plaintext,
            done => dec_done,
            round_active => round_active,
            round_count => round_count
        );

    -- Output data
    data_out <= ciphertext WHEN mode = '0' ELSE
        plaintext;
    done <= fsm_done;

END Behavioral;