/*
 * Copyright (c) 2022 T-Systems International GmbH and all other contributors
 * Author: Paul Ballmann
 */

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.math.BigInteger;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.concurrent.atomic.AtomicLongArray;

public class BloomFilterImpl implements BloomFilter {
    private final int numBytes;
    private final int numberOfHashes;
    private final AtomicLongArray bits;
    private final static int NUM_BITS = 8;

    public BloomFilterImpl(int size, int numberOfHashes) {

        if (numberOfHashes == 0) {
            throw new IllegalArgumentException("numberOfHashes cannot be 0");
        }
        this.numBytes = (size * NUM_BITS);
        this.numberOfHashes = numberOfHashes;
        this.bits = new AtomicLongArray(this.numBytes);
    }

    public BloomFilterImpl(int numberOfElements, int numberOfHashes, float probRate) {
        if (numberOfElements == 0 || numberOfHashes == 0 || probRate > 1 || probRate == 0) {
            throw new IllegalArgumentException("numberOfElements != 0, numberOfHashes != 0, probRate <= 1");
        }
        // n: numberOfElements
        // m: numberOfBits -> ceil((n * log(p)) / log(1 / pow(2, log(2))));
        this.numBytes = (int) (Math.ceil((numberOfElements * Math.log(probRate)) / Math.log(1 / Math.pow(2, Math.log(2)))));
        this.numberOfHashes = numberOfHashes;
        this.bits = new AtomicLongArray(this.numBytes);
    }

    public AtomicLongArray getBits() {
        return bits;
    }

    @Override
    public void add(byte[] element) throws NoSuchAlgorithmException, IOException {
        for (int i = 0; i < this.numberOfHashes; i++) {
            BigInteger index = this.calcInternal(element, i);
            System.out.println("INDEX: " + index);
            this.bits.set(index.intValue(), 0x1);
        }
    }

    @Override
    public boolean contains(byte[] element) throws NoSuchAlgorithmException, IOException {
        for (int i = 0; i < this.numberOfHashes; i++) {
            BigInteger index = this.calcInternal(element, i);
            if (this.bits.get(index.intValue()) == 0x1) {
                return true;
            }
        }
        return false;
    }

    private BigInteger calcInternal(byte[] element, int i) throws NoSuchAlgorithmException, IOException {
        BigInteger bi = new BigInteger(this.hash(element, (char) i));
        return bi.mod(BigInteger.valueOf(this.numBytes));
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
