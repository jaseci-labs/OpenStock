test "paths, anchors and dates" {
    assert ticker_path("BRK.B") == "/s/BRK.B";
    assert sector_anchor("Information Technology") == "information-technology";
    assert sector_anchor(" Health  Care & more ") == "health-care-more";
    assert company_browse_url("0000320193")
        == "https://www.sec.gov/edgar/browse/?CIK=320193&owner=exclude";
    assert format_filing_date("2025-10-31") == "October 31, 2025";
    assert format_filing_date("soon") == "soon"
        and format_filing_date("2025-13-01") == "2025-13-01";
    assert "518 S&P 500 and Nasdaq-100 companies" in directory_description(518);
}
