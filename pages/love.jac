import from "@jac/runtime" { Link }
import from "lucide-react" { ArrowUpRight, Play }
import from "react-tweet" { Tweet }

# Only real posts, videos and articles about OpenStock. X posts render live from X: add the post id, never its text.
glob PRAISE: list[dict[str, str]] = [
         {"post": "2047252137604948054"},
         {
             "source": "Medium",
             "title": "OpenStock — The Free, Open-Source Stock Market App Built for Everyone",
             "url": "https://medium.com/coding-nexus/openstock-the-free-open-source-stock-market-app-built-for-everyone-af6ae05b87de",
         },
         {"post": "1976950915253834116"},
         {
             "source": "Bright Coding",
             "title": "Stop Paying for Stock Data! OpenStock Is the Free Platform Devs Are Switching To",
             "url": "https://www.blog.brightcoding.dev/2026/07/22/stop-paying-for-stock-data-openstock-is-the-free-platform-devs-are-switching-to",
         },
         {
             "channel": "Gourcer",
             "title": "Open-Dev-Society/OpenStock, Gource visualisation",
             "url": "https://www.youtube.com/watch?v=-RRCzE1sXOw",
             "thumbnail": "https://i.ytimg.com/vi/-RRCzE1sXOw/hqdefault.jpg",
         },
         {
             "source": "Zhihu",
             "title": "这个牛逼的股票市场平台，在 GitHub 上开源了。",
             "url": "https://zhuanlan.zhihu.com/p/1963636115106951213",
         },
         {
             "source": "HelloGitHub",
             "title": "Free and Cool Stock Market App",
             "url": "https://hellogithub.com/en/repository/Open-Dev-Society/OpenStock",
         },
         {"post": "1975379365866430873"},
         {
             "source": "PyShine",
             "title": "OpenStock: An Open-Source Alternative to Expensive Market Platforms",
             "url": "https://pyshine.com/OpenStock-Open-Source-Alternative-to-Expensive-Market-Platforms/",
         },
         {
             "channel": "IT咖啡馆 on bilibili",
             "title": "Github 一周热点 #133: 免费的股票看板",
             "url": "https://www.bilibili.com/video/BV1GbH469Erp/",
         },
         {
             "source": "CSDN",
             "title": "【GitHub项目推荐--OpenStock：开源股票市场平台】",
             "url": "https://blog.csdn.net/j8267643/article/details/153693153",
         },
         {
             "source": "aibit",
             "title": "OpenStock: Your Free Open-Source Market Platform Alternative",
             "url": "https://aibit.im/en/article/openstock-your-free-open-source-market-platform-alternative",
         },
         {"post": "2073376806154219883"},
         {
             "source": "Juejin",
             "title": "GitHub 热榜项目：日榜（2026-09-22）",
             "url": "https://juejin.cn/post/7688170153797746726",
         },
         {
             "source": "CSDN",
             "title": "开源股票数据平台OpenStock：用Next.js+React构建的免费金融分析神器",
             "url": "https://blog.csdn.net/libaiup/article/details/153052265",
         },
         {
             "source": "daily.dev",
             "title": "OpenStock is an open-source alternative to expensive market platforms",
             "url": "https://daily.dev/posts/openstock-is-an-open-source-alternative-to-expensive-market-platforms--0cijqlabk",
         },
     ],
     # Prefilled post for the share button. Keep it within X's 280 characters (the link counts as 23, an emoji as 2).
     SHARE_TEXT: str = "OpenStock: a free, open-source alternative to paid stock terminals.\n\nTradingView charts, watchlists, a sector heatmap and ⌘K search across every exchange. No subscription, and you can self-host it.\n\nBuilt by @ravixalgorithm and Open Dev Society 👇",
     CHIP: str = "mr-3 flex h-16 shrink-0 items-center gap-3 rounded-[14px] bg-card px-5 shadow-[inset_0_0_0_1px_var(--line)] transition-colors hover:bg-hover",
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

