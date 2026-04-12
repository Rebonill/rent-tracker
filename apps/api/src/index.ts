import fastify from "fastify";

const app = fastify();

app.get('/health', async () => {
  return { status: 'ok' }
})

app.listen({ port: 3000 }, (err) => {
  if (err) {
    console.error(err)
    process.exit(1)
  }
  console.log('Server running on http://localhost:3000')
})