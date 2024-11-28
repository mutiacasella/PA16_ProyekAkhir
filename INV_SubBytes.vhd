entity Inv_SubBytes is
    Port ( data_in    : in  std_logic_vector(127 downto 0);
           data_out   : out std_logic_vector(127 downto 0) );
end entity;

architecture Behavioral of Inv_SubBytes is
    -- Internal Inverse S-box (you can define it similarly to the S-box for encryption)
begin
    process(data_in)
    begin
        -- Inverse S-box lookup and substitution logic
        -- This would implement the inverse S-box
    end process;
end architecture;
