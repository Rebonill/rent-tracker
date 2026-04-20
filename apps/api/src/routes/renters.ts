import { FastifyInstance } from "fastify";

const TEMP_LANDLORD_ID = 'id1234';

export default async function (app: FastifyInstance) {

    app.get('/renters', async (request, reply) => {
        const renters = await app.prisma.renter.findMany({
            where: { landlordId: TEMP_LANDLORD_ID },
            include: {
            leases: {
                where: { isActive: true },
                include: { property: true, payments: true }
            }
            }
        })
        return renters
    })

    app.post('/renters', {
        schema: {
         body: {
            type: 'object',
            required: ['name'],
            properties: {
                name: { type: 'string', minLength: 1 },
                email: { type: 'string', format: 'email' },
                phone: { type: 'string' }
      }
    }
  }
}, async (request, reply) => {
        const { name, email, phone } = request.body as any
        const renter = await app.prisma.renter.create({
            data: {
            name,
            email,
            phone,
            landlordId: TEMP_LANDLORD_ID
            }
        })
        return reply.status(201).send(renter)
    })

    app.get('/renters/:id', async (request, reply) => {
        const { id } = request.params as any
        const renter = await app.prisma.renter.findUnique({
            where: { id },
            include: {
            leases: {
                include: { property: true, payments: true }
            }
            }
        })
        if (!renter) return reply.status(404).send({ error: 'Renter not found' })
        return renter
    })

    app.put('/renters/:id', async (request, reply) => {
        const { id } = request.params as any
        const { name, email, phone } = request.body as any
        const renter = await app.prisma.renter.update({
            where: { id },
            data: { name, email, phone }
        })
        return renter
    })

    app.delete('/renters/:id', async (request, reply) => {
        const { id } = request.params as any
        await app.prisma.renter.delete({ where: { id } })
        return reply.status(204).send()
    })
}