-- add_round_key.vhd
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.aes_package.all;

entity add_round_key is
    Port (
        state_in : in state_array;
        round_key : in STD_LOGIC_VECTOR(127 downto 0);
        state_out : out state_array
    );
end add_round_key;

architecture Behavioral of add_round_key is
begin
    process(state_in, round_key)
    begin
        for i in 0 to 3 loop
            for j in 0 to 3 loop
                state_out(i,j) <= state_in(i,j) xor 
                    round_key(127-8*(4*i+j) downto 120-8*(4*i+j));
            end loop;
        end loop;
    end process;
end Behavioral;