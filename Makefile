NAME = partypher

PG_I        = postgres:12
PG_C        = ${NAME}_pg_c
PG_DB       = partypher

PG_DSN = postgres://postgres@$(shell cat .pg_ip 2> /dev/null):5432/${PG_DB}?sslmode=disable
export PG_DSN

SRCS := $(shell find . -name '*.go' -type f)

GOOSE_DIR        = ./migrations
GOOSE_SRCS       = $(shell find ${GOOSE_DIR} -name '*.sql' -type f)
GOOSE_DOCKERFILE = ${GOOSE_DIR}/Dockerfile
GOOSE_I          = ${NAME}_goose_i

BASE_I  = ${NAME}_base
BUILD_I = ${NAME}_build

NAME_C = ${NAME}_c

CURL_I = golang:1.12

.DELETE_ON_ERROR:

.pg_start:
	docker run --rm -d -p '5432:5432' --name ${PG_C} ${PG_I}
	@touch $@

.pg_db: .pg_start
	@until (echo 'CREATE DATABASE ${PG_DB};' | docker exec -i ${PG_C} psql -U postgres > /dev/null 2> /dev/null); do \
		echo 'Waiting for pg to be ready.' >&2; \
		sleep 1; \
	done
	@touch $@

.pg_ip: .pg_db
	docker inspect -f '{{.NetworkSettings.IPAddress}}' ${PG_C} > $@

.goose: ${GOOSE_DOCKERFILE} ${GOOSE_SRCS}
	docker build -t ${GOOSE_I} -f $< ${GOOSE_DIR}
	@touch $@

.pg_migrate: .pg_ip .goose
	docker run --rm ${GOOSE_I} ${PG_DSN} up
	@touch $@

.pg: .pg_migrate
	@touch $@

.PHONY: pg_clean
pg_clean:
	@docker rm -f -v ${PG_C} 2> /dev/null > /dev/null || true
	@rm -f .pg_start .pg .pg_db .pg_ip .pg_migrate .goose

dist/${NAME}: ${SRCS}
	@mkdir -p $(dir $@)
	go build -o $@ .

.PHONY: start
start: .pg

.PHONY: start-local
start-local: dist/${NAME} .pg
	@$<

.docker.build: Dockerfile.build .docker.base
	docker build -t ${BUILD_I} --build-arg BASE=${BASE_I} -f $< .
	@touch $@

.start_docker: .docker.build .pg_ip
	@docker rm -f -v ${NAME_C} 2> /dev/null > /dev/null || true
	docker run -d --name ${NAME_C} -e PG_DSN -p '8080:8080' ${BUILD_I}
	@touch $@

.start_ip: .start_docker
	until (docker run --rm -i --link ${NAME_C}:api ${CURL_I} curl -v http://api:8080/healthcheck); do \
		echo 'Waiting for the api to be ready.' >&2; \
		sleep 1; \
	done
	@echo "API Container ready!" >&2
	@docker inspect -f '{{.NetworkSettings.IPAddress}}' ${NAME_C} > $@

.start: .start_ip
	@touch $@

.PHONY: start
start: .start

.docker.base: Dockerfile.base ${SRCS}
	docker build -t ${BASE_I} -f $< .
	@touch $@

.PHONY: test
test: .docker.base .pg
	docker run -i --rm -e PG_DSN ${BASE_I} \
		go test -v ./db

.PHONY: test-local
test-local: .pg
	go test -v ./db

.PHONY: clean
clean: pg_clean
	@docker rm -f -v ${NAME_C} 2> /dev/null > /dev/null || true
	@rm -f dist/${NAME} .docker.base .docker.build .start_docker .start_ip .start
	@rmdir dist 2> /dev/null || true
