"""The primitives every page is built of: class joining, toasts, dialog, menu, panel, price bits."""
import from "react-dom" { createPortal }
import from "lucide-react" { ArrowDownRight, ArrowUpRight, Check, X }
import from "sonner" { Toaster, toast }

glob MENU_ITEM: str = "hover:bg-accent hover:text-accent-foreground focus-visible:bg-accent relative flex w-full cursor-default items-center gap-2 rounded-sm px-2 py-1.5 text-start text-sm outline-hidden select-none disabled:pointer-events-none disabled:opacity-50 [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4";

# Class names joined, leaving out whatever is false or empty
def:pub cx(*names: any) -> str {
    return " ".join([str(n) for n in names if n]);
}

def:pub Toasts -> JsxElement {
    return <Toaster
        className="toaster group"
        style={{"--normal-bg": "var(--popover)", "--normal-text": "var(--popover-foreground)", "--normal-border": "var(--border)"}}
    />;
}

def:pub toast_error(title: str, description: str = "") {
    toast.error(title, {"description": description or None});
}

def:pub toast_ok(title: str, description: str = "") {
    toast.success(title, {"description": description or None});
}

# A modal over the page, closed by its X, Escape or a click outside. `className` is its whole
# inner layout (grid, gap, padding, width), so no two utilities ever compete. Rendered into <body>, so a
# transformed ancestor (the sliding sidebar) never becomes what `fixed` is measured from.
def:pub Dialog(
    open: bool,
    onClose: Callable[[], None],
    children: any,
    className: str = "grid gap-4 p-6 sm:max-w-lg",
    label: str = "",
) -> JsxElement | None {
    has on_key: Ref[any] = Ref(None);

    can with [open] entry {
        on_key.current = lambda (e: any) {
            if e.key == "Escape" {
                onClose();
            }
        };
        if open {
            document.addEventListener("keydown", on_key.current);
        }
    }

    can with [open] exit {
        document.removeEventListener("keydown", on_key.current);
    }

    if not open {
        return None;
    }
    return createPortal(
        <div
            className="animate-in fade-in-0 fixed inset-0 z-50 bg-page/60 backdrop-blur-[3px]"
            onMouseDown={lambda { onClose(); }}
        >
            <div
                role="dialog"
                aria-modal="true"
                aria-label={label or None}
                onMouseDown={lambda (e: any) { e.stopPropagation(); }}
                className={cx("bg-card animate-in fade-in-0 zoom-in-95 fixed top-[50%] left-[50%] z-50 w-full max-w-[calc(100%-2rem)] translate-x-[-50%] translate-y-[-50%] rounded-2xl border border-line shadow-[0_0_0_4px_var(--frame),0_24px_60px_oklch(0_0_0/0.55)] duration-200", className)}
            >
                {children}
                <button
                    type="button"
                    aria-label="Close"
                    onClick={lambda { onClose(); }}
                    className="absolute top-4 end-4 grid size-8 place-items-center rounded-full text-faint transition-[background-color,color,transform] hover:bg-hover hover:text-foreground active:scale-94 focus-visible:ring-2 focus-visible:ring-ring focus:outline-hidden [&_svg]:size-4"
                ><X /></button>
            </div>
        </div>,
        document.body,
    );
}

# A button that opens a panel beside itself (from its end edge with `end`): a dropdown menu, or any popover. A click on anything
# inside marked `data-close` (every MenuItem, unless keepOpen) closes it, as do Escape and a click outside.
def:pub Menu(
    trigger: any,
    children: any,
    className: str = "",
    panelClassName: str = "",
    up: bool = False,
    end: bool = False,
    **rest: any,
) -> JsxElement {
    has open: bool = False;
    has box: Ref[any] = Ref(None);
    has away: Ref[any] = Ref(None);

    can with [open] entry {
        away.current = lambda (e: any) {
            if (e.type == "keydown" and e.key == "Escape")
                or (e.type == "mousedown" and not box.current.contains(e.target))
            {
                open = False;
            }
        };
        if open {
            document.addEventListener("mousedown", away.current);
            document.addEventListener("keydown", away.current);
        }
    }

    can with [open] exit {
        document.removeEventListener("mousedown", away.current);
        document.removeEventListener("keydown", away.current);
    }

    return <div ref={box} className="relative">
        <button
            type="button"
            aria-expanded={open}
            className={className}
            onClick={lambda { open = not open; }}
            {...rest}
        >{trigger}</button>
        {<div
            role="menu"
            onClick={lambda (e: any) {
                if e.target.closest("[data-close]") {
                    open = False;
                }
            }}
            className={cx("bg-popover text-popover-foreground animate-in fade-in-0 zoom-in-95 absolute z-50 max-h-80 min-w-[8rem] overflow-y-auto rounded-md border p-1 shadow-md", "bottom-full mb-1" if up else "top-full mt-1", "end-0" if end else "start-0", panelClassName)}
        >{children}</div>
            if open
            else None}
    </div>;
}

