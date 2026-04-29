import fastify from "fastify";
import prismaPlugin from './plugins/prisma'
import rentersRoutes from './routes/renters'
import propertyRoutes from './routes/properties'
import leasesRoutes from './routes/leases'
import paymentRoutes from './routes/payments'
import 'dotenv/config'
import jwt from '@fastify/jwt'
import authRoutes from './routes/auth'

const app = fastify();

app.register(prismaPlugin)
app.register(jwt, {
  secret: process.env.JWT_SECRET || 'fallback-secret'
})
app.register(authRoutes)
app.register(rentersRoutes)
app.register(propertyRoutes)
app.register(leasesRoutes)
app.register(paymentRoutes)

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