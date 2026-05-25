-- DropForeignKey
ALTER TABLE "Lease" DROP CONSTRAINT "Lease_propertyId_fkey";

-- DropForeignKey
ALTER TABLE "Lease" DROP CONSTRAINT "Lease_renterId_fkey";

-- DropForeignKey
ALTER TABLE "Payment" DROP CONSTRAINT "Payment_leaseId_fkey";

-- AddForeignKey
ALTER TABLE "Lease" ADD CONSTRAINT "Lease_renterId_fkey" FOREIGN KEY ("renterId") REFERENCES "Renter"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Lease" ADD CONSTRAINT "Lease_propertyId_fkey" FOREIGN KEY ("propertyId") REFERENCES "Property"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Payment" ADD CONSTRAINT "Payment_leaseId_fkey" FOREIGN KEY ("leaseId") REFERENCES "Lease"("id") ON DELETE CASCADE ON UPDATE CASCADE;
