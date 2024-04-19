FROM quay.io/minio/minio:RELEASE.2024-02-17T01-15-57Z

COPY certgen /usr/bin/certgen

RUN mkdir -p /root/.minio/certs
RUN cd /root/.minio/certs && certgen -host "127.0.0.1,localhost,minio"
