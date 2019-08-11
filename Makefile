NAME = partypher

MYSQL_I        = mysql:8
MYSQL_C        = ${NAME}_mysql_c
MYSQL_PASSWORD = mySuperSecretPassword

.PHONY: mysql_start
mysql_start:
	docker run --rm -it -p '3306:3306' --name ${MYSQL_C} -e MYSQL_ROOT_PASSWORD=${MYSQL_PASSWORD} ${MYSQL_I}
