library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity AES_Encryption is
    Port (
        clk          : in  std_logic;
        reset        : in  std_logic;
        start        : in  std_logic;
        plaintext    : in  std_logic_vector(127 downto 0);
        key          : in  std_logic_vector(127 downto 0);
        ciphertext   : out std_logic_vector(127 downto 0);
        done         : out std_logic;
        round_active : in  std_logic; -- Sinyal dari FSM
        round_count  : in  std_logic_vector(3 downto 0)
    );
end AES_Encryption;

architecture Behavioral of AES_Encryption is
    signal current_state   : std_logic_vector(127 downto 0);
    signal round_key       : std_logic_vector(127 downto 0);
    signal addroundkey_out : std_logic_vector(127 downto 0);
    signal subbytes_out    : std_logic_vector(127 downto 0);
    signal shiftrows_out   : std_logic_vector(127 downto 0);
    signal mixcolumns_out  : std_logic_vector(127 downto 0);

    -- Key Expansion Instance
    signal round_keys      : std_logic_vector(1407 downto 0); -- 44 x 32-bit keys (11 x 128-bit keys)
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
        round_key <= round_keys((round_count+1)*128-1 downto round_count*128);
    end process;

    -- Tahap 1: AddRoundKey
    addroundkey_instance: entity work.AddRoundKey
        port map (
            data_in    => plaintext,
            round_key  => round_key,
            data_out   => addroundkey_out
        );

    process(clk, reset)
    begin
        if reset = '1' then
            current_state <= (others => '0');
        elsif rising_edge(clk) then
            if round_active = '1' and round_count = "0000" then
                current_state <= addroundkey_out;
            end if;
        end if;
    end process;

    -- Tahap 2: SubBytes
    subbytes_instance: entity work.SubBytes
        port map (
            data_in  => current_state,
            data_out => subbytes_out
        );

    -- Tahap 3: ShiftRows
    shiftrows_instance: entity work.ShiftRows
        port map (
            data_in  => subbytes_out,
            data_out => shiftrows_out
        );

    -- Tahap 4: MixColumns (untuk ronde 1 hingga 9)
    mixcolumns_instance: entity work.MixColumns
        port map (
            data_in  => shiftrows_out,
            data_out => mixcolumns_out
        );

    -- Update Current State
    process(clk, reset)
    begin
        if reset = '1' then
            current_state <= (others => '0');
        elsif rising_edge(clk) then
            if round_active = '1' then
                if round_count /= "1010" then -- Untuk ronde 1 hingga 9
                    current_state <= mixcolumns_out xor round_key;
                else                          -- Untuk ronde ke-10
                    current_state <= shiftrows_out xor round_key;
                end if;
            end if;
        end if;
    end process;

    -- Output ciphertext
    process(clk, reset)
    begin
        if reset = '1' then
            ciphertext <= (others => '0');
        elsif rising_edge(clk) then
            if done = '1' then
                ciphertext <= current_state;
            end if;
        end if;
    end process;
end Behavioral;