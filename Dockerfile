FROM plangora/alpine-elixir-phoenix:otp-24.0.1-elixir-1.12.0 as phx-builder

ENV PORT=4000 MIX_ENV=prod

ADD . .

# Run frontend build, compile, and digest assets, and set default to own the directory
RUN mix deps.get && cd assets/ && \
		npm install && \
    npm run deploy && \
    cd - && \
    mix do compile, phx.digest, release

FROM plangora/alpine-erlang:24.0.1

EXPOSE 4000
ENV PORT=4000 MIX_ENV=prod

COPY --from=phx-builder /opt/app/_build/prod/rel/transigo_admin/ /opt/app/
RUN chown -R default /opt/app/

USER default

CMD ["/opt/app/bin/transigo_admin", "start"]
