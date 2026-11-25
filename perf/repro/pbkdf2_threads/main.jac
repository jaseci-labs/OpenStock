import hashlib;
import threading;
import time;

def work {
    hashlib.pbkdf2_hmac("sha256", b"benchpass123", b"0123456789abcdef", 600000);
}

with entry {
    t0 = time.perf_counter();
    work();
    one = time.perf_counter() - t0;
    threads = [threading.Thread(target=work) for _ in range(4)];
    t0 = time.perf_counter();
    for t in threads { t.start(); }
    for t in threads { t.join(); }
    print("one hash:", round(one, 3), "s; four hashes on four threads:", round(time.perf_counter() - t0, 3), "s");
}