def MarqueeRow(items: list[tuple[Sponsor, str, str]], reverse: bool = False) -> JsxElement {
    # Copies after the first are decoration for the loop: hidden from screen readers and skipped by Tab, still clickable
    return <div className={cx("marquee-mask flex overflow-hidden", reverse and "is-extra")}>
        <div className={cx("marquee", reverse and "is-reverse")}>
            {[
                <div key={copy} className="flex shrink-0" aria-hidden={copy > 0 or None}>
                    {[
                        <SponsorLink
                            key={s.name}
                            sponsor={s}
                            tabIndex={-1 if copy > 0 else None}
                            className={CHIP}
                        >
                            {<img
                                src={avatar}
                                alt=""
                                width={32}
                                height={32}
                                loading="lazy"
                                className="size-8 rounded-full"
                            />
                                if avatar
                                else None}
                            {<img
                                src={s.logo}
                                alt={"" if s.icon_only else s.name}
                                className="h-6 w-auto"
                            />
                                if s.logo
                                else None}
                            <span className="flex flex-col gap-0.5">
                                {<span className="text-[14px] font-semibold leading-none">
                                    {s.name}
                                </span>
                                    if not s.logo or s.icon_only
                                    else None}
                                <span className="kicker leading-none">{label}</span>
                            </span>
                        </SponsorLink>
                        for (s, label, avatar) in items
                    ]}
                    <Link
                        to="/sponsor#tiers"
                        tabIndex={-1 if copy > 0 else None}
                        className="mr-3 flex h-16 shrink-0 items-center rounded-[14px] px-5 text-[13px] font-semibold text-faint transition-colors hover:text-brand-ink"
                        style={{"backgroundImage": "repeating-linear-gradient(-45deg, oklch(0.4 0.01 95 / 0.22) 0 1px, transparent 1px 5px)", "boxShadow": "inset 0 0 0 1px var(--line)"}}
                    >
                        Your name here
                    </Link>
                </div>
                for copy in range(4)
            ]}
        </div>
    </div>;
}

def PraiseCard(praise: dict[str, str]) -> JsxElement {
    if "post" in praise {
        return <div className="hatch mb-3 break-inside-avoid">
            <div className="overflow-hidden rounded-[14px]"><Tweet id={praise["post"]} /></div>
        </div>;
    }
    if "channel" in praise {
        return <Go to={praise["url"]} className={CARD}>
            <div className="card overflow-hidden">
                <div className="relative aspect-video bg-page">
                    {<img
                        src={praise["thumbnail"]}
                        alt=""
                        loading="lazy"
                        className="size-full object-cover"
                    />
                        if "thumbnail" in praise
                        else None}
                    <span className="absolute inset-0 grid place-items-center">
                        <span
                            className="grid size-12 place-items-center rounded-full bg-black/65 text-white transition-transform group-hover:scale-110"
                        ><Play className="size-5 fill-current" /></span>
                    </span>
                </div>
                <div className="p-5">
                    <p className="kicker">Video · {praise["channel"]}</p>
                    <p className="mt-2 text-[17px] font-bold leading-snug tracking-[-0.02em]">
                        {praise["title"]}
                    </p>
                </div>
            </div>
        </Go>;
    }
    return <Go to={praise["url"]} className={CARD}>
        <div className="card flex flex-col gap-3 p-5">
            <p className="kicker">Article · {praise["source"]}</p>
            <p className="text-[17px] font-bold leading-snug tracking-[-0.02em]">
                {praise["title"]}
            </p>
            <span className="flex items-center gap-1 text-[13px] font-semibold text-brand-ink">
                Read on {praise["source"]} <ArrowUpRight
                className="size-4 transition-transform group-hover:-translate-y-0.5 group-hover:translate-x-0.5"
            /></span>
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
        <section className="love-wall mx-auto mt-24 max-w-[1200px] px-5">
            <SectionHead
                kicker="In their words"
                title="What people say about OpenStock."
                sub="Posts, videos and write-ups from people who found it, used it and told others."
            />
            <div className="columns-1 gap-3 md:columns-2 lg:columns-3">
                {[<PraiseCard key={p.get("post") or p["url"]} praise={p} /> for p in PRAISE]}
            </div>
            <p className="mt-6 text-[14px] text-faint">
                Made something about OpenStock?{" "}<Go
                to={REPO_URL + "/edit/main/pages/love.jac"}
                className="font-semibold text-brand-ink hover:underline"
            >Add it to this page</Go>
                .
            </p>
        </section>
    </>;
}
