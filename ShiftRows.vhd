library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ShiftRows is
    Port (
        data_in  : in  std_logic_vector(127 downto 0);
        data_out : out std_logic_vector(127 downto 0)
    );
end ShiftRows;

architecture Behavioral of ShiftRows is
begin
    process(data_in)
    begin
        -- Row 1: no shift
        data_out(127 downto 96) <= data_in(127 downto 96);
        -- Row 2: shift left 1
        data_out(95 downto 64)  <= data_in(87 downto 56) & data_in(95 downto 88);
        -- Row 3: shift left 2
        data_out(63 downto 32)  <= data_in(47 downto 32) & data_in(63 downto 48);
        -- Row 4: shift left 3
        data_out(31 downto 0)   <= data_in(7 downto 0) & data_in(31 downto 8);
    end process;
end Behavioral;
