package eu.europa.ec.dgc.bloomfilter;/*
 * Copyright (c) 2022 T-Systems International GmbH and all other contributors
 * Author: Paul Ballmann/Steffen Schulze
 */
import java.io.*;
import java.math.BigInteger;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HashMap;
import java.util.Objects;
import java.util.concurrent.atomic.AtomicIntegerArray;
import java.util.logging.Logger;

import eu.europa.ec.dgc.bloomfilter.exception.FilterException;

public class BloomFilterImpl implements BloomFilter, Serializable {
    private long numBits;
    private byte numberOfHashes;
    private int currentElementAmount = 0;
    private int definedElementAmount = 0;
    private byte usedHashFunction = 0;
    private float probRate;
    private AtomicIntegerArray data;
    private final static int NUM_BITS = 8;
    private final static byte NUM_BYTES=Integer.BYTES;
    private final static byte NUM_BIT_FORMAT = (NUM_BYTES*NUM_BITS);


    private static final long serialVersionUID = 7526472295622776147L;
    private static final short version = 1;

    public BloomFilterImpl(InputStream inputStream) {
        super();
        DataInputStream dis = new DataInputStream(inputStream);
        this.readFromStream(dis);
    }

    public BloomFilterImpl(int size, byte numberOfHashes,int numberOfElements) {
        super();

        if (numberOfHashes <= 0 || size<=0) {
            throw new IllegalArgumentException("numberOfElements <=0, numberOfHashes <= 0, probRate <= 1");
        }

        if (numberOfHashes == 0) {
            throw new IllegalArgumentException("numberOfHashes cannot be 0");
        }

        size = (size / NUM_BYTES)+(size % NUM_BYTES);  

        long heapFreeSize = Runtime.getRuntime().freeMemory();

        if(heapFreeSize<(long)size*NUM_BYTES) {
            throw new IllegalArgumentException("Heap size not big enough");
        }
        this.definedElementAmount = numberOfElements;
        this.numBits = (long)size*NUM_BIT_FORMAT;
        this.numberOfHashes = numberOfHashes;
        this.probRate = (float) Math.pow(1 - Math.exp(-numberOfHashes / (float)( (float)(this.numBits / NUM_BITS) / numberOfElements)), numberOfHashes);
        this.data = new AtomicIntegerArray(size);
    }

    public BloomFilterImpl(int numberOfElements, float probRate) {
        super();
        if (numberOfElements <= 0  || probRate > 1 || probRate <= 0) {
            throw new IllegalArgumentException("numberOfElements <=0, probRate <= 1");
        }
        // n: numberOfElements
        // m: numberOfBits -> ceil((n * log(p)) / log(1 / pow(2, log(2))));
        this.numBits = (long) (Math.ceil((numberOfElements * Math.log((double)probRate)) / Math.log(1 / Math.pow(2, Math.log(2)))));
         
        int bytes = (int)(this.numBits / NUM_BITS)+1;
        int size  = (bytes / NUM_BYTES)+(bytes % NUM_BYTES);  
        this.numBits = size * NUM_BIT_FORMAT;
        long heapFreeSize = Runtime.getRuntime().freeMemory();

        if (size<=0) {
            throw new IllegalArgumentException("Size can not be 0");
        }

        if (heapFreeSize < (long)size*NUM_BYTES) {
            throw new IllegalArgumentException("Heap size not big enough");
        }
        
        this.definedElementAmount = numberOfElements;
        this.numberOfHashes = (byte)Math.max(1, (int) Math.round((double) this.numBits / numberOfElements * Math.log(2)));
        
        if(numberOfHashes<0) {
            throw new IllegalArgumentException("Number of Hashes to high. Please check the Probalistic Rate (limit arround 1.0E-38)");
        }
        
        this.probRate = probRate;
        this.data = new AtomicIntegerArray(size);
    }

    public AtomicIntegerArray getData() {
        return data;
    }

    @Override
    public void add(byte[] element) throws NoSuchAlgorithmException, FilterException, IOException {
        for (int i = 0; i < this.numberOfHashes; i++) {
            long index = calcIndex(element, i,this.numBits).longValue();
            int bytepos = (int)index/NUM_BIT_FORMAT;
            index -= bytepos * NUM_BIT_FORMAT;
            Integer pattern = Integer.MIN_VALUE>>>index;
            this.data.set(bytepos,this.data.get(bytepos) | pattern);
        }
        currentElementAmount++;
        
        if(currentElementAmount >= definedElementAmount) {
          Logger.getGlobal().warning("Filter is filled. All other Elements may result in a higher False Positve Rate than defined!");
        }
    }

