## Dockerize Swift app that uses SPM library with resources
On macOS/iOS systems the resources are distributes as `bundle`. On linux sustems they are packed as `resources`.
If you want dockerize your app, you need to copy the `resources`, which is tricky.
```Dockerfile
FROM swift:5.9 as builder
WORKDIR /app
COPY . .
RUN swift build -c release 
RUN echo $(ls -la .build/x86_64-unknown-linux-gnu/release)


FROM swift:5.9-slim
RUN apt-get update -y
RUN apt-get install -y file
WORKDIR /app
# first copy everything to temp directory
COPY --from=builder /app/.build/x86_64-unknown-linux-gnu/release/ ./tmp/
# move resources only(linux bundles) to destination
RUN cp -R ./tmp/*.resources .
# remove tmp
RUN rm -rf ./tmp
# now copy your app
COPY --from=builder /app/.build/x86_64-unknown-linux-gnu/release/TempApp .
# and app's own resources (if any)
COPY Resources /app/Resources
CMD ["./TempApp"]

```
