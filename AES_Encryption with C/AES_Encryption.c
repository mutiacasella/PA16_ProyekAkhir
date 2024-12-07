#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <ctype.h>

// Complete S-box array
static const uint8_t sbox[256] = {
    0x63, 0x7c, 0x77, 0x7b, 0xf2, 0x6b, 0x6f, 0xc5, 0x30, 0x01, 0x67, 0x2b, 0xfe, 0xd7, 0xab, 0x76,
    0xca, 0x82, 0xc9, 0x7d, 0xfa, 0x59, 0x47, 0xf0, 0xad, 0xd4, 0xa2, 0xaf, 0x9c, 0xa4, 0x72, 0xc0,
    0xb7, 0xfd, 0x93, 0x26, 0x36, 0x3f, 0xf7, 0xcc, 0x34, 0xa5, 0xe5, 0xf1, 0x71, 0xd8, 0x31, 0x15,
    0x04, 0xc7, 0x23, 0xc3, 0x18, 0x96, 0x05, 0x9a, 0x07, 0x12, 0x80, 0xe2, 0xeb, 0x27, 0xb2, 0x75,
    0x09, 0x83, 0x2c, 0x1a, 0x1b, 0x6e, 0x5a, 0xa0, 0x52, 0x3b, 0xd6, 0xb3, 0x29, 0xe3, 0x2f, 0x84,
    0x53, 0xd1, 0x00, 0xed, 0x20, 0xfc, 0xb1, 0x5b, 0x6a, 0xcb, 0xbe, 0x39, 0x4a, 0x4c, 0x58, 0xcf,
    0xd0, 0xef, 0xaa, 0xfb, 0x43, 0x4d, 0x33, 0x85, 0x45, 0xf9, 0x02, 0x7f, 0x50, 0x3c, 0x9f, 0xa8,
    0x51, 0xa3, 0x40, 0x8f, 0x92, 0x9d, 0x38, 0xf5, 0xbc, 0xb6, 0xda, 0x21, 0x10, 0xff, 0xf3, 0xd2,
    0xcd, 0x0c, 0x13, 0xec, 0x5f, 0x97, 0x44, 0x17, 0xc4, 0xa7, 0x7e, 0x3d, 0x64, 0x5d, 0x19, 0x73,
    0x60, 0x81, 0x4f, 0xdc, 0x22, 0x2a, 0x90, 0x88, 0x46, 0xee, 0xb8, 0x14, 0xde, 0x5e, 0x0b, 0xdb,
    0xe0, 0x32, 0x3a, 0x0a, 0x49, 0x06, 0x24, 0x5c, 0xc2, 0xd3, 0xac, 0x62, 0x91, 0x95, 0xe4, 0x79,
    0xe7, 0xc8, 0x37, 0x6d, 0x8d, 0xd5, 0x4e, 0xa9, 0x6c, 0x56, 0xf4, 0xea, 0x65, 0x7a, 0xae, 0x08,
    0xba, 0x78, 0x25, 0x2e, 0x1c, 0xa6, 0xb4, 0xc6, 0xe8, 0xdd, 0x74, 0x1f, 0x4b, 0xbd, 0x8b, 0x8a,
    0x70, 0x3e, 0xb5, 0x66, 0x48, 0x03, 0xf6, 0x0e, 0x61, 0x35, 0x57, 0xb9, 0x86, 0xc1, 0x1d, 0x9e,
    0xe1, 0xf8, 0x98, 0x11, 0x69, 0xd9, 0x8e, 0x94, 0x9b, 0x1e, 0x87, 0xe9, 0xce, 0x55, 0x28, 0xdf,
    0x8c, 0xa1, 0x89, 0x0d, 0xbf, 0xe6, 0x42, 0x68, 0x41, 0x99, 0x2d, 0x0f, 0xb0, 0x54, 0xbb, 0x16
};

// Rcon lookup table
static const uint8_t Rcon[10] = {
    0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x1B, 0x36
};

typedef struct {
    uint8_t state[4][4];
} State;

