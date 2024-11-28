LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY Inv_ShiftRows IS
    PORT (
        data_in : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
        data_out : OUT STD_LOGIC_VECTOR(127 DOWNTO 0)
    );
END Inv_ShiftRows;

ARCHITECTURE Behavioral OF Inv_ShiftRows IS
BEGIN
    PROCESS (data_in)
    BEGIN
        -- Row 1: no shift
        data_out(127 DOWNTO 96) <= data_in(127 DOWNTO 96);
        -- Row 2: shift 1
        data_out(95 DOWNTO 64) <= data_in(63 DOWNTO 32);
        -- Row 3: shift 2
        data_out(63 DOWNTO 32) <= data_in(95 DOWNTO 64);
        -- Row 4: shift 3
        data_out(31 DOWNTO 0) <= data_in(31 DOWNTO 0);
    END PROCESS;
END Behavioral;