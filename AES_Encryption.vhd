entity AES_Encryption is
    Port ( clk         : in  std_logic;
           reset       : in  std_logic;
           start       : in  std_logic;
           plaintext   : in  std_logic_vector(127 downto 0);
           key         : in  std_logic_vector(127 downto 0);
           ciphertext  : out std_logic_vector(127 downto 0);
           done        : out std_logic );
end entity;

architecture Behavioral of AES_Encryption is
    -- Signal declarations for submodules (for example, SubBytes, AddRoundKey, etc.)
begin
    -- Instantiate submodules and connect signals accordingly

end architecture;
