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
      where: { leaseId_month_year: { leaseId, month, year } },
      include: { partialPayments: true }
    })

    if (existing) {
      const markingPaid = !existing.isPaid

      // If marking unpaid, delete partial payments and reset amount
      if (!markingPaid) {
        await app.prisma.partialPayment.deleteMany({ where: { paymentId: existing.id } })
      }

      const payment = await app.prisma.payment.update({
        where: { id: existing.id },
        data: {
          isPaid: markingPaid,
          paidDate: markingPaid ? new Date() : null,
          amountPaid: markingPaid ? existing.amountPaid : 0
        },
        include: { partialPayments: { orderBy: { createdAt: 'desc' } } }
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
        },
        include: { partialPayments: true }
      })
      return reply.status(201).send(payment)
    }
  })

  // Add a partial payment
  app.post('/payments/partial', {
    schema: {
      body: {
        type: 'object',
        required: ['leaseId', 'month', 'year', 'amount'],
        properties: {
          leaseId: { type: 'string' },
          month: { type: 'integer', minimum: 1, maximum: 12 },
          year: { type: 'integer', minimum: 2000 },
          amount: { type: 'number', minimum: 0.01 },
          note: { type: 'string' }
        }
      }
    }
  }, async (request, reply) => {
    const { leaseId, month, year, amount, note } = request.body as any

    // Get the lease to know the rent amount
    const lease = await app.prisma.lease.findUnique({ where: { id: leaseId } })
    if (!lease) return reply.status(404).send({ error: 'Lease not found' })

    // Upsert the payment record
    let payment = await app.prisma.payment.upsert({
      where: { leaseId_month_year: { leaseId, month, year } },
      create: {
        leaseId, month, year,
        isPaid: false,
        amountPaid: 0
      },
      update: {}
    })

    // Add the partial payment
    await app.prisma.partialPayment.create({
      data: {
        paymentId: payment.id,
        amount,
        note
      }
    })

    // Update the running total
    const newTotal = payment.amountPaid + amount
    const fullyPaid = newTotal >= lease.rentAmount

    payment = await app.prisma.payment.update({
      where: { id: payment.id },
      data: {
        amountPaid: newTotal,
        isPaid: fullyPaid,
        paidDate: fullyPaid ? new Date() : null
      },
      include: { partialPayments: { orderBy: { createdAt: 'desc' } } }
    })

    return payment
  })

  // Get payment history for a lease (include partial payments)
  app.get('/payments/:leaseId', async (request, reply) => {
    const { leaseId } = request.params as any
    const payments = await app.prisma.payment.findMany({
      where: { leaseId },
      include: { partialPayments: { orderBy: { createdAt: 'desc' } } },
      orderBy: [{ year: 'desc' }, { month: 'desc' }]
    })
    return payments
  })
}
