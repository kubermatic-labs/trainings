FROM alpine:3.13.3
RUN apk update --no-cache
USER nobody:nobody
WORKDIR /home/nobody
COPY my-webserver ./my-webserver
ENTRYPOINT ["./my-webserver"]
