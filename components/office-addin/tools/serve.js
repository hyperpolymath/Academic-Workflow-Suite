import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { serveDir } from "https://deno.land/std@0.224.0/http/file_server.ts";

const distDir = "dist";
const port = Number(Deno.env.get("PORT") ?? 8080);

console.log(`Serving ${distDir} on http://localhost:${port}`);

serve((request) => serveDir(request, { fsRoot: distDir }), { port });
