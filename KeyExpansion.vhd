entity KeyExpansion is
    Port ( key_in     : in  std_logic_vector(127 downto 0);
           round_keys : out std_logic_vector(127 downto 0) );
end entity;

architecture Behavioral of KeyExpansion is
begin
    process(key_in)
    begin
        -- Key Expansion logic to generate round keys
        -- This is a simplified placeholder
        round_keys <= key_in; -- Dummy implementation, expand according to AES Key Expansion algorithm
    end process;
end architecture;
