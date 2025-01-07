FROM ubuntu:20.04


RUN apt-get update && apt-get install -y \
  curl \
  bash \
  ca-certificates \
  libgcc-s1 \
  unzip \
  && rm -rf /var/lib/apt/lists/*


RUN curl -fsSL https://bun.sh/install | bash

ENV PATH="/root/.bun/bin:${PATH}"

WORKDIR /app


COPY package.json bun.lockb ./

RUN bun install --frozen-lockfile


COPY ./src ./src


EXPOSE 5001

CMD ["bun", "run", "src/app.js"]
