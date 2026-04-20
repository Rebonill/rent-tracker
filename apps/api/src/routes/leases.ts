import { FastifyInstance } from 'fastify'

export default async function (app: FastifyInstance) {

  // Create a new lease (ties a renter to a property)
  app.post('/leases', {
    schema: {
      body: {
        type: 'object',
        required: ['renterId', 'propertyId', 'rentAmount', 'dueDayOfMonth', 'startDate'],
        properties: {
          renterId: { type: 'string' },
          propertyId: { type: 'string' },
          rentAmount: { type: 'number', minimum: 0 },
          dueDayOfMonth: { type: 'integer', minimum: 1, maximum: 28 },
          startDate: { type: 'string' },
          endDate: { type: 'string' }
        }
      }
    }
  }, async (request, reply) => {
    const { renterId, propertyId, rentAmount, dueDayOfMonth, startDate, endDate } = request.body as any
    const lease = await app.prisma.lease.create({
      data: {
        renterId,
        propertyId,
        rentAmount,
        dueDayOfMonth,
        startDate: new Date(startDate),
        endDate: endDate ? new Date(endDate) : null,
      }
    })
    return reply.status(201).send(lease)
  })

  // Update a lease
  app.put('/leases/:id', async (request, reply) => {
    const { id } = request.params as any
    const { rentAmount, dueDayOfMonth, startDate, endDate, isActive } = request.body as any
    const lease = await app.prisma.lease.update({
      where: { id },
      data: {
        rentAmount,
        dueDayOfMonth,
        startDate: startDate ? new Date(startDate) : undefined,
        endDate: endDate ? new Date(endDate) : undefined,
        isActive,
      }
    })
    return lease
  })
}