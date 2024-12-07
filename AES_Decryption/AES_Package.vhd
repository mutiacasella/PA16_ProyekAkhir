-- AES_Package.vhd
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package aes_package is
    type state_array is array (0 to 3, 0 to 3) of STD_LOGIC_VECTOR(7 downto 0);
end package;