import java.io.IOException;
import java.security.NoSuchAlgorithmException;

public interface BloomFilter {
    void add(byte[] element) throws NoSuchAlgorithmException, IOException;
    boolean contains(byte[] element) throws NoSuchAlgorithmException, IOException;
}
