# Multi-stage build for SysML v2 API Services

# Stage 1: Build stage
FROM eclipse-temurin:11-jdk AS builder

# Install sbt manually
RUN apt-get update && \
    apt-get install -y curl && \
    curl -L -o sbt.tgz https://github.com/sbt/sbt/releases/download/v1.10.5/sbt-1.10.5.tgz && \
    tar -xzf sbt.tgz -C /usr/local && \
    ln -s /usr/local/sbt/bin/sbt /usr/bin/sbt && \
    rm sbt.tgz && \
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
