package com.tsystems.filter;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.math.BigInteger;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.concurrent.atomic.AtomicLongArray;

public class BloomFilterImpl implements BloomFilter {
    private final int numBits;
    private final int numberOfHashes;
    private final AtomicLongArray bits;

    public BloomFilterImpl(int numBits, int numberOfHashes) {
        if (Integer.bitCount(numBits) != 1) {
            throw new IllegalArgumentException("numBits should be: Integer.bitCount(numBits) == 1");
        }
        if (numberOfHashes == 0) {
            throw new IllegalArgumentException("numberOfHashes cannot be 0");
        }
        this.numBits = numBits;
        this.numberOfHashes = numberOfHashes;
        this.bits = new AtomicLongArray(this.numBits);
    }

    @Override
    public void add(byte[] element) throws NoSuchAlgorithmException, IOException {
        for (int i = 0; i < this.numberOfHashes; i++) {
            BigInteger bi = new BigInteger(this.hash(element, (char) i));
            BigInteger index = bi.mod(BigInteger.valueOf(this.numBits));
            this.bits.set(index.intValue(), 0x1);
        }
    }

    @Override
    public float contains(byte[] element) throws NoSuchAlgorithmException, IOException {
        float counter = 0; // counts how often item was encountered. 0 == very unlikely, x > 0 == likely that might not exist
        for (int i = 0; i < this.numberOfHashes; i++) {
            BigInteger bi = new BigInteger(this.hash(element, (char) i));
            BigInteger index = bi.mod(BigInteger.valueOf(this.numBits));
            // return this.bits.get(index.intValue()) == 0x1;
            counter += this.bits.get(index.intValue());
        }
        return counter / this.numberOfHashes;
    }

    private byte[] hash(byte[] toHash, char seed) throws NoSuchAlgorithmException, IOException {
        MessageDigest md = MessageDigest.getInstance("SHA-256");
        // concat byte[] and seed
        byte charAsByte = (byte) seed;
        ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
        outputStream.write(toHash);
        outputStream.write(charAsByte);
        return md.digest(outputStream.toByteArray());
    }
}
