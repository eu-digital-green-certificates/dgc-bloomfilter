/*
 * Copyright (c) 2022 T-Systems International GmbH and all other contributors
 * Author: Paul Ballmann
 */

import model.FilterTestData;
import org.json.simple.JSONArray;
import org.json.simple.JSONObject;
import org.json.simple.parser.JSONParser;
import org.json.simple.parser.ParseException;
import org.junit.Test;

import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.NoSuchAlgorithmException;
import java.util.*;
import java.util.concurrent.atomic.AtomicLongArray;

public class BloomFilterUnitTest {
    // func: read json file
    // func: write to json file
    // func: run bloom filter
    // func: run guava bloom filter

    private static String JSON_TEST_FILE = "src/test/resources/testcase1.json";
    private JSONArray testObjects = null;
    private BloomFilterImpl bloomFilter;
    private FilterTestData filterTestData = null;
    // private List<BloomFilterImpl> filterList = new ArrayList<>();


    @Test
    public void runTests() throws Exception {
        this.testObjects = this.readFromJson();
        assert this.testObjects != null;
        this.runBloomFilterTest();
    }

    @Test
    public void runBloomFilterTest() throws Exception {
        assert this.testObjects != null;
        for (int i = 0; i < this.testObjects.size(); i++) {
            System.out.printf("Current test at index : %s%n", i);
            // create a bloom filter
            FilterTestData testData = this.extractTestData(i);
            this.bloomFilter = this.createFilterForData(testData);
            this.filterTestData = testData;
            // store data in the filter
            this.storeDataInFilter(i);

            this.calcBaseStringFromFilter(i);
            // perform lookup to check if data exists
            this.filterLookupTest(testData, i);
        }
    }

    private BloomFilterImpl createFilterForData(FilterTestData data) {
        return new BloomFilterImpl(data.getDataSize(), data.getK(), (float) data.getP());
    }

    public void storeDataInFilter(int i) {
        assert this.bloomFilter != null;
        FilterTestData testData = this.extractTestData(i);
        this.addToTsiBloomFilter(testData);
    }

    public void calcBaseStringFromFilter(int i) {
        // get base64 from filter
        String filterAsBase64 = this.getFilterAsBase64(this.bloomFilter.getBits());
        this.writeToJson((JSONObject) this.testObjects.get(i), i);
        // store base64 in data
        this.storeBase64InFile(i, filterAsBase64);
    }

    public void filterLookupTest(FilterTestData testData, int index) throws Exception {
        this.lookupFilter(testData, index);
    }
/*
    @Test
    public void runTSIBloomFilter() throws Exception {
        // Contains all of the data from the test file
        JSONArray jsonArray = this.readFromJson();
        // Iterate over all of the test-cases
        assert jsonArray != null;
        this.testObjects = jsonArray;
        for (int i = 0; i < this.testObjects.size(); i++) {
            System.out.printf("i: %s%n", i);
            JSONObject object = (JSONObject) jsonArray.get(i);
            FilterTestData testData = this.extractTestData(object);
            this.bloomFilter = new BloomFilterImpl(testData.getDataSize(), testData.getK(), (float) testData.getP());
            this.addToTsiBloomFilter(testData);
            this.storeFilterAsBase64(this.bloomFilter.getBits(), object, i);
            this.printTsiFilterBits();
            this.lookupFilter(testData, object, i);
            return;
        }

    }*/

    /**
     * Checks if all bits written in the testData.written array can be found in the filter.
     * Each element that actually exists will be set int he testData.exists array
     */
    private void lookupFilter(FilterTestData testData, int index) throws Exception {
        int exists[] = new int[testData.getDataSize()];
        for (int i = 0; i < testData.getDataSize(); i++) {
            // iterate over all testdata
            // perform a lookup
            // if lookup is true, set bit to 1 in exists array
            // loop over exists array
            // check if each bit is equal to the bits in written
            if (this.bloomFilter.contains(dataToArr(testData.getData().get(i)))) {
                exists[i] = 1;
            } else {
                exists[i] = 0;
            }
        }
        // store exists in json
        JSONObject o = (JSONObject) this.testObjects.get(index);
        o.put("exists", Arrays.toString(exists));
        writeToJson(o, index);
        // retrieve written array
        int strike = 0; // strike for each mismatch
        for (int j = 0; j < exists.length; j++) {
            if (exists[j] != testData.getWritten()[j]) {
                strike++;
            }
        }
        System.out.printf("LookupTest: Strikes -> %s%n", strike);
    }

