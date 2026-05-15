import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  pi.on("session_start", async (_event, ctx) => {
    ctx.ui.notify("Loaded pifiles-default", "info");
  });

  pi.registerCommand("pifiles-ping", {
    description: "Verify pifiles default extension is loaded",
    handler: async (_args, ctx) => {
      ctx.ui.notify("pifiles default extension is active", "success");
    },
  });
}
