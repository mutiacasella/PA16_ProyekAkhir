library IEEE;
use IEEE.STD_LOGIC_1164.ALL; -- Untuk std_logic dan std_logic_vector

entity Inv_SubBytes is
    Port (
        data_in  : in  std_logic_vector(127 downto 0);
        data_out : out std_logic_vector(127 downto 0)
    );
end Inv_SubBytes;

architecture Behavioral of Inv_SubBytes is
begin
    process(data_in)
    begin
        -- Implementasi substitusi invers berdasarkan S-box
        data_out <= data_in; -- Placeholder, implementasikan logika sesuai kebutuhan
    end process;
end Behavioral;
