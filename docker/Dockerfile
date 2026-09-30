FROM maven:3.9.9-eclipse-temurin-17 AS build
WORKDIR /workspace
COPY app/pom.xml ./pom.xml
COPY app/src ./src
RUN mvn -B -DskipTests package

FROM eclipse-temurin:17-jre
RUN useradd --system --uid 10001 --create-home appuser
WORKDIR /app
COPY --from=build /workspace/target/ecommerce-0.1.0.jar /app/app.jar
USER 10001
EXPOSE 8080
ENTRYPOINT ["java","-XX:MaxRAMPercentage=75.0","-jar","/app/app.jar"]
