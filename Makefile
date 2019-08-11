NAME = partypher

PG_I        = postgres:12
PG_C        = ${NAME}_pg_c
PG_PASSWORD = mySuperSecretPassword
PG_DB       = partypher

PG_ROOT_DSN = postgres://postgres:${PG_PASSWORD}@localhost:5432/${PG_DB}?sslmode=disable
export PG_ROOT_DSN

SRCS := $(shell find . -name '*.go' -type f)

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

.pg: .pg_db
	@touch $@

.PHONY: pg_clean
pg_clean:
	docker rm -f -v ${PG_C} 2> /dev/null > /dev/null || true
	@rm -f .pg_start .pg .pg_db

dist/${NAME}: ${SRCS}
	@mkdir -p $(dir $@)
	go build -o $@ .

.PHONY: start
start: dist/${NAME} .pg
	@$<

.PHONY: clean
clean: pg_clean
	@rm -f dist/${NAME}
	@rmdir dist
