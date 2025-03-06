#!/bin/bash

set -e  # Exit on error
CIRCUIT_NAME="main"
PTAU_SIZE=21  # Adjust this based on circuit size
OUTPUT_DIR="./output"  # Directory to save the output files

# Create output directory if it doesn't exist
mkdir -p $OUTPUT_DIR

# Check if the secret key argument is provided
if [ -z "$1" ]; then
    echo "❌ No secret key provided. Please provide the secret key as the first argument."
    exit 1
fi

SECRET_INPUT=$1  # Get the secret key from the argument

echo "🚀 Starting Trusted Setup for Groth16..."

# Ensure snarkjs is installed
if ! command -v snarkjs &> /dev/null; then
    echo "❌ snarkjs not found! Install with: npm install -g snarkjs"
    exit 1
fi

# 1. Compile the circuit and specify the output directory
echo "🔨 Compiling the circuit..."
circom ./circuits/templates/${CIRCUIT_NAME}.circom --r1cs --wasm --sym --output $OUTPUT_DIR

# 2. Start Powers of Tau ceremony
echo "🔑 Generating Powers of Tau (ptau)..."
snarkjs powersoftau new bn128 $PTAU_SIZE ${OUTPUT_DIR}/pot${PTAU_SIZE}_0000.ptau -v

# 3. Contribute randomness (User Secret Input)
echo "⚠️  Using provided secret key for contribution..."
echo $SECRET_INPUT | snarkjs powersoftau contribute ${OUTPUT_DIR}/pot${PTAU_SIZE}_0000.ptau ${OUTPUT_DIR}/pot${PTAU_SIZE}_0001.ptau --name="User Contribution" -v

# 4. Prepare phase 2
echo "🛠 Preparing Phase 2..."
snarkjs powersoftau prepare phase2 ${OUTPUT_DIR}/pot${PTAU_SIZE}_0001.ptau ${OUTPUT_DIR}/pot${PTAU_SIZE}_final.ptau -v

# 5. Generate zkey
echo "📜 Running Groth16 setup..."
snarkjs groth16 setup ${OUTPUT_DIR}/${CIRCUIT_NAME}.r1cs ${OUTPUT_DIR}/pot${PTAU_SIZE}_final.ptau ${OUTPUT_DIR}/${CIRCUIT_NAME}_0000.zkey -v

# 6. Contribute randomness for zkey
if [ -z "$2" ]; then
    echo "⚠️  No second secret key provided for zkey contribution. Please provide it as the second argument."
    exit 1
fi

SECRET_INPUT_2=$2  # Get the second secret key from the argument
echo "⚠️  Using second provided secret key for zkey contribution..."
echo $SECRET_INPUT_2 | snarkjs zkey contribute ${OUTPUT_DIR}/${CIRCUIT_NAME}_0000.zkey ${OUTPUT_DIR}/${CIRCUIT_NAME}_0001.zkey --name="User Contribution 2" -v

# 7. Export verification key
echo "📤 Exporting verification key..."
snarkjs zkey export verificationkey ${OUTPUT_DIR}/${CIRCUIT_NAME}_0001.zkey ${OUTPUT_DIR}/verification_key.json

echo "✅ Trusted setup complete! Verification key stored as ${OUTPUT_DIR}/verification_key.json"


# node generate_witness.js web2_auth_new.wasm input.json witness.wtns

#snarkjs groth16 prove circuit_final.zkey witness.wtns proof.json public.json
#snarkjs groth16 verify verification_key.json public.json proof.json