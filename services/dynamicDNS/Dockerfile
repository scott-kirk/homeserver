FROM debian:latest

RUN apt-get update && apt-get install -y \
  curl \
  jq \
  && rm -rf /var/lib/apt/lists/*

COPY ./entrypoint.sh ./
COPY ./update-dns.sh ./

ENTRYPOINT ["./entrypoint.sh"]
