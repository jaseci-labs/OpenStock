graph layers {
    layer all { *; }
}

graph spaces {
    space api: native { svc; }

    app api { run api; }
}