    private byte[] dataToArr(Object obj) {
        return obj.toString().getBytes(StandardCharsets.UTF_8);
    }

    private String getFilterAsBase64(AtomicLongArray filter) {
        String base64Filter = getBase64FromFilter(filter);
        System.out.println("TSI: " + base64Filter);
        return base64Filter;
        // objPointer.put("filter", base64Filter);
        // writeToJson(objPointer, index);
    }

    private void storeBase64InFile(int index, String base64) {
        JSONObject obj = (JSONObject) this.testObjects.get(index);
        obj.put("filter", base64);
        writeToJson(obj, index);
    }

    private FilterTestData extractTestData(int index) {
        FilterTestData data = new FilterTestData();
        JSONObject dataObject = (JSONObject) this.testObjects.get(index);
        data.setData((JSONArray) dataObject.get("data"));
        data.setP((double) dataObject.get("p"));
        data.setK(Integer.parseInt(dataObject.get("k").toString()));
        data.setExists(new int[data.getDataSize()]);
        int[] written = this.toArray((JSONArray) dataObject.get("written"));
        data.setWritten(written);
        // data.setWritten((int[]) obj.get("written"));
        System.out.printf("data: %s%n", data.getData());
        System.out.printf("p: %s, k: %s%n", data.getP(), data.getK());
        return data;
    }

    private int[] toArray(JSONArray arr) {
        int[] intArr = new int[arr.size()];
        for (int i = 0; i < arr.size(); i++) {
            intArr[i] = Integer.parseInt(arr.get(i).toString());
        }
        return intArr;
    }

    private void printTsiFilterBits() {
        System.out.println(this.bloomFilter.getBits().toString());
    }

    private void addToTsiBloomFilter(FilterTestData data) {
        try {
            for (int i = 0; i < data.getDataSize(); i++) {
                // only add elements where written is set to 1 at given index i
                if (data.getWritten()[i] == 1) {
                    this.bloomFilter.add(data.getData().get(i).toString().getBytes(StandardCharsets.UTF_8));
                }
            }
        } catch (NoSuchAlgorithmException | IOException e) {
            e.printStackTrace();
        }
    }

    private String getBase64FromFilter(AtomicLongArray bitArray) {
        return Base64.getEncoder().encodeToString(bitArray.toString().getBytes(StandardCharsets.UTF_8));
    }

    private void writeToJson(JSONObject object, int index) {
        JSONArray jsonArraySource = this.readFromJson();
        FileWriter fileWriter;
        try {
            fileWriter = new FileWriter(JSON_TEST_FILE);
        } catch (IOException io) {
            System.out.println("ERROR " + io.getLocalizedMessage());
            return;
        }
        jsonArraySource.set(index, object);
        try {
            fileWriter.write(jsonArraySource.toJSONString());
            fileWriter.flush();
            fileWriter.close();
        } catch (IOException ioException) {
            System.out.println("ERROR: " + ioException.getLocalizedMessage());
            return;
        }

    }

    private JSONArray readFromJson() {
        FileReader fileReader;
        try {
            fileReader = new FileReader(JSON_TEST_FILE);
        } catch (FileNotFoundException fnf) {
            System.out.println("ERROR: " + fnf.getLocalizedMessage());
            return null;
        }
        JSONArray jsonArray;
        try {
            JSONParser parser = new JSONParser();
            jsonArray = (JSONArray) parser.parse(fileReader);
        } catch (ParseException | IOException pe) {
            System.out.println("ERROR: " + pe.getLocalizedMessage());
            return null;
        }
        return jsonArray;
    }

    private JSONObject getFromJson(JSONArray array, int index) {
        return (JSONObject) array.get(index);
    }

    private Object getFromObject(String key, JSONObject object) {
        return object.get(key);
    }


}
