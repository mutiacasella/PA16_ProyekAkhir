entity Testbench is
end entity;

architecture Behavioral of Testbench is
    -- Signal declarations for testing AES module
    signal clk         : std_logic := '0';
    signal reset       : std_logic := '0';
    signal start       : std_logic := '0';
    signal plaintext   : std_logic_vector(127 downto 0) := (others => '0');
    signal key         : std_logic_vector(127 downto 0) := (others => '0');
    signal ciphertext  : std_logic_vector(127 downto 0);
    signal done        : std_logic;
begin
    -- Instantiate AES_TOP
    uut: entity work.AES_TOP
        port map ( clk => clk, reset => reset, start => start, 
                   plaintext => plaintext, key => key, 
                   ciphertext => ciphertext, done => done );
    
    -- Clock process
    clk <= not clk after 10 ns;
    
    -- Stimulus process
    process
    begin
        -- Apply stimulus to test AES functionality
        wait for 20 ns;
        start <= '1';
        -- Set plaintext and key
        wait for 40 ns;
        start <= '0';
        wait for 100 ns;
        -- Check results
        assert (ciphertext = expected_ciphertext) report "AES Test failed" severity failure;
        wait;
    end process;
end architecture;
