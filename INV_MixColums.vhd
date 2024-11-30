library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity INV_MixColumns is
    Port (
        data_in  : in  std_logic_vector(127 downto 0);  
        data_out : out std_logic_vector(127 downto 0) 
    );
end INV_MixColumns;

architecture Behavioral of INV_MixColumns is
    -- Perkalian matriks Galois Field GF(2⁸)
    function gf_mult(a: std_logic_vector(7 downto 0); b: std_logic_vector(7 downto 0)) return std_logic_vector is
        variable result : std_logic_vector(7 downto 0) := (others => '0');
        variable temp_a : std_logic_vector(7 downto 0);
        variable temp_b : std_logic_vector(7 downto 0);
    begin
        temp_a := a;
        temp_b := b;

        for i in 0 to 7 loop
            if temp_b(0) = '1' then
                result := result xor temp_a;
            end if;

            if temp_a(7) = '1' then
                temp_a := (temp_a(6 downto 0) & '0') xor X"1B"; -- Modular XOR dengan x⁸ + x⁴ + x³ + x + 1 
            else
                temp_a := temp_a(6 downto 0) & '0';
            end if;

            temp_b := '0' & temp_b(7 downto 1);
        end loop;

        return result;
    end function;

    -- Matriks untuk Inverse MixColumns
    constant INV_MIX_MATRIX : array(0 to 3, 0 to 3) of std_logic_vector(7 downto 0) := (
        ("00001110", "00001011", "00001101", "00001001"),
        ("00001001", "00001110", "00001011", "00001101"), 
        ("00001101", "00001001", "00001110", "00001011"),
        ("00001011", "00001101", "00001001", "00001110")
    );

begin
    process(data_in)
        variable state_in  : array(0 to 3, 0 to 3) of std_logic_vector(7 downto 0);
        variable state_out : array(0 to 3, 0 to 3) of std_logic_vector(7 downto 0);
        variable result    : std_logic_vector(127 downto 0);
    begin
        -- Load input ke dalam matriks 4x4
        for i in 0 to 3 loop
            for j in 0 to 3 loop
                state_in(j, i) := data_in((i*32 + j*8 + 7) downto (i*32 + j*8));
            end loop;
        end loop;

        -- Operasi Inverse MixColumns
        for i in 0 to 3 loop
            for j in 0 to 3 loop
                state_out(j, i) := 
                    gf_mult(state_in(0, i), INV_MIX_MATRIX(j, 0)) xor
                    gf_mult(state_in(1, i), INV_MIX_MATRIX(j, 1)) xor
                    gf_mult(state_in(2, i), INV_MIX_MATRIX(j, 2)) xor
                    gf_mult(state_in(3, i), INV_MIX_MATRIX(j, 3));
            end loop;
        end loop;

        -- Hasil perkalian matriks disimpan ke data_out
        for i in 0 to 3 loop
            for j in 0 to 3 loop
                result((i*32 + j*8 + 7) downto (i*32 + j*8)) := state_out(j, i);
            end loop;
        end loop;

        data_out <= result;
    end process;
end Behavioral;