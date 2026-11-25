# syntax=docker/dockerfile:1.7
FROM python:3.13-slim AS build
WORKDIR /build
COPY app/requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

FROM python:3.13-slim
LABEL org.opencontainers.image.source="https://github.com/shubhamkhedkar/aws-alb-asg-rds-terraform-platform" \
      org.opencontainers.image.title="tallybook"
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1
RUN groupadd --system --gid 10001 tally \
 && useradd --system --uid 10001 --gid tally --no-create-home tally
COPY --from=build /install /usr/local
WORKDIR /srv
COPY app/tallybook ./tallybook
USER 10001:10001
EXPOSE 8080
HEALTHCHECK --interval=15s --timeout=3s --start-period=20s --retries=3 \
  CMD ["python", "-c", "import urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://127.0.0.1:8080/healthz', timeout=2).status == 200 else 1)"]
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "2", "--access-logfile", "-", "tallybook.wsgi:app"]