// Debug print function
void print_state(const char* label, State* state) {
    printf("%s:\n", label);
    for(int i = 0; i < 4; i++) {
        for(int j = 0; j < 4; j++) {
            printf("%02x ", state->state[j][i]);
        }
        printf("\n");
    }
    printf("\n");
}

// SubBytes transformation
void sub_bytes(State* state) {
    for(int i = 0; i < 4; i++)
        for(int j = 0; j < 4; j++)
            state->state[i][j] = sbox[state->state[i][j]];
}

// ShiftRows transformation
void shift_rows(State* state) {
    uint8_t temp;
    
    // Row 1: shift left by 1
    temp = state->state[1][0];
    state->state[1][0] = state->state[1][1];
    state->state[1][1] = state->state[1][2];
    state->state[1][2] = state->state[1][3];
    state->state[1][3] = temp;
    
    // Row 2: shift left by 2
    temp = state->state[2][0];
    state->state[2][0] = state->state[2][2];
    state->state[2][2] = temp;
    temp = state->state[2][1];
    state->state[2][1] = state->state[2][3];
    state->state[2][3] = temp;
    
    // Row 3: shift left by 3 (right by 1)
    temp = state->state[3][3];
    state->state[3][3] = state->state[3][2];
    state->state[3][2] = state->state[3][1];
    state->state[3][1] = state->state[3][0];
    state->state[3][0] = temp;
}

// GF(2^8) multiplication
uint8_t gmul(uint8_t a, uint8_t b) {
    uint8_t p = 0;
    uint8_t hi_bit_set;
    for(int i = 0; i < 8; i++) {
        if((b & 1) == 1)
            p ^= a;
        hi_bit_set = (a & 0x80);
        a <<= 1;
        if(hi_bit_set == 0x80)
            a ^= 0x1b;
        b >>= 1;
    }
    return p;
}

// MixColumns transformation
void mix_columns(State* state) {
    uint8_t temp[4];
    for(int i = 0; i < 4; i++) {
        temp[0] = state->state[0][i];
        temp[1] = state->state[1][i];
        temp[2] = state->state[2][i];
        temp[3] = state->state[3][i];
        
        state->state[0][i] = gmul(0x02, temp[0]) ^ gmul(0x03, temp[1]) ^ temp[2] ^ temp[3];
        state->state[1][i] = temp[0] ^ gmul(0x02, temp[1]) ^ gmul(0x03, temp[2]) ^ temp[3];
        state->state[2][i] = temp[0] ^ temp[1] ^ gmul(0x02, temp[2]) ^ gmul(0x03, temp[3]);
        state->state[3][i] = gmul(0x03, temp[0]) ^ temp[1] ^ temp[2] ^ gmul(0x02, temp[3]);
    }
}

// AddRoundKey transformation
void add_round_key(State* state, uint8_t* round_key) {
    for(int i = 0; i < 4; i++)
        for(int j = 0; j < 4; j++)
            state->state[j][i] ^= round_key[4*i + j];
}

// Key expansion
void key_expansion(uint8_t* key, uint8_t* expanded_key) {
    // Copy the initial key
    memcpy(expanded_key, key, 16);
    
    uint8_t temp[4];
    int i = 1;
    
    // Generate the rest of the round keys
    while(i <= 10) {
        // Copy last 4 bytes
        for(int j = 0; j < 4; j++)
            temp[j] = expanded_key[16*i - 4 + j];
            
        // Rotate
        uint8_t k = temp[0];
        temp[0] = temp[1];
        temp[1] = temp[2];
        temp[2] = temp[3];
        temp[3] = k;
        
        // SubBytes
        for(int j = 0; j < 4; j++)
            temp[j] = sbox[temp[j]];
            
        // XOR with Rcon
        temp[0] ^= Rcon[i-1];
        
        // Generate next round key
        for(int j = 0; j < 16; j++) {
            if(j < 4)
                expanded_key[16*i + j] = expanded_key[16*(i-1) + j] ^ temp[j];
            else
                expanded_key[16*i + j] = expanded_key[16*i + j-4] ^ expanded_key[16*(i-1) + j];
        }
        i++;
    }
}

