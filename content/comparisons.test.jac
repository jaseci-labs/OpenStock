test "every guide parses whole and is found by its slug" {
    assert [g.slug for g in GUIDES] == [
        "free-tradingview-alternative",
        "self-hosted-stock-tracker",
        "free-stock-watchlist",
        "open-source-bloomberg-alternative",
        "stock-market-app-for-students",
        "track-nse-stocks",
    ];
    for g in GUIDES {
        assert g.kicker and g.title and g.description and g.lede, g.slug;
        assert len(g.sections) == 3 and len(g.faqs) == 3, g.slug;
        assert all([s.heading and s.paragraphs for s in g.sections]), g.slug;
        assert all([f.question.endswith("?") and f.answer for f in g.faqs]), g.slug;
        found = find_guide(g.slug);
        assert found is not None and found.title == g.title;
    }
    first = GUIDES[0];
    assert first.title == "Free TradingView alternative (open source)";
    assert first.description.startswith("OpenStock is a free, open-source stock tracker.");
    assert first.lede.startswith("If you want Pine Script");
    assert [len(s.paragraphs) for s in first.sections] == [2, 2, 1];
    assert first.faqs[0].answer.startswith("No. The charts are their free embeds.");
    assert find_guide("nope") is None;
}
