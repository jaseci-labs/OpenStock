"""Every release as a timeline, and everyone whose pull request or issue shaped one."""
import from "@jac/runtime" { Link }

glob PEOPLE: list[Credit] = contributors(),
     CHIP: str = "flex items-center gap-2 rounded-full bg-card py-1 pl-1 pr-3 shadow-[inset_0_0_0_1px_var(--line)] transition-colors hover:bg-hover",
     PR: str = "mono ml-1.5 text-[12px] text-faint transition-colors hover:text-brand-ink";

# An item's text, each "#123" in it a link to that pull request
def ItemText(text: str) -> JsxElement {
    parts: list[any] = [];
    plain: list[str] = [];
    for word in text.split(" ") {
        ref = word.rstrip(",.");
        if ref[1:].isdigit() and ref[0] == "#" {
            parts += [
                " ".join(plain),
                <Go key={len(parts)} to={f"{REPO_URL}/pull/{ref[1:]}"} className={PR}>{ref}</Go>,
            ];
            plain = [word[len(ref):]];
        } else {
            plain.append(word);
        }
    }
    return <span className="text-muted-foreground">{parts}{" ".join(plain)}</span>;
}

def Avatar(login: str, size: int) -> JsxElement {
    return <img
        src={f"https://github.com/{login}.png?size={size * 2}"}
        alt=""
        width={size}
        height={size}
        loading="lazy"
        className="flex-none rounded-full bg-page"
    />;
}

# One release of the timeline: a line down its left (but under the last), with a dot at its title
def ReleaseItem(release: Release, latest: bool, last: bool) -> JsxElement {
    return <li className="grid gap-3 md:grid-cols-[150px_minmax(0,1fr)] md:gap-8">
        <div className="md:sticky md:top-24 md:self-start md:pt-0.5 md:text-right">
            <p className="kicker text-foreground">{release.date}</p>
            {<span className="pill is-brand mt-2">Latest</span> if latest else None}
        </div>
        <section
            aria-labelledby={f"release-{release.id}"}
            className={cx("relative pl-8", not last and "pb-16")}
        >
            {None
                if last
                else <span
                    className="absolute left-[5px] top-3 bottom-0 w-px bg-line"
                    aria-hidden
                />}
            <span
                className={cx("absolute left-0 top-1.5 size-[11px] rounded-full ring-4 ring-page", "bg-brand" if latest else "bg-line-strong")}
                aria-hidden
            />
            <h2
                id={f"release-{release.id}"}
                className="text-[24px] font-bold leading-tight tracking-[-0.03em] md:text-[28px]"
            >{release.title}</h2>
            <p className="mt-1.5 text-[15px] text-muted-foreground">{release.summary}.</p>
            <div className={cx("mt-6 grid gap-3", len(release.sections) > 1 and "lg:grid-cols-2")}>
                {[
                    <div key={section.title} className="hatch">
                        <div className="card h-full p-5">
                            <h3 className="kicker">{section.title}</h3>
                            <ul className="mt-3 flex flex-col gap-2.5 text-[14px] leading-relaxed">
                                {[
                                    <li key={item} className="flex gap-2.5">
                                        <span
                                            className="mt-[9px] size-1 flex-none rounded-full bg-brand"
                                            aria-hidden
                                        />
                                        <ItemText text={item} />
                                    </li>
                                    for item in section.items
                                ]}
                            </ul>
                        </div>
                    </div>
                    for section in release.sections
                ]}
            </div>
            <div className="mt-4 flex flex-wrap items-center gap-2">
                <span className="kicker mr-1">Thanks to</span>
                {[
                    <Go
                        key={c.login}
                        to={f"https://github.com/{c.login}"}
                        title={credit_title(c)}
                        className={CHIP}
                    >
                        <Avatar login={c.login} size={22} />
                        <span className="text-[13px] font-semibold text-foreground">{c.login}</span>
                        <span className="text-[12px] text-faint">{credit_label(c)}</span>
                    </Go>
                    for c in release.credits
                ]}
            </div>
        </section>
    </li>;
}

def:pub page -> JsxPage {
    return <>
        <PageHero
            kicker="Changelog"
            title="Everything that changed in OpenStock."
            sub="Every release since we started in September 2025, in plain words. Each change links to its pull request on GitHub."
        >
            <Link to="/dashboard" className={CTA}>Open dashboard</Link>
            <a href="#contributors" className={CTA_GHOST}>Meet the {len(PEOPLE)} contributors</a>
        </PageHero>
        <ol className="mx-auto mt-16 max-w-[1200px] px-5">
            {[
                <ReleaseItem key={r.id} release={r} latest={i == 0} last={i == len(RELEASES) - 1} />
                for (i, r) in enumerate(RELEASES)
            ]}
        </ol>
        <section id="contributors" className="mx-auto mt-24 max-w-[1200px] scroll-mt-24 px-5">
            <SectionHead
                kicker="Contributors"
                title={f"Built by {len(PEOPLE)} people."}
                sub="Everyone whose pull request or issue shaped a release above. Thank you: this is your work."
            />
            <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
                {[
                    <Go
                        key={p.login}
                        to={f"https://github.com/{p.login}"}
                        title={credit_title(p)}
                        className="hatch group"
                    >
                        <div
                            className="card flex items-center gap-3 p-4 transition-colors group-hover:bg-hover"
                        >
                            <Avatar login={p.login} size={40} />
                            <div className="min-w-0">
                                <p className="flex items-center gap-2 font-semibold">
                                    <span className="truncate">{p.login}</span>
                                    {<span className="pill is-brand shrink-0">Maintainer</span>
                                        if p.login == MAINTAINER
                                        else None}
                                </p>
                                <p className="text-[13px] text-faint">{credit_label(p)}</p>
                            </div>
                        </div>
                    </Go>
                    for p in PEOPLE
                ]}
            </div>
            <p className="mt-6 text-[14px] text-faint">
                Want to be here? Pick a{" "}<Go
                to={GOOD_FIRST_ISSUES_URL}
                className="font-semibold text-brand-ink hover:underline"
            >
                    good first issue
                </Go>{" "}or report a bug you hit.
            </p>
        </section>
    </>;
}
