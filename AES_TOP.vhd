library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity AES_TOP is
    Port (
        clk         : in  std_logic;
        reset       : in  std_logic;
        start       : in  std_logic;
        mode        : in  std_logic; -- '0': encryption, '1': decryption
        data_in     : in  std_logic_vector(127 downto 0);
        key         : in  std_logic_vector(127 downto 0);
        data_out    : out std_logic_vector(127 downto 0);
        done        : out std_logic
    );
end AES_TOP;

architecture Behavioral of AES_TOP is
    signal ciphertext      : std_logic_vector(127 downto 0);
    signal plaintext       : std_logic_vector(127 downto 0);
    signal fsm_done        : std_logic := '0';
    signal enc_done        : std_logic := '0';
    signal dec_done        : std_logic := '0';
    signal round_count     : std_logic_vector(3 downto 0) := (others => '0');
    signal round_active    : std_logic := '0';
begin
    -- FSM Instance
    fsm_instance: entity work.FSM
        port map (
            clk          => clk,
            reset        => reset,
            start        => start,
            done         => fsm_done,
            round_count  => round_count,
            round_active => round_active
        );

    -- AES Encryption Instance
    encryption_instance: entity work.AES_Encryption
        port map (
            clk          => clk,
            reset        => reset,
            start        => start and (mode = '0'),
            plaintext    => data_in,
            key          => key,
            ciphertext   => ciphertext,
            done         => enc_done, 
            round_active => round_active,
            round_count  => round_count
        );

    -- AES Decryption Instance
    decryption_instance: entity work.AES_Decryption
        port map (
            clk          => clk,
            reset        => reset,
            start        => start and (mode = '1'),
            ciphertext   => data_in,
            key          => key,
            plaintext    => plaintext,
            done         => dec_done, 
            round_active => round_active,
            round_count  => round_count
        );

    -- Output data
    data_out <= ciphertext when mode = '0' else plaintext;
    done <= fsm_done;

end Behavioral;