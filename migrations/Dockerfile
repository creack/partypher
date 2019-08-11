FROM golang:1.12

RUN go get -u github.com/pressly/goose/cmd/goose

WORKDIR /migrations
ADD . .

ENTRYPOINT ["goose", "postgres"]
