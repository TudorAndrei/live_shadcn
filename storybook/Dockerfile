# The storybook, as one image.
#
# It is a demo application, so it holds no data and reaches no database. What it
# does need is unusual: the shadcn styling layer is gitignored, so the build has
# to run `mix ui.fetch` before it can compile any CSS. That is deliberate —
# this repository records a digest per upstream file rather than redistributing
# anybody else's source — and it means the image build needs network access to
# GitHub and base-ui.com, once, in the builder stage.

ARG ELIXIR=1.20.3
ARG OTP=29.0.1
ARG DEBIAN=bookworm-20250630-slim

FROM hexpm/elixir:${ELIXIR}-erlang-${OTP}-debian-${DEBIAN} AS builder

ARG DEBIAN
ENV MIX_ENV=prod

RUN apt-get update -y \
    && apt-get install -y --no-install-recommends build-essential git ca-certificates curl \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN mix local.hex --force && mix local.rebar --force

WORKDIR /build

# The whole monorepo: the storybook depends on the packages by path, and the
# asset build reads the registry beside them.
COPY mix.exs* ./
COPY packages ./packages
COPY registry ./registry
COPY tools ./tools
COPY storybook ./storybook

# The styling layer, from the commit registry/UPSTREAM.json pins.
RUN cd tools && mix deps.get --only prod && mix ui.fetch

WORKDIR /build/storybook

RUN mix deps.get --only prod && mix deps.compile
RUN cd assets && npm ci
RUN mix assets.deploy
RUN mix compile
RUN mix release

FROM debian:${DEBIAN} AS runtime

RUN apt-get update -y \
    && apt-get install -y --no-install-recommends libstdc++6 openssl libncurses6 locales ca-certificates \
    && apt-get clean && rm -rf /var/lib/apt/lists/* \
    && sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8 MIX_ENV=prod PHX_SERVER=true

WORKDIR /app
RUN chown nobody /app
COPY --from=builder --chown=nobody:root /build/storybook/_build/prod/rel/storybook ./

USER nobody
EXPOSE 4100

CMD ["/app/bin/storybook", "start"]
