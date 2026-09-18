FROM public.ecr.aws/x8v8d7g8/mars-base:latest

WORKDIR /app

COPY . .

RUN if ! command -v java >/dev/null 2>&1; then \
        apt-get update && \
        apt-get install -y --no-install-recommends default-jre-headless && \
        rm -rf /var/lib/apt/lists/*; \
    fi

RUN pip install -e . attrs pytest pytest-mock typing_extensions

CMD ["/bin/bash"]
