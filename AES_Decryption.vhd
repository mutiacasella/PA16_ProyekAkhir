entity Decryption_Control is
    Port ( clk         : in  std_logic;
           reset       : in  std_logic;
           start       : in  std_logic;
           ciphertext  : in  std_logic_vector(127 downto 0);
           key         : in  std_logic_vector(127 downto 0);
           plaintext   : out std_logic_vector(127 downto 0);
           done        : out std_logic );
end entity;

architecture Behavioral of Decryption_Control is
    -- Instantiate decryption submodules
begin
    -- Decryption logic here (similar to encryption but with inverse steps)
end architecture;
