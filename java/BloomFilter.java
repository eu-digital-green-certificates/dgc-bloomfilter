package com.tsystems.filter;

import java.io.IOException;
import java.security.NoSuchAlgorithmException;

public interface BloomFilter {
    void add(byte[] element) throws NoSuchAlgorithmException, IOException;
    float contains(byte[] element) throws NoSuchAlgorithmException, IOException;
}
