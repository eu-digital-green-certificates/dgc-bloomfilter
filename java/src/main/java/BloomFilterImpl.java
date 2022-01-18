/*
 * Copyright (c) 2022 T-Systems International GmbH and all other contributors
 * Author: Paul Ballmann
 */

import java.io.*;
import java.math.BigInteger;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HashMap;
import java.util.concurrent.atomic.AtomicLongArray;

public class BloomFilterImpl implements BloomFilter, Serializable {
    private final int numBytes;
    private final int numberOfHashes;
    private final AtomicLongArray bits;
    private final static int NUM_BITS = 8;
    @Serial
    private static final long serialVersionUID = 7526472295622776147L;

    public BloomFilterImpl(int size, int numberOfHashes) {
        super();
        if (numberOfHashes == 0) {
            throw new IllegalArgumentException("numberOfHashes cannot be 0");
        }
        this.numBytes = (size * NUM_BITS);
        this.numberOfHashes = numberOfHashes;
        this.bits = new AtomicLongArray(this.numBytes);
    }

    public BloomFilterImpl(int numberOfElements, int numberOfHashes, float probRate) {
        super();
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

    /**
     * Indicates whether some other object is "equal to" this one.
     *
     * @param obj the reference object with which to compare.
     * @return {@code true} if this object is the same as the obj
     * argument; {@code false} otherwise.
     * @see #hashCode()
     * @see HashMap
     */
    @Override
    public boolean equals(Object obj) {
        return super.equals(obj);
    }

    /**
     * Creates and returns a copy of this object.  The precise meaning
     * of "copy" may depend on the class of the object.
     *
     * @return a clone of this instance.
     * @throws CloneNotSupportedException if the object's class does not
     *                                    support the {@code Cloneable} interface. Subclasses
     *                                    that override the {@code clone} method can also
     *                                    throw this exception to indicate that an instance cannot
     *                                    be cloned.
     * @see Cloneable
     */
    @Override
    protected Object clone() throws CloneNotSupportedException {
        return super.clone();
    }

    private void readObject(
            ObjectInputStream inputStream
    ) throws ClassNotFoundException, IOException {
        inputStream.defaultReadObject();
    }

    private void writeObject(
            ObjectOutputStream outputStream
    ) throws IOException {
        outputStream.defaultWriteObject();
    }


}
