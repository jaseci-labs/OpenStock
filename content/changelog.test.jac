test "every release parses whole, newest first" {
    assert len(RELEASES) == 11 and RELEASES[0].id == "2026-11-22" and RELEASES[-1].id == "2025-10";
    assert [r.id for r in RELEASES] == sorted([r.id for r in RELEASES], reverse=True);
    for r in RELEASES {
        assert r.date and r.title and r.summary and r.sections and r.credits, r.id;
        assert all([s.title and s.items for s in r.sections]), r.id;
        assert all([c.prs or c.issues for c in r.credits]), r.id;
    }
    latest = RELEASES[0];
    assert latest.title == "Late November update" and len(latest.highlights) == 6;
    assert [s.title for s in latest.sections][:3] == ["Languages", "Watchlist", "Alerts"];
    assert latest.sections[0].items[0].endswith("in the sidebar. #157");
    assert latest.credits[0] == Credit("ravixalgorithm", [150, 154, 175, 180, 181, 183, 184, 185]);
    assert latest.credits[-1] == Credit("soarkit", issues=[144, 149, 159, 160, 161]);
    assert not RELEASES[3].highlights;
}

test "contributors merge across releases, the maintainer first" {
    people = contributors();
    assert people[0].login == MAINTAINER and len(people[0].prs) > 40;
    assert len({c.login for c in people}) == len(people) > 40;
    assert [len(c.prs) for c in people[1:]]
        == sorted([len(c.prs) for c in people[1:]], reverse=True);
    soarkit = [c for c in people if c.login == "soarkit"][0];
    assert soarkit.issues == [144, 149, 159, 160, 161, 143];
    # Merging must not grow the releases' own credits.
    assert len(contributors()[0].prs) == len(people[0].prs);
}

test "credit labels" {
    assert credit_label(Credit("a", [1])) == "1 PR";
    assert credit_label(Credit("a", [1, 2], [3])) == "2 PRs · 1 issue";
    assert credit_title(Credit("a", [1, 2], [3])) == "Pull requests #1 #2 · Issues #3";
    assert credit_title(Credit("a", issues=[3, 4])) == "Issues #3 #4";
}