// New function to validate hex input
int validate_hex(const char* input) {
    if (strlen(input) != 32) return 0;
    for (int i = 0; i < 32; i++) {
        if (!isxdigit(input[i])) return 0;
    }
    return 1;
}

// Main AES encryption function
void aes_encrypt(uint8_t* plaintext, uint8_t* key, uint8_t* ciphertext) {
    State state;
    uint8_t expanded_key[176]; // 11 round keys
    
    // Key expansion
    key_expansion(key, expanded_key);
    
    // Initialize state from plaintext
    for(int i = 0; i < 4; i++)
        for(int j = 0; j < 4; j++)
            state.state[j][i] = plaintext[4*i + j];
    
    // Initial round
    add_round_key(&state, key);
    printf("After Round 0:\n");
    print_state("State", &state);
    
    // Main rounds
    for(int round = 1; round < 10; round++) {
        printf("Round %d:\n", round);
        sub_bytes(&state);
        print_state("After SubBytes", &state);
        
        shift_rows(&state);
        print_state("After ShiftRows", &state);
        
        mix_columns(&state);
        print_state("After MixColumns", &state);
        
        add_round_key(&state, &expanded_key[16*round]);
        print_state("After AddRoundKey", &state);
    }
    
    // Final round
    printf("Final Round:\n");
    sub_bytes(&state);
    shift_rows(&state);
    add_round_key(&state, &expanded_key[160]);
    
    // Copy result to ciphertext
    for(int i = 0; i < 4; i++)
        for(int j = 0; j < 4; j++)
            ciphertext[4*i + j] = state.state[j][i];
}

// Helper function to convert hex string to bytes
void hex_to_bytes(const char* hex, uint8_t* bytes) {
    for(int i = 0; i < 16; i++) {
        sscanf(hex + 2*i, "%2hhx", &bytes[i]);
    }
}

// Helper function to print bytes as hex
void print_hex(const char* label, uint8_t* bytes) {
    printf("%s: ", label);
    for(int i = 0; i < 16; i++)
        printf("%02x", bytes[i]);
    printf("\n");
}

// Modified main function with fixed error handling
int main() {
    char plaintext_hex[33];
    char key_hex[33];
    uint8_t plaintext[16];
    uint8_t key[16];
    uint8_t ciphertext[16];
    char c;

    printf("AES-128 Encryption\n");
    printf("Enter values in hexadecimal\n\n");

    // Plaintext input
    do {
        printf("Guide plaintext: |------------------------------| (32-bit char)\n");
        printf("Enter plaintext: ");
        if (fgets(plaintext_hex, sizeof(plaintext_hex), stdin)) {
            plaintext_hex[strcspn(plaintext_hex, "\n")] = 0;
            
            // Clear input buffer
            while ((c = getchar()) != '\n' && c != EOF);
            
            if (!validate_hex(plaintext_hex)) {
                printf("Error: Please enter exactly 32 hex characters (0-9, a-f)\n\n");
                continue;
            }
        }
    } while (!validate_hex(plaintext_hex));

    // Key input
    do {
        printf("\nGuide key: |------------------------------| (32-bit char)\n");
        printf("Enter key: ");
        if (fgets(key_hex, sizeof(key_hex), stdin)) {
            key_hex[strcspn(key_hex, "\n")] = 0;
            
            // Clear input buffer
            while ((c = getchar()) != '\n' && c != EOF);
            
            if (!validate_hex(key_hex)) {
                printf("Error: Please enter exactly 32 hex characters (0-9, a-f)\n\n");
                continue;
            }
        }
    } while (!validate_hex(key_hex));

    hex_to_bytes(plaintext_hex, plaintext);
    hex_to_bytes(key_hex, key);
    
    printf("\nConfirmation of inputs:\n");
    print_hex("Plaintext", plaintext);
    print_hex("Key", key);
    
    printf("\nProcessing...\n");
    aes_encrypt(plaintext, key, ciphertext);
    
    printf("\nResult:\n");
    print_hex("Ciphertext", ciphertext);
    
    return 0;
}