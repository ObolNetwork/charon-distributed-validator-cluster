# TODO(dhruv): replace latest with proper version.
FROM prysmaticlabs/prysm-validator:latest as prysm-validator

FROM debian:buster-slim
COPY --from=prysm-validator /app/cmd/validator/validator validator

ENTRYPOINT [ "/home/prysm/run.sh" ]