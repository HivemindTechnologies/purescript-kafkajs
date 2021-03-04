# Examples

Start a kafka using

```bash 
docker-compose up -d
```

## Transactional producer consumer

Install everything
```bash 
npm install 
```

Run a producer in a terminal.

```bash 
npx spago run -m Kafka.Example.Producer
```

Run a consumer in another terminal.

```bash 
npx spago run -m Kafka.Example.Consumer
```