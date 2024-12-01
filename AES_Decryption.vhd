library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity AES_Decryption is
    Port (
        clk          : in  std_logic;
        reset        : in  std_logic;
        start        : in  std_logic;
        ciphertext   : in  std_logic_vector(127 downto 0);
        key          : in  std_logic_vector(127 downto 0);
        plaintext    : out std_logic_vector(127 downto 0);
        done         : out std_logic;
        round_active : in  std_logic; -- Sinyal dari FSM
        round_count  : in  std_logic_vector(3 downto 0) -- Ronde saat ini
    );
end AES_Decryption;

architecture Behavioral of AES_Decryption is
    signal current_state      : std_logic_vector(127 downto 0);
    signal round_key          : std_logic_vector(127 downto 0);
    signal inv_shiftrows_out  : std_logic_vector(127 downto 0);
    signal inv_subbytes_out   : std_logic_vector(127 downto 0);
    signal inv_mixcolumns_out : std_logic_vector(127 downto 0);

    -- Key Expansion Instance
    signal round_keys         : std_logic_vector(1407 downto 0); -- 44 x 32-bit keys (11 x 128-bit keys)
begin
    -- Key Expansion Instance
    key_expansion_instance: entity work.KeyExpansion
        port map (
            key_in      => key,
            round_keys  => round_keys
        );

    -- Round Key Selector
    process(round_count)
    begin
        round_key <= round_keys((10-round_count+1)*128-1 downto (10-round_count)*128);
    end process;

    -- Tahap 1: AddRoundKey (Ronde 0)
    process(clk, reset)
    begin
        if reset = '1' then
            current_state <= (others => '0');
        elsif rising_edge(clk) then
            if round_active = '1' and round_count = "0000" then
                current_state <= ciphertext xor round_key;
            end if;
        end if;
    end process;

    -- Tahap 2: Inv_ShiftRows
    inv_shiftrows_instance: entity work.Inv_ShiftRows
        port map (
            data_in  => current_state,
            data_out => inv_shiftrows_out
        );

    -- Tahap 3: Inv_SubBytes
    inv_subbytes_instance: entity work.Inv_SubBytes
        port map (
            data_in  => inv_shiftrows_out,
            data_out => inv_subbytes_out
        );

    -- Tahap 4: Inv_MixColumns (untuk ronde 1 hingga 9)
    inv_mixcolumns_instance: entity work.Inv_MixColumns
        port map (
            data_in  => inv_subbytes_out,
            data_out => inv_mixcolumns_out
        );

    -- Update Current State
    process(clk, reset)
    begin
        if reset = '1' then
            current_state <= (others => '0');
        elsif rising_edge(clk) then
            if round_active = '1' then
                if round_count /= "1010" then -- Untuk ronde 1 hingga 9
                    current_state <= inv_mixcolumns_out xor round_key;
                else                          -- Untuk ronde ke-10
                    current_state <= inv_subbytes_out xor round_key;
                end if;
            end if;
        end if;
    end process;

    -- Output plaintext
    process(clk, reset)
    begin
        if reset = '1' then
            plaintext <= (others => '0');
        elsif rising_edge(clk) then
            if done = '1' then
                plaintext <= current_state;
            end if;
        end if;
    end process;
end Behavioral;