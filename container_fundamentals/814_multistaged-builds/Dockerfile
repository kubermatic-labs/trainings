FROM golang:1.15.2-alpine3.12
RUN mkdir /build
ADD main.go /build/
WORKDIR /build
RUN CGO_ENABLED=0 GOOS=linux go build -o main .
ENTRYPOINT [ "./main" ]
