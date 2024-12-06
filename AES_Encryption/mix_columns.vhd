-- mix_columns.vhd
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.aes_package.all;

entity mix_columns is
    Port (
        state_in : in state_array;
        state_out : out state_array
    );
end mix_columns;

architecture Behavioral of mix_columns is
    function gmul(a, b: STD_LOGIC_VECTOR(7 downto 0)) return STD_LOGIC_VECTOR is
        variable p: STD_LOGIC_VECTOR(7 downto 0);
        variable hi_bit: STD_LOGIC;
        variable temp: STD_LOGIC_VECTOR(7 downto 0);
    begin
        p := (others => '0');
        temp := a;
        
        for i in 0 to 7 loop
            if (b(i) = '1') then
                p := p xor temp;
            end if;
            hi_bit := temp(7);
            temp := temp(6 downto 0) & '0';
            if (hi_bit = '1') then
                temp := temp xor X"1B"; -- Reduction polynomial x^8 + x^4 + x^3 + x + 1
            end if;
        end loop;
        return p;
    end function;

begin
    process(state_in)
        variable temp: state_array;
    begin
        for col in 0 to 3 loop
            temp(0,col) :=  gmul(X"02", state_in(0,col)) xor 
                            gmul(X"03", state_in(1,col)) xor 
                            state_in(2,col) xor 
                            state_in(3,col);

            temp(1,col) :=  state_in(0,col) xor 
                            gmul(X"02", state_in(1,col)) xor 
                            gmul(X"03", state_in(2,col)) xor 
                            state_in(3,col);

            temp(2,col) :=  state_in(0,col) xor 
                            state_in(1,col) xor 
                            gmul(X"02", state_in(2,col)) xor 
                            gmul(X"03", state_in(3,col));

            temp(3,col) :=  gmul(X"03", state_in(0,col)) xor 
                            state_in(1,col) xor 
                            state_in(2,col) xor 
                            gmul(X"02", state_in(3,col));
        end loop;
        state_out <= temp;
    end process;
end Behavioral;