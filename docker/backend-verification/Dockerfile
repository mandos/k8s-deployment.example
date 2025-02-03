FROM alpine

RUN apk add jq curl postgresql-client
COPY ./verify-backend.sh /usr/bin/verify-backend.sh 
ENTRYPOINT [ "/usr/bin/verify-backend.sh" ]
