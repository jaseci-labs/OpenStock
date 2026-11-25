import hashlib;
import time;

with entry {
    t0 = time.perf_counter();
    key = hashlib.pbkdf2_hmac("sha256", b"benchpass123", b"0123456789abcdef", 600000);
    print("pbkdf2_hmac sha256 600000 rounds:", round(time.perf_counter() - t0, 3), "s", key.hex()[:16]);
}
