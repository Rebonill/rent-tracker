import { FastifyInstance } from 'fastify'
import { authenticate } from '../middleware/authenticate'

export default async function (app: FastifyInstance) {

  app.addHook('onRequest', authenticate)

  // Toggle a payment's paid status for a given month
  app.post('/payments/toggle', {
    schema: {
        body: {
            type: 'object',
            required: ['leaseId', 'month', 'year'],
            properties: {
                leaseId: { type: 'string' },
                month: { type: 'integer', minimum: 1, maximum: 12 },
                year: { type: 'integer', minimum: 2000 }
            }
        }
    }
}, async (request, reply) => {
    const { leaseId, month, year } = request.body as any

    // Find existing payment or create one
    const existing = await app.prisma.payment.findUnique({
      where: { leaseId_month_year: { leaseId, month, year } }
    })

    if (existing) {
      const payment = await app.prisma.payment.update({
        where: { id: existing.id },
        data: {
          isPaid: !existing.isPaid,
          paidDate: !existing.isPaid ? new Date() : null
        }
      })
      return payment
    } else {
      const payment = await app.prisma.payment.create({
        data: {
          leaseId,
          month,
          year,
          isPaid: true,
          paidDate: new Date()
        }
      })
      return reply.status(201).send(payment)
    }
  })

  // Get payment history for a lease
  app.get('/payments/:leaseId', async (request, reply) => {
    const { leaseId } = request.params as any
    const payments = await app.prisma.payment.findMany({
      where: { leaseId },
      orderBy: [{ year: 'desc' }, { month: 'desc' }]
    })
    return payments
  })
}