    @Override
    public boolean mightContain(byte[] element) throws NoSuchAlgorithmException, FilterException, IOException {
        boolean result = true;
        for (int i = 0; i < this.numberOfHashes; i++) {
            long index = calcIndex(element, i,this.numBits).longValue();
            int bytepos = (int)index/NUM_BIT_FORMAT;
            index -= bytepos * NUM_BIT_FORMAT;
            long pattern = Integer.MIN_VALUE>>>index;
            if ((this.data.get(bytepos) & pattern) == pattern) {
                 result&=true;
            }
            else {
                result &=false;
                break;
            }
        }
        return result;
    }

    public static BigInteger calcIndex(byte[] element, int i, long bits) throws NoSuchAlgorithmException, IOException {
        var hash = hash(element, (char) i);
        BigInteger bi = new BigInteger(hash);
        return bi.mod(BigInteger.valueOf(bits));
    }

    public static byte[] hash(byte[] toHash, char seed) throws NoSuchAlgorithmException, IOException {
        MessageDigest md = MessageDigest.getInstance("SHA-256");
        // concat byte[] and seed
        byte charAsByte = (byte) seed;
        ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
        outputStream.write(toHash);
        outputStream.write(charAsByte);
        return md.digest(outputStream.toByteArray());
    }


    //region Streams

    /**
     * Writes the filter to an output stream in a structured manner
     * 0 byte -> k (numberOfHashes)
     * 1 - 4 byte -> p (probRate)
     * 5 byte -> unsigned length of the data
     * 6 - x byte -> data as utf8
     *
     * @param outputStream
     * @throws IOException
     */
    public void writeTo(OutputStream outputStream) throws FilterException, IOException {
        // k = 1 (numberOfHashes), p = 4 (probRate),
        // 0 = k, 1 = p, 5 = filter
        DataOutputStream dataOutputStream = new DataOutputStream(outputStream);
        dataOutputStream.writeShort(version);
        dataOutputStream.writeByte(this.numberOfHashes);
        dataOutputStream.writeByte(usedHashFunction);
        dataOutputStream.writeFloat(this.probRate);
        dataOutputStream.writeInt(this.definedElementAmount);
        dataOutputStream.writeInt(this.currentElementAmount);
        dataOutputStream.writeInt(this.getData().length());        
        for (int i = 0; i < this.getData().length(); i++) {
            dataOutputStream.writeInt(this.getData().get(i));
        }

    }

    private void readFromStream(DataInputStream dis) {
        try {
            int version = dis.readShort(); // for later compatibility
            this.numberOfHashes = dis.readByte();
            this.usedHashFunction = dis.readByte();
            this.probRate = dis.readFloat();
            this.definedElementAmount = dis.readInt();
            this.currentElementAmount = dis.readInt();
            int dataLength = dis.readInt();
            int[] data = new int[dataLength];
            for (int i = 0; i < dataLength; i++) {
                data[i] = dis.readInt();
            }
            this.data = new AtomicIntegerArray(data);
            this.numBits = data.length * NUM_BIT_FORMAT;
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    /**
     * Will try to read data from the input stream to constrcut a new bloomFilter from
     * * 0 byte -> k (numberOfHashes)
     * * 1 - 4 byte -> p (probRate)
     * * 5 - x byte -> data as utf8
     *
     * @param inputStream
     * @throws IOException
     */
    public void readFrom(InputStream inputStream) {
        DataInputStream dataInputStream = new DataInputStream(inputStream);
        this.readFromStream(dataInputStream);
    }
    //endregion

    //region Utility

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
     *                                    throw this europa.ec.dgc.bloomfilter.exception to indicate that an instance cannot
     *                                    be cloned.
     * @see Cloneable
     */
    @Override
    protected Object clone() throws CloneNotSupportedException {
        return super.clone();
    }

    public int hashCode() {
        return Objects.hashCode(new Object[]{this.numBits, this.numberOfHashes, this.getData()});
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
    //endregion

    @Override
    public float getP() {
        return this.probRate;
    }

    @Override
    public int getK() {
        return this.numberOfHashes;
    }

    @Override
    public long getM() {
        return this.numBits;
    }

    @Override
    public int getN() {
        return this.definedElementAmount;
    }

}
