ARG GO_IMAGE=golang:latest

FROM ${GO_IMAGE}

RUN go get -u github.com/pressly/goose/cmd/goose

WORKDIR /migrations
ADD . .

ENTRYPOINT ["goose", "postgres"]
