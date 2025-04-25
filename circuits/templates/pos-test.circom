pragma circom 2.1.6;

include "../../circomlib/circuits/poseidon.circom";
template Example () {
    signal input temp_pubkey[3]; // Represented as 3 elements of up to 31 bytes each to allow for pubkeys of up to 64 bytes each
    signal input temp_pubkey_len; // This is public and checked by the verifier. Included in nonce hash to prevent collisions
    signal input exp_date;
    signal input jwt_randomness;


    
    signal computed_nonce <== Poseidon(6)([temp_pubkey[0], temp_pubkey[1], temp_pubkey[2], temp_pubkey_len, exp_date, jwt_randomness]);


    log("hash", computed_nonce);
}

component main = Example();
