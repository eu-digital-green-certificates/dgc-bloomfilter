package europa.ec.dgc.bloomfilter;/*
 * Copyright (c) 2022 T-Systems International GmbH and all other contributors
 * Author: Paul Ballmann
 */

import europa.ec.dgc.bloomfilter.exception.FilterException;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.security.NoSuchAlgorithmException;

public interface BloomFilter {
    float    getP();
    int     getK();
    long    getM();
    int     getN();
    int     getCurrentN();
    void    add(byte[] element)                 throws NoSuchAlgorithmException, FilterException, IOException;
    boolean mightContain(byte[] element)        throws NoSuchAlgorithmException, FilterException, IOException;
    void    readFrom(InputStream inputStream);
    void    writeTo(OutputStream outputStream)  throws FilterException, IOException;
    
}
