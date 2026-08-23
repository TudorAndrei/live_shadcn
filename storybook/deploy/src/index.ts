// The storybook, in front of Cloudflare Containers.
//
// The Worker does one thing: it hands every request to the one container that
// runs the Phoenix release. There is no routing to do — the storybook is a
// demo, every reader sees the same pages, and none of them is behind a login.

import { Container, getContainer } from "@cloudflare/containers";

// The Container base class names its own state type; borrowing it keeps this
// subclass honest across upgrades rather than guessing at DurableObjectState.
type ContainerCtx = ConstructorParameters<typeof Container>[0];

type Env = {
  STORYBOOK: DurableObjectNamespace<Storybook>;
  // A Worker secret. `runtime.exs` refuses to boot without it: the storybook
  // holds nothing worth protecting, but LiveView still signs its socket.
  SECRET_KEY_BASE: string;
  PHX_HOST: string;
};

export class Storybook extends Container<Env> {
  // What the release listens on, and what the Dockerfile exposes.
  defaultPort = 4100;

  // A demo nobody is reading costs nothing to keep asleep. The first request
  // after that pays a cold start, which for a Phoenix release is a second or
  // two, and every request after it renews the timer.
  sleepAfter = "20m";

  constructor(ctx: ContainerCtx, env: Env) {
    super(ctx, env);

    this.envVars = {
      SECRET_KEY_BASE: env.SECRET_KEY_BASE,
      PHX_HOST: env.PHX_HOST,
    };
  }
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    // Without this the container starts, the release raises, and the reader
    // gets a timeout that says nothing about why.
    if (!env.SECRET_KEY_BASE) {
      return new Response(
        "SECRET_KEY_BASE is not set. Run:\n\n" +
          "  cd storybook && mix phx.gen.secret\n" +
          "  cd deploy && npx wrangler secret put SECRET_KEY_BASE\n",
        { status: 500, headers: { "content-type": "text/plain" } },
      );
    }

    return getContainer(env.STORYBOOK, "storybook").fetch(request);
  },
};
