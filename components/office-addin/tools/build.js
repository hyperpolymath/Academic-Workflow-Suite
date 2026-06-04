// SPDX-License-Identifier: MPL-2.0
// Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
import { build, stop } from "https://deno.land/x/esbuild@v0.20.2/mod.js";
import { ensureDir, copy } from "https://deno.land/std@0.224.0/fs/mod.ts";
import { join } from "https://deno.land/std@0.224.0/path/mod.ts";

const distDir = "dist";
const publicDir = "public";
const assetsDir = join(publicDir, "assets");

await ensureDir(distDir);

await build({
  entryPoints: {
    addin: "src/AWAPAddin.bs.js",
    commands: "src/RibbonCommands.bs.js",
    taskpane: "src/TaskPane.bs.js",
  },
  bundle: true,
  format: "iife",
  platform: "browser",
  outdir: distDir,
  sourcemap: true,
});

await injectScript("commands", "commands.js");
await injectScript("taskpane", "taskpane.js");

await copy("manifest.xml", join(distDir, "manifest.xml"), { overwrite: true });
if (await exists(assetsDir)) {
  await copy(assetsDir, join(distDir, "assets"), { overwrite: true });
}

stop();

async function injectScript(templateName, scriptFile) {
  const templatePath = join(publicDir, `${templateName}.html`);
  const targetPath = join(distDir, `${templateName}.html`);
  const html = await Deno.readTextFile(templatePath);
  const injected = html.replace(
    "</body>",
    `  <script src="${scriptFile}"></script>\n</body>`,
  );
  await Deno.writeTextFile(targetPath, injected);
}

async function exists(path) {
  try {
    await Deno.stat(path);
    return true;
  } catch {
    return false;
  }
}
