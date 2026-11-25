import from "lucide-react" { Code, Globe, Heart }

glob ICONS: list[any] = [Globe, Code, Heart],
     PRINCIPLES: list[list[str]] = rows("""
Open access | No paywall on the core. Charts, watchlists and research stay free for everyone, and self-hosting unlocks everything.
Open source | Fully transparent codebase. Audit our algorithms, contribute features, and build with us.
Community driven | Powered by donations and volunteers. We answer to our users, not shareholders."""),
     STORY: str = "grid items-center gap-10 p-8 md:grid-cols-[minmax(0,1.3fr)_minmax(0,1fr)] md:p-12",
     BODY: str = "text-[16px] leading-relaxed text-muted-foreground",
     FRAME: str = "relative grid aspect-square max-h-[340px] place-items-center rounded-[16px] bg-page shadow-[inset_0_0_0_1px_var(--line)]";

def:pub page -> JsxPage {
    logo = "absolute inset-0 size-full object-contain p-16 opacity-90";
    return <>
        <PageHero
            kicker="About"
            title="Tools for everyone."
            sub="We believe financial intelligence shouldn’t be locked behind paywalls. OpenStock is built by the community, for the community."
        >
            <Go to={REPO_URL} className={CTA}>See the code</Go>
            <Go to={GOOD_FIRST_ISSUES_URL} className={CTA_GHOST}>Contribute</Go>
        </PageHero>
        <Band className="mt-20" kicker="Principles" title="What we won’t compromise on.">
            <div className="grid gap-3 md:grid-cols-3">
                {[
                    <IconCard key={p[0]} icon={ICONS[i]} title={p[0]}>{p[1]}</IconCard>
                    for (i, p) in enumerate(PRINCIPLES)
                ]}
            </div>
        </Band>
        <Band>
            <Hatch className={STORY}>
                <div className="flex flex-col gap-4">
                    <p className="kicker text-brand-ink">Open Dev Society</p>
                    <h2 className="text-[30px] font-bold leading-tight tracking-[-0.04em]">
                        Born from a simple frustration.
                    </h2>
                    <p
                        className={BODY}
                    >Why are powerful financial tools so expensive? OpenStock is our answer.</p>
                    <p className={BODY}>
                        We are a collective of developers, designers and financial enthusiasts working under the Open Dev Society
                        banner. Our mission is to democratise software by building high-quality, open-source alternatives to
                        proprietary platforms.
                    </p>
                    <Go
                        to="https://github.com/Open-Dev-Society"
                        className="btn btn-ghost mt-2 self-start"
                    >
                        Open Dev Society on GitHub
                    </Go>
                </div>
                <div className={FRAME}>
                    <img src="/assets/icons/odsLogo.svg" alt="Open Dev Society" className={logo} />
                </div>
            </Hatch>
        </Band>
    </>;
}
