ARG BRANCH=master

FROM rust:1.67.0-slim-buster AS builder
ARG BRANCH
WORKDIR /build
RUN apt-get update
RUN apt-get install -y libssl-dev git
RUN git clone --branch ${BRANCH} --depth 1 https://github.com/casey/ord.git .
# cargo under QEMU building for ARM can consumes 10s of GBs of RAM...
# Solution: https://users.rust-lang.org/t/cargo-uses-too-much-memory-being-run-in-qemu/76531/2
ENV CARGO_NET_GIT_FETCH_WITH_CLI true
RUN cargo build --release

FROM debian:buster-slim
# override these values by setting environment in docker-compose or cli
ARG APP_PORT=8080
ARG BITCOIN_DATA_DIR=/data/.bitcoin
ARG BITCOIN_COOKIE_FILE=${BITCOIN_DATA_DIR}/.cookie
EXPOSE ${APP_PORT}
COPY --from=builder /build/target/release/ord /bin/ord
USER 1000
ENTRYPOINT ["/bin/ord"]
CMD ["--data-dir", "${BITCOIN_DATA_DIR}", "--cookie-file", "${BITCOIN_COOKIE_FILE}", "server", "--http-port", "${APP_PORT}"]
