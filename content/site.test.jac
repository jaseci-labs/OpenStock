test "is_public_path lets crawlers and the public sections through" {
    for path in [
        "/",
        "/about",
        "/robots.txt",
        "/sitemap.xml",
        "/s",
        "/s/AAPL",
        "/s/BRK.B",
        "/compare",
        "/compare/self-hosted-stock-tracker",
        "/sponsor",
    ] {
        assert is_public_path(path), path;
    }
}

test "is_public_path keeps the signed-in app private, including paths that share a prefix" {
    for path in [
        "/stocks",
        "/stocks/AAPL",
        "/dashboard",
        "/watchlist",
        "/profile",
        "/sign-in",
        "/something",
    ] {
        assert not is_public_path(path), path;
    }
}

test "sponsor links and compact counts" {
    assert sponsor_checkout_url()
        == "https://github.com/sponsors/ravixalgorithm/sponsorships?frequency=recurring";
    assert sponsor_checkout_url(25, "one-time").endswith("?frequency=one-time&amount=25");
    assert [format_count(n) for n in [999, 1000, 1234, 13049, 2500000]] == [
        "999",
        "1K",
        "1.2K",
        "13K",
        "2.5M",
    ];
}
