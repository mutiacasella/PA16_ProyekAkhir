library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Decryption_Control is
    Port (
        clk         : in  std_logic;
        reset       : in  std_logic;
        start       : in  std_logic;
        ciphertext  : in  std_logic_vector(127 downto 0);
        key         : in  std_logic_vector(127 downto 0);
        plaintext   : out std_logic_vector(127 downto 0);
        done        : out std_logic
    );
end Decryption_Control;

architecture Behavioral of Decryption_Control is
    signal temp_plaintext : std_logic_vector(127 downto 0);
    signal ready          : std_logic := '0';
begin
    process(clk, reset)
    begin
        if reset = '1' then
            temp_plaintext <= (others => '0');
            ready <= '0';
        elsif rising_edge(clk) then
            if start = '1' then
                -- Example decryption logic
                temp_plaintext <= ciphertext xor key; -- Simple XOR operation
                ready <= '1';
            end if;
        end if;
    end process;
    plaintext <= temp_plaintext;
    done <= ready;
end Behavioral;
