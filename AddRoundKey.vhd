library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity AddRoundKey is
    Port (
        data_in    : in  std_logic_vector(127 downto 0);
        round_key  : in  std_logic_vector(127 downto 0);
        data_out   : out std_logic_vector(127 downto 0)
    );
end AddRoundKey;

architecture Behavioral of AddRoundKey is
begin
    process(data_in, round_key)
    begin
        data_out <= data_in xor round_key;
    end process;
end Behavioral;
