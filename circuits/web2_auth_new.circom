pragma circom 2.1.6;

include "../circomlib/circuits/poseidon.circom";
include "./rsa_verify.circom";

template JWTValidation(w, n, e_bits, hash_length) {
    // *** PUBLIC INPUTS ***
    signal input msg_hash[hash_length];     
    signal input epk;          
    signal input address;         
    signal input modulus[n];   // RSA modulus `n` (2048 bits → n field elements)
    signal input signature[n]; // RSA signature `s`

    // *** PRIVATE INPUTS ***
    signal input nonce;           // Random nonce (must match Poseidon output)
    signal input blinding_factor; // Used to generate nonce
    signal input sid;             // Subject ID (JWT claim)
    signal input aud;             // Audience (JWT claim)
    signal input spice;           // Extra randomness for address derivation

    // *** 1. RSA Verification (PKCS#1 v1.5 with SHA-256) ***
    // Pass w, n, e_bits, hash_length explicitly to rsaVerifier
    component rsaVerifier = RsaVerifyPkcs1v15(w, n, e_bits, hash_length); // Keep template parameters
    for (var i = 0; i < n; i++) {
        rsaVerifier.exp[i] <== (i == 0 ? 65537 : 0); // Set e=65537 only at index 0
        rsaVerifier.sign[i] <== signature[i];
        rsaVerifier.modulus[i] <== modulus[i];
    }
    // Check the last hash_length words for the raw SHA-256 hash
    for (var i = 0; i < hash_length; i++) {
        rsaVerifier.hashed[i] <== msg_hash[i];
    }

    // *** 2. Nonce Verification ***
    component nonceHasher = Poseidon(2);
    nonceHasher.inputs[0] <== epk;
    nonceHasher.inputs[1] <== blinding_factor;
    nonceHasher.out === nonce;

    // *** 3. Address Generation ***
    component addrHasher = Poseidon(3);
    addrHasher.inputs[0] <== sid;
    addrHasher.inputs[1] <== aud;
    addrHasher.inputs[2] <== spice;
    addrHasher.out === address;
}

// ** Instantiate with correct RSA size (2048-bit modulus) and SHA-256 hash (256 bits) **
component main {public [msg_hash, epk, address, modulus, signature]} = 
    JWTValidation(64, 32, 17, 4); // w=64, n=32, e_bits=17, hash_length=4