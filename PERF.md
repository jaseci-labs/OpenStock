# Performance: the Next.js original against the Jac rewrite

The original is commit 62da391ed (Next.js 15.5, `next start`, MongoDB 7, better-auth). The Jac is
this branch, built with neojac 0.5.1 (`neojac build`, one native program, `dist/web-linux-x86_64/web`).
Both ran on the same machine on 2026-11-25.

**Load.** The machine is shared: 20 cores with a load average of 25–50 for the whole session (it is
printed at the start and end of each run in `perf/`). Absolute numbers are therefore noisy, and the
original's signed-in numbers changed most between runs (4–5 ms in a first run, 21–34 ms in the
final one). Every comparison below alternates original and Jac runs within each round and reports
medians, so both sides saw the same load.

## Where the code runs

`archwire.jac` has two spaces: `api: native { api.*; }` and `site: browser { pages.* | ui.*; }`.
Every server-side module (quotes, markets, portfolio, account, jobs, seo, mail, ai, kit, insights)
is in the native space, so it is compiled to machine code. The program links only libc, libm,
libpthread and libdl: no CPython and no Node. No space is `cpython` or `node`, so no code was left to
move into a native space, and a server request crosses no space boundary. The only crossing is
browser → native, which is the HTTP call each page makes.

## Results

Medians. "before" is this branch before the change in this work (commit 23e1ac6); "after" is
commit e64d950. Latency is the per-request median at 1 client, over 300 requests in each of 5
alternated rounds; throughput is at 16 clients with keep-alive. "Same" means the two sides' outputs
were compared and matched (see *Same output*).

### Server endpoints (`perf/bench.py`)

| Workload | Original p50 | Jac before | Jac after | Original req/s (16 clients) | Jac before | Jac after | Same |
|---|---:|---:|---:|---:|---:|---:|---|
| `GET /robots.txt` | 2.23 ms | 0.92 ms | 0.99 ms | 469 | 1292 | 1458 | yes¹ |
| `GET /sitemap.xml` | 2.59 ms | 4.29 ms | **2.10 ms** | 402 | 222 | **518** | yes² |
| stock page `/s/AAPL`³ | 3.75 ms | 2.27 ms | 2.29 ms | 288 | 519 | 529 | yes |
| directory `/s`³ | 7.91 ms | 7.90 ms | 7.78 ms | 169 | 167 | 158 | yes |
| get watchlist | 21.31 ms | 0.66 ms | 0.76 ms | 38 | 1526 | 1366 | yes |
| in watchlist | 33.78 ms | 1.10 ms | 1.07 ms | 35 | 1291 | 1197 | yes |
| get lists | 21.74 ms | 0.87 ms | 0.87 ms | 54 | 1891 | 2027 | yes |
| get alerts | 22.49 ms | 0.75 ms | 0.79 ms | 55 | 2320 | 2524 | yes |
| sign in (email + password) | **101 ms** | 1936 ms | 1445 ms | **40** | 1 | <1 | yes |

¹ The Jac's robots.txt also disallows `/__jac/`, the path of its endpoints. That line is the only
difference, and the rewrite added it on purpose.
² The same `(loc, changefreq, priority)` for all 534 URLs; Next puts each tag on its own line.
³ Next prerenders these pages as HTML. The Jac sends a 1.5 KB app shell, and the page then calls the
API: `ticker_page` for `/s/AAPL`, and `tickers_by_sector` plus `directory_ld` for `/s`. The Jac
figure is the sum of those requests. Output is compared by checking that the title and intro the
API returns appear in Next's HTML.

### Start-up, commands, tests, builds

| Workload | Original | Jac | |
|---|---:|---:|---|
| Server start → first `/robots.txt` reply, kept data (7 alternated runs) | 1.861 s | **0.012 s** | `perf/startup.py` |
| Same, first start on an empty data directory | 1.853 s | 0.224 s | SQLite store creation: see blocker 5 |
| `check-env` command (21 alternated runs)⁴ | 44.1 ms | **1.4 ms** | `perf/cmdbench.py` |
| Test suite, nothing changed (5 alternated runs) | 2.75 s (vitest, 274 tests) | **0.54 s** (158 tests) | |
| Test suite after editing `api/seo.jac` (3 runs) | 2.88 s | 18–20 s | blocker 4 |
| Test suite, test runners deleted, shared build cache warm | — | 11.3 s | |
| Test suite, first run ever (shared build cache cold) | 2.6 s | 55 s | |
| Production build, first | 36.9 s (`next build`) | 40.8 s | |
| Production build, sources unchanged | — | 10.0 s | |
| Page weight `/s/AAPL` (HTML + JS + CSS on the wire) | 233 KB in 18 requests (gzip) | 700 KB in 3 requests (no compression) | blocker 3; `perf/pagebytes.py` |

⁴ The Jac `tools/check_env.jac` checks the variables the rewrite reads and prints a shorter report,
so its output differs from `scripts/check-env.mjs` by design. Both exit 0 with every required
variable present. The figure compares process start-up and a small amount of work.

The two test suites differ: vitest runs the original's 274 tests, and `neojac test` runs the
rewrite's 158 tests, which cover the same modules. Each suite passes in full on its own code.

## What made the difference

* **The Jac is already faster almost everywhere.** It is a single native program with no JIT warm-up
  and no framework layers. Its graph store is SQLite in the same process, where the original makes
  a MongoDB round trip and a session lookup. As a result, signed-in reads take 0.7–1.1 ms against
  21–34 ms, start-up takes 12 ms against 1.86 s, and the CLI takes 1.4 ms against 44 ms.
