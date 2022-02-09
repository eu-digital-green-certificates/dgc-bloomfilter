package europa.ec.dgc.bloomfilter;/*
 * Copyright (c) 2022 T-Systems International GmbH and all other contributors
 * Author: Paul Ballmann
 */

import java.util.BitSet;

public class TestCaseFormat extends Object {
    String content;
    int[] filter;

    public TestCaseFormat(int[] filter, String content) {
        this.content = content;
        this.filter = filter;
    }
}
