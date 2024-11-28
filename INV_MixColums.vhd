entity Inv_MixColumns is
    Port ( data_in    : in  std_logic_vector(127 downto 0);
           data_out   : out std_logic_vector(127 downto 0) );
end entity;

architecture Behavioral of Inv_MixColumns is
begin
    process(data_in)
    begin
        -- Implement inverse MixColumns operation using predefined inverse matrix
    end process;
end architecture;
