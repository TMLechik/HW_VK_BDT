FROM alpine:latest

RUN apk add --no-cache bash curl bc

COPY site_checker.sh /usr/local/bin/
COPY test_site_checker.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/site_checker.sh /usr/local/bin/test_site_checker.sh
