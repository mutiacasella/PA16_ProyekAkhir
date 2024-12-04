LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY ShiftRows IS
    PORT (
        data_in : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
        data_out : OUT STD_LOGIC_VECTOR(127 DOWNTO 0)
    );
END ShiftRows;

ARCHITECTURE Behavioral OF ShiftRows IS
BEGIN
    PROCESS (data_in)
    BEGIN
        -- Row 1: no shift
        data_out(127 DOWNTO 96) <= data_in(127 DOWNTO 96);
        -- Row 2: shift left 1
        data_out(95 DOWNTO 64) <= data_in(87 DOWNTO 64) & data_in(95 DOWNTO 88);
        -- Row 3: shift left 2
        data_out(63 DOWNTO 32) <= data_in(47 DOWNTO 32) & data_in(63 DOWNTO 48);
        -- Row 4: shift left 3
        data_out(31 DOWNTO 0) <= data_in(7 DOWNTO 0) & data_in(31 DOWNTO 8);
    END PROCESS;
END Behavioral;