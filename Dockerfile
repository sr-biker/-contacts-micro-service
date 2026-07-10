FROM maven:3.9-amazoncorretto-21 AS build
WORKDIR /build
COPY pom.xml .
RUN mvn -B dependency:go-offline
COPY src ./src
RUN mvn -B package -DskipTests

FROM amazoncorretto:21-alpine
WORKDIR /app
COPY --from=build /build/target/contacts-micro-service.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
