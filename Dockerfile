# Imagen de build: compila el servidor a AOT.
FROM dart:3.11 AS build

WORKDIR /app
COPY pubspec.* ./
RUN dart pub get

COPY . .
RUN dart pub get --offline && dart build cli --target bin/server.dart -o output

# Imagen final mínima: runtime de Dart + binario compilado.
FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/output/bundle/ /app/

# Render (10000) y Cloud Run (8080) inyectan PORT; el servidor lo lee al arrancar.
EXPOSE 10000
CMD ["/app/bin/server"]
