import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";
import jac from "@jac/vite";

export default defineConfig({
    plugins: [jac(), react(), tailwindcss()],
});
