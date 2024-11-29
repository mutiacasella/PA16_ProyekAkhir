library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity SubBytes is
    Port (
        data_in  : in  std_logic_vector(127 downto 0); 
        data_out : out std_logic_vector(127 downto 0) 
    );
end SubBytes;

architecture Structural of SubBytes is
    -- Komponen SBox_Table
    component SBox_Table
        Port (
            data_in  : in  std_logic_vector(7 downto 0);
            data_out : out std_logic_vector(7 downto 0)
        );
    end component;

    signal bytes_in  : std_logic_vector(127 downto 0);
    signal bytes_out : std_logic_vector(127 downto 0);
begin
    bytes_in <= data_in;

    -- Mengkonversi data input berdasarkan S-Box
    gen_sbox: for i in 0 to 15 generate
        SBox_Instance: SBox_Table
            Port map (
                data_in  => bytes_in((i+1)*8-1 downto i*8),
                data_out => bytes_out((i+1)*8-1 downto i*8)
            );
    end generate;

    data_out <= bytes_out;
end Structural;