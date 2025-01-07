FROM ubuntu:20.04

# Install dependencies
RUN apt-get update && apt-get install -y \
  curl \
  bash \
  ca-certificates \
  libgcc-s1 \
  unzip \
  && rm -rf /var/lib/apt/lists/*

# Install Bun
RUN curl -fsSL https://bun.sh/install | bash

ENV PATH="/root/.bun/bin:${PATH}"

WORKDIR /app

# Copy necessary files
COPY package.json bun.lockb ./

# Install dependencies
RUN bun install --frozen-lockfile

# Copy application source code
COPY ./src ./src

# Expose the port your app will run on
EXPOSE 5000

# Start the app
CMD ["bun", "run", "src/app.js"]
