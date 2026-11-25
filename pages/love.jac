import from "@jac/runtime" { Link }
import from "lucide-react" { ArrowUpRight, Play }
import from "react-tweet" { Tweet }

# Only real posts, videos and articles about OpenStock. X posts render live from X: add the post id, never its text.
# post | id, article | source | title | url, video | channel | title | url | thumbnail
glob PRAISE: list[list[str]] = rows("""
post | 2047252137604948054
article | Medium | OpenStock — The Free, Open-Source Stock Market App Built for Everyone | https://medium.com/coding-nexus/openstock-the-free-open-source-stock-market-app-built-for-everyone-af6ae05b87de
post | 1976950915253834116
article | Bright Coding | Stop Paying for Stock Data! OpenStock Is the Free Platform Devs Are Switching To | https://www.blog.brightcoding.dev/2026/07/22/stop-paying-for-stock-data-openstock-is-the-free-platform-devs-are-switching-to
video | Gourcer | Open-Dev-Society/OpenStock, Gource visualisation | https://www.youtube.com/watch?v=-RRCzE1sXOw | https://i.ytimg.com/vi/-RRCzE1sXOw/hqdefault.jpg
article | Zhihu | 这个牛逼的股票市场平台，在 GitHub 上开源了。 | https://zhuanlan.zhihu.com/p/1963636115106951213
article | HelloGitHub | Free and Cool Stock Market App | https://hellogithub.com/en/repository/Open-Dev-Society/OpenStock
post | 1975379365866430873
article | PyShine | OpenStock: An Open-Source Alternative to Expensive Market Platforms | https://pyshine.com/OpenStock-Open-Source-Alternative-to-Expensive-Market-Platforms/
video | IT咖啡馆 on bilibili | Github 一周热点 #133: 免费的股票看板 | https://www.bilibili.com/video/BV1GbH469Erp/
article | CSDN | 【GitHub项目推荐--OpenStock：开源股票市场平台】 | https://blog.csdn.net/j8267643/article/details/153693153
article | aibit | OpenStock: Your Free Open-Source Market Platform Alternative | https://aibit.im/en/article/openstock-your-free-open-source-market-platform-alternative
post | 2073376806154219883
article | Juejin | GitHub 热榜项目：日榜（2026-09-22） | https://juejin.cn/post/7688170153797746726
article | CSDN | 开源股票数据平台OpenStock：用Next.js+React构建的免费金融分析神器 | https://blog.csdn.net/libaiup/article/details/153052265
article | daily.dev | OpenStock is an open-source alternative to expensive market platforms | https://daily.dev/posts/openstock-is-an-open-source-alternative-to-expensive-market-platforms--0cijqlabk"""),
     # Prefilled post for the share button. Keep it within X's 280 characters (the link counts as 23, an emoji as 2).
     SHARE_TEXT: str = "OpenStock: a free, open-source alternative to paid stock terminals.\n\nTradingView charts, watchlists, a sector heatmap and ⌘K search across every exchange. No subscription, and you can self-host it.\n\nBuilt by @ravixalgorithm and Open Dev Society 👇",
     CHIP: str = "mr-3 flex h-16 shrink-0 items-center gap-3 rounded-[14px] bg-card px-5 shadow-[inset_0_0_0_1px_var(--line)] transition-colors hover:bg-hover",
     INVITE: str = "mr-3 flex h-16 shrink-0 items-center rounded-[14px] px-5 text-[13px] font-semibold text-faint transition-colors hover:text-brand-ink",
     PLAY: str = "grid size-12 place-items-center rounded-full bg-black/65 text-white transition-transform group-hover:scale-110",
     ARROW: str = "size-4 transition-transform group-hover:-translate-y-0.5 group-hover:translate-x-0.5",
     TITLE: str = "text-[17px] font-bold leading-snug tracking-[-0.02em]",
     CARD: str = "hatch group mb-3 break-inside-avoid";

# Sponsors, past sponsors and past supporters as one row of chips: (sponsor, label, avatar).
# Only a current sponsor's chip offers its perk.
def wall -> list[tuple[Sponsor, str, str]] {
    now = [(s, tier_name(s.tier), "") for s in ACTIVE_SPONSORS];
    past = [
        (
            Sponsor(s.name, s.url, s.logo, s.tier, icon_only=s.icon_only),
            f"Past {tier_name(s.tier).lower()}" + (f" · {s.period}" if s.period else ""),
            "",
        )
        for s in PREVIOUS_SPONSORS
    ];
    backers = [
        (
            Sponsor(name, f"https://github.com/{login}", "", ""),
            "Past supporter",
            f"https://github.com/{login}.png?size=64",
        )
        for (login, name) in PREVIOUS_SUPPORTERS.items()
    ];
    return now + past + backers;
}

