-- shift_rows.vhd
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.aes_package.all;

entity shift_rows is
    Port (
        state_in : in state_array;
        state_out : out state_array
    );
end shift_rows;

architecture Behavioral of shift_rows is
begin
    -- Row 0: no shift
    state_out(0,0) <= state_in(0,0);
    state_out(0,1) <= state_in(0,1);
    state_out(0,2) <= state_in(0,2);
    state_out(0,3) <= state_in(0,3);
    
    -- Row 1: shift left by 1
    state_out(1,0) <= state_in(1,1);
    state_out(1,1) <= state_in(1,2);
    state_out(1,2) <= state_in(1,3);
    state_out(1,3) <= state_in(1,0);
    
    -- Row 2: shift left by 2
    state_out(2,0) <= state_in(2,2);
    state_out(2,1) <= state_in(2,3);
    state_out(2,2) <= state_in(2,0);
    state_out(2,3) <= state_in(2,1);
    
    -- Row 3: shift left by 3
    state_out(3,0) <= state_in(3,3);
    state_out(3,1) <= state_in(3,0);
    state_out(3,2) <= state_in(3,1);
    state_out(3,3) <= state_in(3,2);
end Behavioral;