import { cpSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";
import jac from "@jac/vite";

// @jac/vite points Vite's public directory at the build's own, so public/ (the logos and
// images the pages name as /assets/..., and favicon.ico) is copied beside the bundle here.
const publicFiles = () => ({
    name: "openstock-public-files",
    writeBundle(options: { dir?: string }) {
        if (options.dir) cpSync(fileURLToPath(new URL("./public", import.meta.url)), options.dir, { recursive: true });
    },
});

export default defineConfig({
    plugins: [jac(), react(), tailwindcss(), publicFiles()],
});