def Chip(s: Sponsor, label: str, avatar: str, tabIndex: int | None) -> JsxElement {
    alt = "" if s.icon_only else s.name;
    face = <img
        src={avatar}
        alt=""
        width={32}
        height={32}
        loading="lazy"
        className="size-8 rounded-full"
    />;
    return <SponsorLink sponsor={s} {tabIndex} className={CHIP}>
        {face if avatar else None}
        {<img src={s.logo} {alt} className="h-6 w-auto" /> if s.logo else None}
        <span className="flex flex-col gap-0.5">
            {<span className="text-[14px] font-semibold leading-none">{s.name}</span>
                if not s.logo or s.icon_only
                else None}
            <span className="kicker leading-none">{label}</span>
        </span>
    </SponsorLink>;
}

def MarqueeRow(items: list[tuple[Sponsor, str, str]], reverse: bool = False) -> JsxElement {
    invite = {"backgroundImage": HATCHED, "boxShadow": "inset 0 0 0 1px var(--line)"};
    # Copies after the first are decoration for the loop: hidden from screen readers and skipped by Tab, still clickable
    return <div className={cx("marquee-mask flex overflow-hidden", reverse and "is-extra")}>
        <div className={cx("marquee", reverse and "is-reverse")}>
            {
                for copy in range(4) {
                    skip_tab = -1 if copy > 0 else None;
                    <div key={copy} className="flex shrink-0" aria-hidden={copy > 0 or None}>
                        {[
                            <Chip key={s.name} {s} {label} {avatar} tabIndex={skip_tab} />
                            for (s, label, avatar) in items
                        ]}
                        <Link
                            to="/sponsor#tiers"
                            tabIndex={skip_tab}
                            className={INVITE}
                            style={invite}
                        >
                            Your name here
                        </Link>
                    </div>
                }
            }
        </div>
    </div>;
}

def PraiseCard(praise: list[str]) -> JsxElement {
    if praise[0] == "post" {
        return <div className="hatch mb-3 break-inside-avoid">
            <div className="overflow-hidden rounded-[14px]"><Tweet id={praise[1]} /></div>
        </div>;
    }
    if praise[0] == "video" {
        thumb = <img src={praise[4]} alt="" loading="lazy" className="size-full object-cover" />
            if len(praise) > 4
            else None;
        return <Go to={praise[3]} className={CARD}>
            <div className="card overflow-hidden">
                <div className="relative aspect-video bg-page">
                    {thumb}
                    <span className="absolute inset-0 grid place-items-center">
                        <span className={PLAY}><Play className="size-5 fill-current" /></span>
                    </span>
                </div>
                <div className="p-5">
                    <p className="kicker">Video · {praise[1]}</p>
                    <p className={cx("mt-2", TITLE)}>{praise[2]}</p>
                </div>
            </div>
        </Go>;
    }
    return <Go to={praise[3]} className={CARD}>
        <div className="card flex flex-col gap-3 p-5">
            <p className="kicker">Article · {praise[1]}</p>
            <p className={TITLE}>{praise[2]}</p>
            <span className="flex items-center gap-1 text-[13px] font-semibold text-brand-ink">
                Read on {praise[1]} <ArrowUpRight className={ARROW} /></span>
        </div>
    </Go>;
}

def:pub page -> JsxPage {
    items = wall();
    share = f"https://x.com/intent/post?text={encodeURIComponent(SHARE_TEXT)}&url={encodeURIComponent(REPO_URL)}";
    return <>
        <PageHero
            kicker="Wall of love"
            title="Thank you for keeping OpenStock free."
            sub="The sponsors who pay the bills, the supporters who chip in, and everyone who writes, posts or films something about it."
        >
            <Link to="/sponsor" className={CTA}>Become a sponsor</Link>
            <Go to={share} className={CTA_GHOST}>Post about OpenStock</Go>
        </PageHero>
        <section className="mt-16 flex flex-col gap-3" aria-label="Sponsors and supporters">
            <MarqueeRow {items} />
            <MarqueeRow items={items[::-1]} reverse />
        </section>
        <Band
            className="love-wall mt-24"
            kicker="In their words"
            title="What people say about OpenStock."
            sub="Posts, videos and write-ups from people who found it, used it and told others."
        >
            <div className="columns-1 gap-3 md:columns-2 lg:columns-3">
                {[<PraiseCard key={p[1] if p[0] == "post" else p[3]} praise={p} /> for p in PRAISE]}
            </div>
            <p className="mt-6 text-[14px] text-faint">
                Made something about OpenStock?{" "}<Go
                to={REPO_URL + "/edit/main/pages/love.jac"}
                className={LINK}
            >Add it to this page</Go>
                .
            </p>
        </Band>
    </>;
}