# `checked` given makes it a checkbox item (a tick), with `radio` a radio item (a dot)
def:pub MenuItem(
    children: any,
    onSelect: Callable[[], None],
    checked: bool | None = None,
    radio: bool = False,
    keepOpen: bool = False,
    **rest: any,
) -> JsxElement {
    return <button
        type="button"
        role="menuitem"
        data-close={None if keepOpen else ""}
        onClick={lambda { onSelect(); }}
        className={cx(MENU_ITEM, checked is not None and "ps-8")}
        {...rest}
    >
        {<span
            className="pointer-events-none absolute start-2 flex size-3.5 items-center justify-center"
        >
            {(<span className="size-2 rounded-full bg-current" /> if radio else <Check />)
                if checked
                else None}
        </span>
            if checked is not None
            else None}
        {children}
    </button>;
}

# Concentric hatch shell: a recessed hatched frame holding one raised card
def:pub Panel(
    children: any,
    title: str = "",
    sub: any = None,
    action: any = None,
    className: str = "",
    bodyClassName: str = "",
) -> JsxElement {
    return <section className={cx("hatch", className)}>
        {<div className="section-head">
            <div className="min-w-0">
                <h2 className="section-title">{title}</h2>
                {<p className="section-sub">{sub}</p> if sub else None}
            </div>
            {action}
        </div>
            if title
            else None}
        <div className={cx("card", bodyClassName)}>{children}</div>
    </section>;
}

# Direction is carried by colour and arrow, so it never relies on colour alone
def:pub ChangePill(value: float | None = None) -> JsxElement {
    if value is None or not isFinite(value) {
        return <span className="pill">—</span>;
    }
    if value == 0 {
        return <span className="pill">0.00%</span>;
    }
    return <span className={"pill is-up" if value > 0 else "pill is-down"}>
        {<ArrowUpRight /> if value > 0 else <ArrowDownRight />}
        {f"{abs(value):.2f}%"}
    </span>;
}

# Briefly tints its content up or down when `value` changes, so live updates are noticed without shouting
def:pub PriceFlash(children: any, value: float | None = None, className: str = "") -> JsxElement {
    has previous: Ref[any] = Ref(value);
    has direction: str = "";

    can with [value] entry {
        before = previous.current;
        previous.current = value;
        if value is not None and before is not None and value != before {
            direction = "up" if value > before else "down";
            setTimeout(lambda { direction = ""; }, 900);
        }
    }

    return <span className={cx(className, direction and f"flash-{direction}")}>{children}</span>;
}

# Honest label for how old a number is: "Live" in realtime mode, otherwise the time of the last
# trade (seconds since 1970) in the viewer's own time zone. `loc` is the language; pass "en" on public pages.
def:pub DataFreshness(
    loc: str, tradeTime: float | None = None, realtime: bool = False
) -> JsxElement {
    if realtime {
        return <span className="inline-flex items-center gap-1.5 text-[12px] text-faint"><span
            className="live-dot"
        /> {tr(loc, "DataFreshness.live")}</span>;
    }
    shown = {"month": "short", "day": "numeric", "hour": "numeric", "minute": "2-digit"};
    return <span className="text-[12px] text-faint">
        {tr(
            loc,
            "DataFreshness.asOf",
            {
                "time": new(Date, tradeTime * 1000).toLocaleString(
                    "en-US" if loc == "en" else loc, shown
                ),
            },
        )
            if tradeTime
            else tr(loc, "DataFreshness.delayed")}
    </span>;
}

# Shown inside the workspace while a page loads, so navigation never feels frozen
def:pub Loading -> JsxElement {
    return <div className="flex flex-col gap-3" aria-busy="true" aria-label={t("Common.loading")}>
        <div className="flex flex-col gap-2 px-1 pt-1">
            <span className="h-7 w-48 animate-pulse rounded-lg bg-hover" />
            <span className="h-4 w-72 animate-pulse rounded-md bg-hover/70" />
        </div>
        <section className="hatch">
            <div className="bento">
                {[
                    <div key={i} className="bento-tile h-[124px]">
                        <span className="h-full animate-pulse rounded-lg bg-hover/60" />
                    </div>
                    for i in range(4)
                ]}
            </div>
        </section>
        <section className="hatch"><div className="card h-[420px] animate-pulse" /></section>
    </div>;
}
