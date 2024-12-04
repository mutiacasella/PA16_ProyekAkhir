LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY FSM IS
    PORT (
        clk : IN STD_LOGIC;
        reset : IN STD_LOGIC;
        start : IN STD_LOGIC;
        done : OUT STD_LOGIC;
        round_count : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        round_active : OUT STD_LOGIC -- Untuk sinkronisasi antar ronde
    );
END FSM;

ARCHITECTURE Behavioral OF FSM IS
    -- Deklarasi tipe enumerasi untuk state FSM
    TYPE state_type IS (IDLE, EXECUTE, FINISH);

    -- Deklarasi sinyal internal untuk state dan counter
    SIGNAL state : state_type := IDLE;
    SIGNAL count : STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');
    SIGNAL active_round : STD_LOGIC := '0';
BEGIN
    -- Proses utama FSM
    PROCESS (clk, reset)
    BEGIN
        IF reset = '1' THEN
            -- Reset FSM ke kondisi awal
            state <= IDLE;
            count <= (OTHERS => '0');
            active_round <= '0';
        ELSIF rising_edge(clk) THEN
            CASE state IS
                WHEN IDLE =>
                    IF start = '1' THEN
                        state <= EXECUTE;
                        count <= "0000";
                        active_round <= '1';
                    END IF;

                WHEN EXECUTE =>
                    IF count = "1010" THEN -- 10 round untuk AES-128
                        state <= FINISH;
                        active_round <= '0';
                    ELSE
                        count <= STD_LOGIC_VECTOR(unsigned(count) + 1);
                        active_round <= '1';
                    END IF;

                WHEN FINISH =>
                    state <= IDLE; -- Kembali ke IDLE setelah selesai
                    count <= (OTHERS => '0');
                    active_round <= '0';

                WHEN OTHERS =>
                    state <= IDLE;
            END CASE;
        END IF;
    END PROCESS;

    done <= '1' WHEN state = FINISH ELSE
        '0';
    round_count <= count;
    round_active <= active_round;
END Behavioral;