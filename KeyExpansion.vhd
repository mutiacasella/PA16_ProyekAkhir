library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity KeyExpansion is
    Port (
        key_in      : in  std_logic_vector(127 downto 0);
        round_keys  : out std_logic_vector(1407 downto 0) 
    );
end KeyExpansion;

architecture Structural of KeyExpansion is
    -- Komponen SBox_Table
    component SBox_Table
        Port (
            data_in  : in  std_logic_vector(7 downto 0);
            data_out : out std_logic_vector(7 downto 0)
        );
    end component;

    -- Rcon Table
    type RconArray is array (0 to 9) of std_logic_vector(31 downto 0);
    constant Rcon : RconArray := (
        X"01000000", X"02000000", X"04000000", X"08000000", X"10000000", 
        X"20000000", X"40000000", X"80000000", X"1B000000", X"36000000"
    );

    signal w : std_logic_vector(1407 downto 0); -- Semua word
    signal temp : std_logic_vector(31 downto 0); 
    signal subword_var : std_logic_vector(31 downto 0); -- Output SubWord

    -- Sinyal untuk menghubungkan komponen SBox_Table
    signal sbox_in : std_logic_vector(31 downto 0);
    signal sbox_out : std_logic_vector(31 downto 0);

    -- RotWord 
    function RotWord(word_in : std_logic_vector(31 downto 0)) return std_logic_vector is
    begin
        return word_in(23 downto 0) & word_in(31 downto 24);
    end function;

begin

    -- Instansiasi Komponen SBox_Table untuk SubWord
    SBox_Byte0: SBox_Table
        Port map (
            data_in  => sbox_in(31 downto 24),
            data_out => sbox_out(31 downto 24)
        );

    SBox_Byte1: SBox_Table
        Port map (
            data_in  => sbox_in(23 downto 16),
            data_out => sbox_out(23 downto 16)
        );

    SBox_Byte2: SBox_Table
        Port map (
            data_in  => sbox_in(15 downto 8),
            data_out => sbox_out(15 downto 8)
        );

    SBox_Byte3: SBox_Table
        Port map (
            data_in  => sbox_in(7 downto 0),
            data_out => sbox_out(7 downto 0)
        );

    -- Proses Key Expansion
    process(key_in)
        variable temp_var : std_logic_vector(31 downto 0);
    begin
        -- Inisialisasi kata pertama
        w(127 downto 0) <= key_in;

        -- Expand kata berikutnya
        for i in 4 to 43 loop
            if i mod 4 = 0 then
                -- RotWord
                temp_var := RotWord(w((i-1)*32+31 downto (i-1)*32));

                -- SubWord
                sbox_in <= temp_var; 
                temp_var := sbox_out xor Rcon((i/4)-1);
            else
                temp_var := w((i-1)*32+31 downto (i-1)*32);
            end if;
            w(i*32+31 downto i*32) <= temp_var xor w((i-4)*32+31 downto (i-4)*32);
        end loop;

        round_keys <= w;
    end process;

end Structural;