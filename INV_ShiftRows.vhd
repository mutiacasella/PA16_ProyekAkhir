entity Inv_ShiftRows is
    Port ( data_in    : in  std_logic_vector(127 downto 0);
           data_out   : out std_logic_vector(127 downto 0) );
end entity;

architecture Behavioral of Inv_ShiftRows is
begin
    process(data_in)
    begin
        -- Implement inverse ShiftRows operation
        data_out(127 downto 96) <= data_in(127 downto 96);  -- row 1 (no shift)
        data_out(95 downto 64)  <= data_in(63 downto 32);   -- row 2 (shift 1 right)
        data_out(63 downto 32)  <= data_in(95 downto 64);   -- row 3 (shift 2 right)
        data_out(31 downto 0)   <= data_in(31 downto 0);    -- row 4 (shift 3 right)
    end process;
end architecture;
