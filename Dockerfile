FROM postgis/postgis:18-3.6 AS build

# Build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    cmake \
    bison \
    flex \
    postgresql-server-dev-18 \
    && rm -rf /var/lib/apt/lists/*

# ---- pgvector 0.8.1 ----
WORKDIR /tmp
RUN git clone --branch v0.8.1 https://github.com/pgvector/pgvector.git \
    && cd pgvector \
    && make \
    && make install

# ---- Apache AGE 1.7.0 ----
WORKDIR /tmp
RUN git clone --branch release/PG18/1.7.0 https://github.com/apache/age.git \
    && cd age \
    && make PG_CONFIG=/usr/lib/postgresql/18/bin/pg_config \
    && make install


# ---- Final runtime image ----
FROM postgis/postgis:18-3.6

RUN apt-get update && apt-get install -y locales \
    && echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
    && locale-gen \
    && update-locale LANG=en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8
ENV LC_COLLATE=en_US.UTF-8
ENV LC_CTYPE=en_US.UTF-8

# Copy extensions from build stage
COPY --from=build /usr/lib/postgresql/18/lib/vector.so /usr/lib/postgresql/18/lib/
COPY --from=build /usr/lib/postgresql/18/lib/age.so /usr/lib/postgresql/18/lib/

COPY --from=build /usr/share/postgresql/18/extension/vector* /usr/share/postgresql/18/extension/
COPY --from=build /usr/share/postgresql/18/extension/age* /usr/share/postgresql/18/extension/
