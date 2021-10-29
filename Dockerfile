# BUILDER
#FROM ekidd/rust-musl-builder:stable as builder
FROM messense/rust-musl-cross:arm-musleabi as builder
RUN rustup target add arm-unknown-linux-musleabi	
RUN USER=root cargo new --bin rust-auth
WORKDIR ./rust-auth
COPY Cargo.toml Cargo.lock ./
RUN cargo build --release 
RUN rm src/*.rs

ADD . ./
#RUN rm ./target/x86_64-unknown-linux-musl/release/deps/rust_auth*
RUN rm ./target/arm-unknown-linux-musleabi/release/deps/rust_auth*
COPY templates ./templates
RUN cargo build --release 

#IMAGE 
FROM alpine:latest
ARG APP=/usr/src/rust-auth
EXPOSE 8000
ENV TZ=Etc/UTC \
  APP_USER=appuser

RUN addgroup -S $APP_USER \
  && adduser -S -g $APP_USER $APP_USER

RUN apk update \
  && apk add --no-cache ca-certificates tzdata bash \
  && rm -rf /var/cache/apk/*

#COPY --from=builder /home/rust/src/rust-auth/target/x86_64-unknown-linux-musl/release/rust-auth ${APP}/rust-auth
COPY --from=builder /home/rust/src/rust-auth/target/arm-unknown-linux-musleabi/release/rust-auth ${APP}/rust-auth

RUN chown -R $APP_USER:$APP_USER ${APP}

USER $APP_USER
WORKDIR ${APP}
ENV APP_NAME='Rust Auth Server'
ENV ISSUER='rust-auth-server'
ENV JWT_LIFE_SPAN=1800
ENV PRIVATE_KEY='my private key'
ENV IDENTITY_ENDPOINT=http://cluster:8000/oauth/identity
ENV TOKEN_ENDPOINT=http://localhost:8000/oauth/token
ENV REDIRECT_URL=http://localhost:8000/local/callback?
ENV MONGO_DB_URI='mongodb+srv://mongoUser:QRYTwyxRP61G9Wx1@db-cluster.i4zkb.mongodb.net/auth-db?retryWrites=true&w=majority'

CMD ["./rust-auth"]