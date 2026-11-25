test "sponsors name tiers that exist, and the sidebar holds only partners" {
    ids = [t.id for t in SPONSOR_TIERS];
    assert ids == list(TIER_COLOR) == ["backer", "supporter", "company", "partner"];
    assert [t.monthly for t in SPONSOR_TIERS] == [5, 25, 100, 500];
    for s in ACTIVE_SPONSORS + PREVIOUS_SPONSORS {
        assert s.tier in ids
            and s.url.startswith("https://")
            and s.logo.startswith("/assets/"), s.name;
    }
    side = sidebar_sponsors();
    assert [s.name for s in side] == ["Orbit", "Proxy-Seller"]
        and len(side) <= SIDEBAR_SPONSOR_SLOTS;
    assert SPONSOR_TIERS[3].slots == SIDEBAR_SPONSOR_SLOTS
        and "13,000+" in SPONSOR_TIERS[3].perks[1];
    assert tier_border("partner") == "color-mix(in oklch, oklch(0.72 0.14 300) 55%, transparent)";
    perk = ACTIVE_SPONSORS[2].perk;
    assert perk is not None and perk.code == "PROXY90" and perk.note;
}
