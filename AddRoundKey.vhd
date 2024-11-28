entity AddRoundKey is
    Port ( data_in    : in  std_logic_vector(127 downto 0);
           round_key  : in  std_logic_vector(127 downto 0);
           data_out   : out std_logic_vector(127 downto 0) );
end entity;

architecture Behavioral of AddRoundKey is
begin
    process(data_in, round_key)
    begin
        -- XOR the data with the round key
        data_out <= data_in xor round_key;
    end process;
end architecture;
