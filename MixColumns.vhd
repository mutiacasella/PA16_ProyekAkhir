LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY MixColumns IS
    PORT (
        data_in : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
        data_out : OUT STD_LOGIC_VECTOR(127 DOWNTO 0)
    );
END MixColumns;

ARCHITECTURE Behavioral OF MixColumns IS
    -- Perkalian matriks Galois Field GF(2⁸)
    FUNCTION gf_mult(a : STD_LOGIC_VECTOR(7 DOWNTO 0); b : STD_LOGIC_VECTOR(7 DOWNTO 0)) RETURN STD_LOGIC_VECTOR IS
        VARIABLE result : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
        VARIABLE temp_a : STD_LOGIC_VECTOR(7 DOWNTO 0);
        VARIABLE temp_b : STD_LOGIC_VECTOR(7 DOWNTO 0);
    BEGIN
        temp_a := a;
        temp_b := b;

        FOR i IN 0 TO 7 LOOP
            -- Jika bit LSB temp_b adalah 1, tambahkan temp_a ke hasil (XOR di GF(2⁸))
            IF temp_b(0) = '1' THEN
                result := result XOR temp_a;
            END IF;

            -- Shift temp_a ke kiri dan lakukan modular reduction jika bit MSB-nya 1
            IF temp_a(7) = '1' THEN
                temp_a := (temp_a(6 DOWNTO 0) & '0') XOR X"1B"; -- Modular XOR dengan x⁸ + x⁴ + x³ + x + 1 
            ELSE
                temp_a := temp_a(6 DOWNTO 0) & '0';
            END IF;

            -- Shift temp_b ke kanan
            temp_b := '0' & temp_b(7 DOWNTO 1);
        END LOOP;

        RETURN result;
    END FUNCTION;

    -- Tipe untuk merepresentasikan matriks
    TYPE matrix_4x4 IS ARRAY (0 TO 3, 0 TO 3) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
    TYPE column IS ARRAY (0 TO 3) OF STD_LOGIC_VECTOR(7 DOWNTO 0);

    -- Matriks untuk MixColumns
    --CONSTANT MIX_MATRIX : matrix_4x4 := (
    --("00000010", "00000003", "00000001", "00000001"),
    --    ("00000001", "00000002", "00000003", "00000001"),
    --    ("00000001", "00000001", "00000002", "00000003"),
    --    ("00000003", "00000001", "00000001", "00000002")
    --);

    constant MIX_MATRIX : matrix_4x4 := (
        (X"02", X"03", X"01", X"01"),
        (X"01", X"02", X"03", X"01"),
        (X"01", X"01", X"02", X"03"),
        (X"03", X"01", X"01", X"02")
    );

BEGIN
    PROCESS (data_in)
        VARIABLE state_in : matrix_4x4;
        VARIABLE state_out : matrix_4x4;
        VARIABLE result : STD_LOGIC_VECTOR(127 DOWNTO 0);
    BEGIN
        -- Load input ke dalam matriks 4x4
        FOR i IN 0 TO 3 LOOP
            FOR j IN 0 TO 3 LOOP
                state_in(j, i) := data_in((i * 32 + j * 8 + 7) DOWNTO (i * 32 + j * 8));
            END LOOP;
        END LOOP;

        -- Operasi MixColumns
        FOR i IN 0 TO 3 LOOP
            FOR j IN 0 TO 3 LOOP
                state_out(j, i) :=
                gf_mult(state_in(0, i), MIX_MATRIX(j, 0)) XOR
                gf_mult(state_in(1, i), MIX_MATRIX(j, 1)) XOR
                gf_mult(state_in(2, i), MIX_MATRIX(j, 2)) XOR
                gf_mult(state_in(3, i), MIX_MATRIX(j, 3));
            END LOOP;
        END LOOP;

        -- Hasil perkalian matriks disimpan ke data_out
        FOR i IN 0 TO 3 LOOP
            FOR j IN 0 TO 3 LOOP
                result((i * 32 + j * 8 + 7) DOWNTO (i * 32 + j * 8)) := state_out(j, i);
            END LOOP;
        END LOOP;

        data_out <= result;
    END PROCESS;
END Behavioral;