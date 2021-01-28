FROM node:14-buster

RUN apt-get update && \
    apt-get install -y libgmp-dev nlohmann-json3-dev nasm g++ git curl ne && \
    rm -rf /var/lib/apt/lists/*

RUN npm i -g circom snarkjs

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"
RUN cargo install zkutil

WORKDIR /build

# RUN git clone https://github.com/iden3/r1csoptimize

COPY package.json yarn.lock ./
RUN yarn
COPY circuits ./circuits
WORKDIR /build/circuits
ENTRYPOINT bash
# ENV NODE_OPTIONS='--trace-gc --trace-gc-ignore-scavenger --max-old-space-size=2048000 --initial-old-space-size=2048000 --no-global-gc-scheduling --no-incremental-marking --max-semi-space-size=1024 --initial-heap-size=2048000'
ENV NODE_OPTIONS='--max-old-space-size=2048000'
ENV CIRCOM_RUNTIME=/build/node_modules/circom_runtime/c
RUN circom -rcfv test.circom
RUN node ../node_modules/ffiasm/src/buildzqfield.js -q 21888242871839275222246405745257275088548364400416034343698204186575808495617 -n Fr && \
    nasm -felf64 fr.asm && \
    cp $CIRCOM_RUNTIME/*.cpp ./ && \
    cp $CIRCOM_RUNTIME/*.hpp ./ && \
    g++ -pthread main.cpp calcwit.cpp utils.cpp fr.cpp fr.o test.cpp -o testWitness -lgmp -std=c++11 -O3 -fopenmp -DSANITY_CHECK
RUN zkutil setup -c test.r1cs
