import pg from 'pg'
import 'dotenv/config'

const pool = new pg.Pool({
  connectionString: process.env.DATABASE_URL,
})

async function seed() {
  const client = await pool.connect()

  try {
    // Find all leases with their renter names
    const leases = await client.query(`
      SELECT l.id as "leaseId", l."startDate", r.name as "renterName"
      FROM "Lease" l
      JOIN "Renter" r ON r.id = l."renterId"
      WHERE l."isActive" = true
    `)

    if (leases.rows.length === 0) {
      console.log('No active leases found. Add a renter first.')
      return
    }

    console.log(`Found ${leases.rows.length} active lease(s):`)
    leases.rows.forEach((l: any) => console.log(`  - ${l.renterName} (${l.leaseId})`))

    for (const lease of leases.rows) {
      const leaseId = lease.leaseId

      // Update lease start date to Jan 2025 so the app shows all months
      await client.query(`
        UPDATE "Lease" SET "startDate" = '2025-01-01', "updatedAt" = NOW()
        WHERE id = $1
      `, [leaseId])
      console.log(`📅 Updated lease start date to Jan 2025`)

      // Generate payments from Jan 2025 through Apr 2026
      const paymentsToInsert = [
        // 2025 - all paid
        { month: 1, year: 2025, isPaid: true, paidDate: '2025-01-03' },
        { month: 2, year: 2025, isPaid: true, paidDate: '2025-02-02' },
        { month: 3, year: 2025, isPaid: true, paidDate: '2025-03-04' },
        { month: 4, year: 2025, isPaid: true, paidDate: '2025-04-01' },
        { month: 5, year: 2025, isPaid: true, paidDate: '2025-05-05' },
        { month: 6, year: 2025, isPaid: true, paidDate: '2025-06-02' },
        { month: 7, year: 2025, isPaid: true, paidDate: '2025-07-03' },
        { month: 8, year: 2025, isPaid: true, paidDate: '2025-08-01' },
        { month: 9, year: 2025, isPaid: false, paidDate: null },  // missed September
        { month: 10, year: 2025, isPaid: true, paidDate: '2025-10-04' },
        { month: 11, year: 2025, isPaid: true, paidDate: '2025-11-02' },
        { month: 12, year: 2025, isPaid: true, paidDate: '2025-12-01' },
        // 2026
        { month: 1, year: 2026, isPaid: true, paidDate: '2026-01-03' },
        { month: 2, year: 2026, isPaid: true, paidDate: '2026-02-02' },
        { month: 3, year: 2026, isPaid: true, paidDate: '2026-03-05' },
        { month: 4, year: 2026, isPaid: false, paidDate: null },  // missed April
      ]

      for (const p of paymentsToInsert) {
        // Upsert — skip if already exists
        await client.query(`
          INSERT INTO "Payment" (id, "leaseId", month, year, "isPaid", "paidDate", "createdAt", "updatedAt")
          VALUES (gen_random_uuid(), $1, $2, $3, $4, $5, NOW(), NOW())
          ON CONFLICT ("leaseId", month, year)
          DO UPDATE SET "isPaid" = $4, "paidDate" = $5, "updatedAt" = NOW()
        `, [leaseId, p.month, p.year, p.isPaid, p.paidDate])
      }

      console.log(`✅ Seeded 16 months of payments for ${lease.renterName}`)
    }
  } finally {
    client.release()
    await pool.end()
  }
}

seed().catch(console.error)
