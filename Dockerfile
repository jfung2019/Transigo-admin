FROM bitwalker/alpine-elixir-phoenix:latest as phx-builder

ENV PORT=4000 MIX_ENV=prod

ADD . .

# Run frontend build, compile, and digest assets, and set default to own the directory
RUN mix deps.get && cd assets/ && \
		npm install && npm rebuild node-sass && \
    npm run deploy && \
    cd - && \
    mix do compile, phx.digest, release

FROM bitwalker/alpine-erlang:21.3.8

EXPOSE 4000
ENV PORT=4000 MIX_ENV=prod

COPY --from=phx-builder /opt/app/_build/prod/rel/transigo_admin/ /opt/app/
RUN chown -R default /opt/app/

USER default

CMD ["/opt/app/bin/transigo_admin", "foreground"]