* **`sitemap.xml` was slower: 4.29 ms against 2.59 ms, and 222 against 402 req/s.** Next renders
  it once and serves the cached file (`revalidate = 86400`). The Jac rebuilt the 534 URLs, about
  0.87 ms of string formatting, on every request. It is now built once per origin (`api/seo.jac`,
  the `sitemaps` glob). The text depends only on the static ticker and guide lists and on
  `BETTER_AUTH_URL`, so a change to `BETTER_AUTH_URL` still produces the new text. The result is
  2.10 ms and 518 req/s, ahead of Next. `tickers_by_sector` is also built once, at load, rather than
  on every call. That saves the 73 µs grouping, but this endpoint's cost is almost all JSON encoding
  (blocker 2).
* **The directory page `/s` is level with Next, not ahead.** About 80% of its time is the server
  encoding 518 `Ticker` objects (93 KB) to JSON (blocker 2). The page reads only `name` and `symbol`.
  A narrower return type would make the page about 4× cheaper, but it changes what the public
  `tickers_by_sector` endpoint returns, so it was not done.
* **Sign-in is the one large loss: 14–19× slower and serialized.** The cause is the runtime's
  password hashing (blocker 1), not the app's code. The app could lower `[auth.accounts] rounds`,
  but that weakens every stored password, so it is left at the default.
* Not changed: `--release` (refused for apps, blocker 6). The `rc` memory profile was also not
  adopted: it leaks reference cycles, which the graph's nodes and edges have, in a long-running
  server.

## Blockers in neojac 0.5.1

Each reproduction is in `perf/repro/`, outside the project's sources (`[project] exclude` in `jac.toml`).

1. **PBKDF2 is 3.8× slower than OpenSSL and takes a global lock.** `hashlib.pbkdf2_hmac("sha256",
   b"benchpass123", b"0123456789abcdef", 600000)` in a native program takes 0.96–1.0 s. CPython 3.10
   with OpenSSL takes 0.256 s, and both give the same key, `092fe741863a148f…`
   (`perf/repro/pbkdf2/main.jac`, `neojac run main.jac`). Four of these hashes on four threads take
   2.5–5.1× as long as one (3.8× median of 3 runs), where four in CPython take the same time as one
   (`perf/repro/pbkdf2_threads`).
   The auth plugin hashes each sign-in with 600 000 rounds (`[auth.accounts] rounds`), so the server
   signs in about one person a second however many cores it has: 1.4–1.9 s per sign-in, against
   101 ms for better-auth's scrypt.
2. **The endpoint codec is about 4–5× slower than V8.** In `perf/repro/encode` (a native app: `neojac
   build`, then call `/__jac/call/api/svc/<name>`), a `def:pub` returning 518 seven-field objects
   (116 KB) takes 6.2 ms per request. A plain Node `http` server sending the same data with
   `JSON.stringify` takes 1.4 ms. A 112 KB string with nothing to escape takes 2.15 ms against
   0.70 ms in Node for 56 KB, so most of the cost is per object. Native `json.dumps` of the same
   dicts takes 1.34 ms, against 0.60 ms in CPython and 0.29 ms in Node. A related limit: the codec
   refuses a union field. `def:pub f -> list[dict[str, str | list[str]]]` fails with `error[E1229]:
   serve_def() cannot be specialized` / `comptime assertion failed: the codec takes a union of one
   type and None` (stdjac/codec.jac:109).
3. **The server does not compress.** `neojac docs apps/server` says: "For TLS, compression and many
   connections at once, put the server behind a reverse proxy". The pages' JavaScript, 638 KB in the
   entry chunk, goes out uncompressed, so `/s/AAPL` is 700 KB on the wire against 233 KB from Next.
   The app has no setting to enable compression.
4. **Changing one module costs 12–20 s before the tests run.** Each test module is a separate native
   runner of 16–22 MB, and editing `api/seo.jac` relinks every runner that imports it. Running the
   runners takes 0.1 s. vitest takes about 2.7 s every time. The very first run, with the shared
   build cache cold, took 55 s.
5. **The first start on an empty data directory takes about 0.22 s,** almost all of it about 20
   `fsync` calls while the store creates `accounts.db` and `graph.db` (seen with `strace -f -r`).
   With kept data, start-up takes 12 ms.
6. **`--release` cannot be used for an app.** `neojac build --release` in a project prints
   `neojac build: --release is an option of a program's build, and these are a project's apps`. The
   cross-module inlining it gives is not available to a server.

## Reproducing

`perf/` holds the harness. Each script sets its paths at the top. They assume the original at
`../base/OpenStock`, built with `next build --turbopack` with `npm ci` done, and a MongoDB at
127.0.0.1:27117.

* `serve.sh orig|jac|before <port>`: start a server.
* `bench.py`: the endpoint table. It reads a better-auth session cookie (`OCOOKIE`) and a Jac
  token (`JTOKEN`) from files: sign up `bench1` on both, add MSFT, NVDA, TSLA and AAPL, and create
  the list "Tech". `load.mjs` is its keep-alive load generator. Sign-in requests come from different
  loopback addresses so that neither side's rate limit applies.
* `startup.py [runs] [path]`: start to first reply. Set `JACDATA` to a directory to time a start on
  kept data.
* `cmdbench.py`: the `check-env` command (`neojac build tools/check_env.jac -o /tmp/osbench/check_env` first).
* `pagebytes.py`: page weight.
