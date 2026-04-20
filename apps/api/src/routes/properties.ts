import { FastifyInstance } from 'fastify'

const TEMP_LANDLORD_ID = 'id1234' // same ID as in renters.ts

export default async function (app: FastifyInstance) {

  // List all properties for the landlord
  app.get('/properties', async (request, reply) => {
    const properties = await app.prisma.property.findMany({
      where: { landlordId: TEMP_LANDLORD_ID }
    })
    return properties
  })

  // Create a new property
  app.post('/properties', {
    schema: {
        body: {
            type: 'object',
            required: ['address', 'city', 'state', 'zip'],
            properties: {
                address: { type: 'string', minLength: 1 },
                unit: { type: 'string' },
                city: { type: 'string', minLength: 1 },
                state: { type: 'string', minLength: 1 },
                zip: { type: 'string', minLength: 1 }
            }
        }
    }
    }, async (request, reply) => {
        const { address, unit, city, state, zip } = request.body as any
        const property = await app.prisma.property.create({
        data: {
            address,
            unit,
            city,
            state,
            zip,
            landlordId: TEMP_LANDLORD_ID
      }
    })
    return reply.status(201).send(property)
  })

  // Update a property
  app.put('/properties/:id', async (request, reply) => {
    const { id } = request.params as any
    const { address, unit, city, state, zip } = request.body as any
    const property = await app.prisma.property.update({
      where: { id },
      data: { address, unit, city, state, zip }
    })
    return property
  })

  // Delete a property
  app.delete('/properties/:id', async (request, reply) => {
    const { id } = request.params as any
    await app.prisma.property.delete({ where: { id } })
    return reply.status(204).send()
  })
}