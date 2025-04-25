include "helpers/arrays.circom";

template test(){
    signal input nonce_value_len;
    signal input nonce_value[100];
    signal nonce_field_elem <== ASCIIDigitsToField(100)(nonce_value, nonce_value_len);
    log("calculated nonce", nonce_field_elem);
}

component main = test();