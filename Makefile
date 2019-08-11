NAME = partypher

MYSQL_I        = mysql:8
MYSQL_C        = ${NAME}_mysql_c
MYSQL_PASSWORD = mySuperSecretPassword
MYSQL_DB       = partypher

MYSQL_DSN = root:${MYSQL_PASSWORD}@tcp(localhost:3306)/${MYSQL_DB}

SRCS := $(shell find . -name '*.go' -type f)

.DELETE_ON_ERROR:

.mysql_start:
	docker run --rm -d -p '3306:3306' --name ${MYSQL_C} -e MYSQL_ROOT_PASSWORD=${MYSQL_PASSWORD} ${MYSQL_I}
	@touch $@

.mysql_db: .mysql_start
	@until (echo 'CREATE DATABASE ${MYSQL_DB};' | docker exec -i ${MYSQL_C} mysql -u root -p${MYSQL_PASSWORD} > /dev/null 2> /dev/null); do \
		echo 'Waiting for mysql to be ready.' >&2; \
		sleep 1; \
	done
	@touch $@

.mysql: .mysql_db
	@touch $@

.PHONY: mysql_clean
mysql_clean:
	docker rm -f -v ${MYSQL_C} 2> /dev/null > /dev/null || true
	@rm -f .mysql_start .mysql .mysql_db

dist/${NAME}: ${SRCS}
	@mkdir -p $(dir $@)
	go build -o $@ .

.PHONY: start
start: dist/${NAME} .mysql
	@$<

.PHONY: clean
clean: mysql_clean
	@rm -f dist/${NAME}
	@rmdir dist
