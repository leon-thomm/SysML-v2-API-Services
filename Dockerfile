# Multi-stage build for SysML v2 API Services

# Stage 1: Build stage
FROM eclipse-temurin:11-jdk as builder

# Install sbt
RUN apt-get update && \
    apt-get install -y curl gnupg && \
    echo "deb https://repo.scala-sbt.org/scalasbt/debian all main" | tee /etc/apt/sources.list.d/sbt.list && \
    echo "deb https://repo.scala-sbt.org/scalasbt/debian /" | tee /etc/apt/sources.list.d/sbt_old.list && \
    curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2EE0EA64E40A89B84B2DF73499E82A75642AC823" | apt-key add && \
    apt-get update && \
    apt-get install -y sbt && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy project files
COPY . .

# Create generated directory
RUN mkdir -p generated

# Build the application
RUN sbt clean compile stage

# Stage 2: Runtime stage
FROM eclipse-temurin:11-jre

# Set working directory
WORKDIR /app

# Copy the built application from builder stage
COPY --from=builder /app/target/universal/stage /app

# Expose port 9000
EXPOSE 9000

# Set environment variables for database connection
ENV DB_HOST=postgres \
    DB_PORT=5432 \
    DB_NAME=sysml2 \
    DB_USER=postgres \
    DB_PASSWORD=mysecretpassword

# Run the application
CMD ["/app/bin/sysml-v2-api-services", "-Dconfig.resource=application.conf"]
