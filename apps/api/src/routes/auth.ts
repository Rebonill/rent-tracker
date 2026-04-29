import { FastifyInstance } from 'fastify';
import { hashPassword, verifyPassword } from '../utils/password';

export default async function (app: FastifyInstance) {

    // Register  a new landlord
    app.post('/register', {
        schema: {
            body: {
                type: 'object',
                required: ['name', 'email', 'password'],
                properties: {
                    name: { type: 'string', minLength: 1 },
                    email: { type: 'string', format: 'email' },
                    password: { type: 'string', minLength: 6 }
                }
            }
        }
    }, async (request, reply) => {
        const { name, email, password } = request.body as any

        // Check if landlord already exists
        const existingLandlord = await app.prisma.landlord.findUnique({ where: { email } })
        if (existingLandlord) {
            return reply.status(409).send({ error: 'Email already registered' })
        }

        // Create the landlord with hashed password
        const hashedPassword = await hashPassword(password)
        const landlord = await app.prisma.landlord.create({
            data: {
                name,
                email,
                password: hashedPassword
            }
        })

        // Sign a JWT token
        const token = app.jwt.sign({ landlordId: landlord.id })

        return reply.status(201).send({ 
            token,
            landlord: {
                id: landlord.id,
                name: landlord.name,
                email: landlord.email
            }
        })
    })

    // Login an existing landlord
    app.post('/login', {
        schema: {
            body: {
                type: 'object',
                required: ['email', 'password'],
                properties: {
                    email: { type: 'string', format: 'email' },
                    password: { type: 'string' }
                }
            }
        }
    }, async (request, reply) => {
        const { email, password } = request.body as any

        // Find landlord by email
        const landlord = await app.prisma.landlord.findUnique({ where: { email } })
        if (!landlord) {
            return reply.status(401).send({ error: 'Invalid email or password' })
        }

        // Verify password
        const isValidPassword = await verifyPassword(password, landlord.password)
        if (!isValidPassword) {
            return reply.status(401).send({ error: 'Invalid email or password' })
        }

        // Sign a JWT token
        const token = app.jwt.sign({ landlordId: landlord.id })

        return reply.send({ 
            token,
            landlord: {
                id: landlord.id,
                name: landlord.name,
                email: landlord.email
            }
        })
    }) 

}